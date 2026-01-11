import { Request, Response } from 'express';
import fs from 'fs';
import path from 'path';
import { Op } from 'sequelize';
import { Product, ProductImage, ProductVariant, Tag, Category, Project } from '../models';
import { sendSuccess, sendError, sendNotFound, sendValidationError, sendForbidden } from '../utils/helpers';
import { PROJECT_STATUS } from '../config/constants';

// Helper to include associations
const productInclude = [
    {
        model: ProductImage,
        as: 'images',
        attributes: ['id', 'imageUrl', 'sortOrder'],
    },
    {
        model: ProductVariant,
        as: 'variants',
        attributes: ['id', 'name', 'nameAr', 'priceModifier', 'quantity', 'isAvailable'],
        where: { isAvailable: true },
        required: false,
    },
    {
        model: Tag,
        as: 'tags',
        attributes: ['id', 'name', 'nameAr'],
        through: { attributes: [] },
    },
    {
        model: Category,
        as: 'category',
        attributes: ['id', 'name', 'nameAr', 'icon'],
    },
    {
        model: Project,
        as: 'project',
        attributes: ['id', 'name', 'nameAr', 'city', 'averageRating'],
    },
];

export const getAllProducts = async (req: Request, res: Response) => {
    try {
        const {
            page = '1',
            limit = '20',
            search,
            categoryId,
            projectId,
            status,
            minPrice,
            maxPrice,
            minRating,
            sort = 'newest',
        } = req.query;

        const offset = (Number(page) - 1) * Number(limit);
        const where: any = {};

        // Status filter: if not provided, default to approved only
        // If status is 'all' or undefined with projectId (owner viewing), show all statuses
        if (status === 'all') {
            // No status filter - show all
        } else if (status) {
            where.status = status;
        } else {
            // Default: only approved
            where.status = 'approved';
            where.isAvailable = true;
        }

        // Filter by project if provided
        if (projectId) {
            where.projectId = projectId;
        }

        // Exclude own products if user is logged in
        if (req.user) {
            console.log('DEBUG: User is logged in:', req.user.id);
            // If we are NOT filtering by specific project (e.g. looking at own project), exclude own products
            // But wait, if I am looking at my own project, I SHOULD see my products?
            // The user said "home screen filtering (still showing own products/projects)".
            // So on Home Screen (no projectId filter usually), we should exclude own products.

            if (!projectId) {
                console.log('DEBUG: Excluding products with project.ownerId:', req.user.id);
                // We need to filter by project owner. Product -> Project -> Owner
                // This is complex in Sequelize with simple where.
                // Easier: Get user's project ID and exclude products from that project.
                const userProject = await Project.findOne({ where: { ownerId: req.user.id } });
                if (userProject) {
                    console.log('DEBUG: Excluding products from project:', userProject.id);
                    where.projectId = { [Op.ne]: userProject.id };
                }
            }
        }

        if (search) {
            where[Op.or] = [
                { name: { [Op.like]: `%${search}%` } },
                { nameAr: { [Op.like]: `%${search}%` } },
                { description: { [Op.like]: `%${search}%` } },
                { descriptionAr: { [Op.like]: `%${search}%` } },
            ];
        }

        if (categoryId) {
            where.categoryId = categoryId;
        }

        if (minPrice || maxPrice) {
            where.basePrice = {};
            if (minPrice) where.basePrice[Op.gte] = Number(minPrice);
            if (maxPrice) where.basePrice[Op.lte] = Number(maxPrice);
        }

        let order: any = [['createdAt', 'DESC']];
        if (sort === 'price_asc') order = [['basePrice', 'ASC']];
        if (sort === 'price_desc') order = [['basePrice', 'DESC']];
        if (sort === 'rating') order = [['averageRating', 'DESC']];

        const { count, rows } = await Product.findAndCountAll({
            where,
            include: productInclude,
            limit: Number(limit),
            offset,
            order,
            distinct: true,
        });

        return sendSuccess(res, {
            products: rows,
            pagination: {
                total: count,
                page: Number(page),
                totalPages: Math.ceil(count / Number(limit)),
            },
        });
    } catch (error: any) {
        return sendError(res, 'SERVER_ERROR', 'Error fetching products', 500, error);
    }
};

export const getProductById = async (req: Request, res: Response) => {
    try {
        const { id } = req.params;
        const product = await Product.findByPk(id, {
            include: productInclude,
        });

        if (!product) {
            return sendNotFound(res, 'Product');
        }

        // Increment view count
        await product.increment('viewCount');

        return sendSuccess(res, product);
    } catch (error: any) {
        return sendError(res, 'SERVER_ERROR', 'Error fetching product', 500, error);
    }
};

export const createProduct = async (req: Request, res: Response) => {
    try {
        const userId = req.user!.id;
        const project = await Project.findOne({ where: { ownerId: userId } });

        if (!project) {
            return sendForbidden(res, 'You do not have a project');
        }

        if (project.status !== PROJECT_STATUS.APPROVED) {
            return sendForbidden(res, 'Your project is not approved');
        }

        // Get posterImageUrl from uploaded file or from body
        let posterImageUrl = req.body.posterImageUrl;
        if (req.file) {
            posterImageUrl = `/uploads/products/${req.file.filename}`;
        }

        if (!posterImageUrl) {
            return sendValidationError(res, [{
                field: 'posterImage',
                message: 'Product image is required'
            }]);
        }

        // Parse FormData values (they come as strings)
        const productData = {
            name: req.body.name,
            nameAr: req.body.nameAr,
            description: req.body.description || null,
            descriptionAr: req.body.descriptionAr || null,
            categoryId: parseInt(req.body.categoryId, 10),
            basePrice: parseFloat(req.body.basePrice),
            quantity: parseInt(req.body.quantity, 10) || 0,
            isAvailable: req.body.isAvailable === 'true' || req.body.isAvailable === true,
            projectId: project.id,
            posterImageUrl,
            status: 'pending' as const, // Always pending initially
        };

        const product = await Product.create(productData);

        return sendSuccess(res, product, 'Product created successfully');
    } catch (error: any) {
        return sendError(res, 'SERVER_ERROR', 'Error creating product', 500, error);
    }
};

export const updateProduct = async (req: Request, res: Response) => {
    try {
        const { id } = req.params;
        const userId = req.user!.id;

        const product = await Product.findByPk(id, {
            include: [{ model: Project, as: 'project' }],
        });

        if (!product) {
            return sendNotFound(res, 'Product');
        }

        if (product.project?.ownerId !== userId) {
            return sendForbidden(res, 'You do not own this product');
        }

        await product.update(req.body);

        return sendSuccess(res, product, 'Product updated successfully');
    } catch (error: any) {
        return sendError(res, 'SERVER_ERROR', 'Error updating product', 500, error);
    }
};

export const deleteProduct = async (req: Request, res: Response) => {
    try {
        const { id } = req.params;
        const userId = req.user!.id;

        const product = await Product.findByPk(id, {
            include: [{ model: Project, as: 'project' }],
        });

        if (!product) {
            return sendNotFound(res, 'Product');
        }

        if (product.project?.ownerId !== userId) {
            return sendForbidden(res, 'You do not own this product');
        }

        await product.destroy();

        return sendSuccess(res, null, 'Product deleted successfully');
    } catch (error: any) {
        return sendError(res, 'SERVER_ERROR', 'Error deleting product', 500, error);
    }
};

export const getNearbyProducts = async (req: Request, res: Response) => {
    // Placeholder for geolocation logic
    // For now, return random products
    return getAllProducts(req, res);
};

// --- Product Images ---

export const addProductImage = async (req: Request, res: Response) => {
    try {
        const { id } = req.params;
        const userId = req.user!.id;
        const file = req.file;

        if (!file) {
            return sendValidationError(res, [{ field: 'image', message: 'Image is required' }]);
        }

        const product = await Product.findByPk(id, {
            include: [{ model: Project, as: 'project' }],
        });

        if (!product) {
            // Clean up uploaded file if product not found
            fs.unlinkSync(file.path);
            return sendNotFound(res, 'Product');
        }

        if (product.project?.ownerId !== userId) {
            fs.unlinkSync(file.path);
            return sendForbidden(res, 'You do not own this product');
        }

        const imageUrl = `/uploads/products/${file.filename}`;
        const image = await ProductImage.create({
            productId: product.id,
            imageUrl,
            sortOrder: 0, // Default sort order
        });

        return sendSuccess(res, image, 'Image added successfully');
    } catch (error: any) {
        if (req.file) fs.unlinkSync(req.file.path);
        return sendError(res, 'SERVER_ERROR', 'Error adding product image', 500, error);
    }
};

export const deleteProductImage = async (req: Request, res: Response) => {
    try {
        const { id, imageId } = req.params;
        const userId = req.user!.id;

        const product = await Product.findByPk(id, {
            include: [{ model: Project, as: 'project' }],
        });

        if (!product) {
            return sendNotFound(res, 'Product');
        }

        if (product.project?.ownerId !== userId) {
            return sendForbidden(res, 'You do not own this product');
        }

        const image = await ProductImage.findOne({
            where: { id: imageId, productId: id },
        });

        if (!image) {
            return sendNotFound(res, 'Product Image');
        }

        // Delete file from filesystem
        const uploadsDir = path.join(process.cwd(), 'uploads');
        const filePath = path.join(uploadsDir, image.imageUrl.replace('/uploads/', ''));
        const thumbPath = filePath.replace(/image-/, 'thumb_image-');

        if (fs.existsSync(filePath)) {
            fs.unlinkSync(filePath);
        }
        if (fs.existsSync(thumbPath)) {
            fs.unlinkSync(thumbPath);
        }

        await image.destroy();

        return sendSuccess(res, null, 'Image deleted successfully');
    } catch (error: any) {
        return sendError(res, 'SERVER_ERROR', 'Error deleting product image', 500, error);
    }
};

export const updateProductPoster = async (req: Request, res: Response) => {
    try {
        const { id } = req.params;
        const userId = req.user!.id;

        const product = await Product.findByPk(id, {
            include: [{ model: Project, as: 'project' }],
        });

        if (!product) {
            return sendNotFound(res, 'Product');
        }

        if (product.project?.ownerId !== userId) {
            return sendForbidden(res, 'You do not own this product');
        }

        if (!req.file) {
            return sendValidationError(res, [{ field: 'posterImage', message: 'Poster image is required' }]);
        }

        // Delete old poster file if exists
        if (product.posterImageUrl) {
            const uploadsDir = path.join(process.cwd(), 'uploads');
            const oldFilePath = path.join(uploadsDir, product.posterImageUrl.replace('/uploads/', ''));
            if (fs.existsSync(oldFilePath)) {
                fs.unlinkSync(oldFilePath);
            }
        }

        // Update with new poster
        const posterImageUrl = `/uploads/products/${req.file.filename}`;
        await product.update({ posterImageUrl });

        return sendSuccess(res, product, 'Poster image updated successfully');
    } catch (error: any) {
        if (req.file) fs.unlinkSync(req.file.path);
        return sendError(res, 'SERVER_ERROR', 'Error updating poster image', 500, error);
    }
};

export const promoteImageAsPoster = async (req: Request, res: Response) => {
    try {
        const { id, imageId } = req.params;
        const userId = req.user!.id;

        const product = await Product.findByPk(id, {
            include: [{ model: Project, as: 'project' }],
        });

        if (!product) {
            return sendNotFound(res, 'Product');
        }

        if (product.project?.ownerId !== userId) {
            return sendForbidden(res, 'You do not own this product');
        }

        // Find the image to promote
        const image = await ProductImage.findOne({
            where: { id: imageId, productId: id },
        });

        if (!image) {
            return sendNotFound(res, 'Product Image');
        }

        // Delete old poster file if exists
        if (product.posterImageUrl) {
            const uploadsDir = path.join(process.cwd(), 'uploads');
            const oldFilePath = path.join(uploadsDir, product.posterImageUrl.replace('/uploads/', ''));
            if (fs.existsSync(oldFilePath)) {
                fs.unlinkSync(oldFilePath);
            }
        }

        // Update product with the image URL as new poster
        await product.update({ posterImageUrl: image.imageUrl });

        // Delete the image from product_images since it's now the poster
        await image.destroy();

        return sendSuccess(res, product, 'Image promoted to poster successfully');
    } catch (error: any) {
        return sendError(res, 'SERVER_ERROR', 'Error promoting image to poster', 500, error);
    }
};

// --- Product Variants ---

export const getProductVariants = async (req: Request, res: Response) => {
    try {
        const { id } = req.params;
        const variants = await ProductVariant.findAll({
            where: { productId: id },
        });
        return sendSuccess(res, variants);
    } catch (error: any) {
        return sendError(res, 'SERVER_ERROR', 'Error fetching variants', 500, error);
    }
};

export const addProductVariant = async (req: Request, res: Response) => {
    try {
        const { id } = req.params;
        const userId = req.user!.id;

        const product = await Product.findByPk(id, {
            include: [{ model: Project, as: 'project' }],
        });

        if (!product) {
            return sendNotFound(res, 'Product');
        }

        if (product.project?.ownerId !== userId) {
            return sendForbidden(res, 'You do not own this product');
        }

        const variant = await ProductVariant.create({
            ...req.body,
            productId: product.id,
        });

        return sendSuccess(res, variant, 'Variant added successfully');
    } catch (error: any) {
        return sendError(res, 'SERVER_ERROR', 'Error adding variant', 500, error);
    }
};

export const updateProductVariant = async (req: Request, res: Response) => {
    try {
        const { variantId } = req.params;
        const userId = req.user!.id;

        const variant = await ProductVariant.findByPk(variantId, {
            include: [{
                model: Product,
                as: 'product',
                include: [{ model: Project, as: 'project' }]
            }],
        });

        if (!variant) {
            return sendNotFound(res, 'Variant');
        }

        if (variant.product?.project?.ownerId !== userId) {
            return sendForbidden(res, 'You do not own this product');
        }

        await variant.update(req.body);

        return sendSuccess(res, variant, 'Variant updated successfully');
    } catch (error: any) {
        return sendError(res, 'SERVER_ERROR', 'Error updating variant', 500, error);
    }
};

export const deleteProductVariant = async (req: Request, res: Response) => {
    try {
        const { variantId } = req.params;
        const userId = req.user!.id;

        const variant = await ProductVariant.findByPk(variantId, {
            include: [{
                model: Product,
                as: 'product',
                include: [{ model: Project, as: 'project' }]
            }],
        });

        if (!variant) {
            return sendNotFound(res, 'Variant');
        }

        if (variant.product?.project?.ownerId !== userId) {
            return sendForbidden(res, 'You do not own this product');
        }

        await variant.destroy();

        return sendSuccess(res, null, 'Variant deleted successfully');
    } catch (error: any) {
        return sendError(res, 'SERVER_ERROR', 'Error deleting variant', 500, error);
    }
};

// --- Product Tags ---

export const addProductTag = async (req: Request, res: Response) => {
    try {
        const { id } = req.params;
        const { tagId } = req.body;
        const userId = req.user!.id;

        const product = await Product.findByPk(id, {
            include: [{ model: Project, as: 'project' }],
        });

        if (!product) {
            return sendNotFound(res, 'Product');
        }

        if (product.project?.ownerId !== userId) {
            return sendForbidden(res, 'You do not own this product');
        }

        const tag = await Tag.findByPk(tagId);
        if (!tag) {
            return sendNotFound(res, 'Tag');
        }

        // Check if already associated
        const hasTag = await product.hasTag(tag);
        if (hasTag) {
            return sendError(res, 'CONFLICT', 'Tag already added to product', 409);
        }

        await product.addTag(tag);

        return sendSuccess(res, null, 'Tag added to product successfully');
    } catch (error: any) {
        return sendError(res, 'SERVER_ERROR', 'Error adding tag to product', 500, error);
    }
};

export const removeProductTag = async (req: Request, res: Response) => {
    try {
        const { id, tagId } = req.params;
        const userId = req.user!.id;

        const product = await Product.findByPk(id, {
            include: [{ model: Project, as: 'project' }],
        });

        if (!product) {
            return sendNotFound(res, 'Product');
        }

        if (product.project?.ownerId !== userId) {
            return sendForbidden(res, 'You do not own this product');
        }

        const tag = await Tag.findByPk(tagId);
        if (!tag) {
            return sendNotFound(res, 'Tag');
        }

        await product.removeTag(tag);

        return sendSuccess(res, null, 'Tag removed from product successfully');
    } catch (error: any) {
        return sendError(res, 'SERVER_ERROR', 'Error removing tag from product', 500, error);
    }
};
