import { Request, Response } from 'express';
import { Op } from 'sequelize';
import { Product, ProductImage, ProductVariant, Tag, Category, Project, User } from '../models';
import { sendSuccess, sendError, sendNotFound, sendPaginated } from '../utils/helpers';
import { NotificationTemplates } from '../services/notification.service';

// Helper to include associations for admin product list queries (simplified - no nested includes)
const productListInclude = [
    {
        model: ProductImage,
        as: 'images',
        attributes: ['id', 'imageUrl', 'sortOrder'],
    },
    {
        model: ProductVariant,
        as: 'variants',
        attributes: ['id', 'name', 'nameAr', 'priceModifier', 'quantity', 'isAvailable'],
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
        attributes: ['id', 'name', 'nameAr', 'city', 'averageRating', 'ownerId'],
        // Note: owner is fetched separately for list to avoid subquery issues
    },
];

// Helper to include associations for admin product detail queries (with nested owner)
const productDetailInclude = [
    {
        model: ProductImage,
        as: 'images',
        attributes: ['id', 'imageUrl', 'sortOrder'],
    },
    {
        model: ProductVariant,
        as: 'variants',
        attributes: ['id', 'name', 'nameAr', 'priceModifier', 'quantity', 'isAvailable'],
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
        attributes: ['id', 'name', 'nameAr', 'city', 'averageRating', 'ownerId'],
        // Nested include removed to avoid Sequelize error
    },
];

// Helper to attach owner to product project
const attachOwnerToProduct = async (product: any) => {
    if (product.project && product.project.ownerId) {
        const owner = await User.findByPk(product.project.ownerId, {
            attributes: ['id', ['full_name', 'name'], 'email', 'phone'],
        });
        if (owner) {
            product.project.setDataValue('owner', owner);
        }
    }
    return product;
};

/**
 * Get all products for admin with filtering and pagination
 */
export const getAllProducts = async (req: Request, res: Response) => {
    try {
        const {
            page = '1',
            limit = '20',
            search,
            categoryId,
            projectId,
            ownerId,
            status,
            sort = 'newest',
        } = req.query;

        const offset = (Number(page) - 1) * Number(limit);
        const where: any = {};

        // Status filter (admin can see all statuses)
        if (status && status !== 'all') {
            where.status = status;
        }

        // Category filter
        if (categoryId) {
            where.categoryId = Number(categoryId);
        }

        // Project filter
        if (projectId) {
            where.projectId = Number(projectId);
        }

        // Search filter
        if (search) {
            where[Op.or] = [
                { name: { [Op.like]: `%${search}%` } },
                { nameAr: { [Op.like]: `%${search}%` } },
            ];
        }

        // Owner filter (requires join)
        let projectWhere: any = undefined;
        if (ownerId) {
            projectWhere = { ownerId: Number(ownerId) };
        }

        // Sorting
        let order: any[] = [];
        switch (sort) {
            case 'oldest':
                order = [['createdAt', 'ASC']];
                break;
            case 'name':
                order = [['name', 'ASC']];
                break;
            case 'price_high':
                order = [['basePrice', 'DESC']];
                break;
            case 'price_low':
                order = [['basePrice', 'ASC']];
                break;
            case 'rating':
                order = [['averageRating', 'DESC']];
                break;
            case 'pending_first':
                order = [
                    [require('sequelize').literal(`CASE WHEN \`Product\`.\`status\` = 'pending' THEN 0 ELSE 1 END`), 'ASC'],
                    ['createdAt', 'DESC'],
                ];
                break;
            case 'newest':
            default:
                order = [['createdAt', 'DESC']];
                break;
        }

        // Build include with optional project filter
        const includeWithFilter = productListInclude.map((inc: any) => {
            if (inc.as === 'project' && projectWhere) {
                return { ...inc, where: projectWhere };
            }
            return inc;
        });

        const { count, rows } = await Product.findAndCountAll({
            where,
            include: includeWithFilter,
            order,
            limit: Number(limit),
            offset,
            distinct: true,
        });

        return sendPaginated(res, rows, {
            page: Number(page),
            limit: Number(limit),
            total: count,
        });
    } catch (error: any) {
        console.error('Error fetching admin products:', error);
        return sendError(res, 'SERVER_ERROR', 'Error fetching products', 500, error);
    }
};

/**
 * Get single product by ID with full details
 */
export const getProductById = async (req: Request, res: Response) => {
    try {
        const { id } = req.params;

        const product = await Product.findByPk(id, {
            include: productDetailInclude,
        });

        if (!product) {
            return sendNotFound(res, 'Product');
        }

        await attachOwnerToProduct(product);

        return sendSuccess(res, product, 'Product retrieved');
    } catch (error: any) {
        console.error('Error fetching product:', error);
        return sendError(res, 'SERVER_ERROR', 'Error fetching product', 500, error);
    }
};

/**
 * Approve a pending product
 */
export const approveProduct = async (req: Request, res: Response) => {
    try {
        const { id } = req.params;

        const product = await Product.findByPk(id);
        if (!product) {
            return sendNotFound(res, 'Product');
        }

        await product.update({
            status: 'approved',
            rejectionReason: null,
        });

        // Reload with associations
        await product.reload({ include: productDetailInclude });
        await attachOwnerToProduct(product);

        // Send notification to project owner
        if (product.project?.ownerId) {
            NotificationTemplates.productApproved(
                product.project.ownerId,
                product.id,
                product.name
            );
        }

        return sendSuccess(res, product, 'Product approved successfully');
    } catch (error: any) {
        console.error('Error approving product:', error);
        return sendError(res, 'SERVER_ERROR', 'Error approving product', 500, error);
    }
};

/**
 * Reject a product with reason
 */
export const rejectProduct = async (req: Request, res: Response) => {
    try {
        const { id } = req.params;
        const { reason } = req.body;

        if (!reason || reason.trim() === '') {
            return sendError(res, 'VALIDATION_ERROR', 'Rejection reason is required', 400);
        }

        const product = await Product.findByPk(id);
        if (!product) {
            return sendNotFound(res, 'Product');
        }

        await product.update({
            status: 'rejected',
            rejectionReason: reason.trim(),
        });

        await product.reload({ include: productDetailInclude });
        await attachOwnerToProduct(product);

        // Send notification to project owner
        if (product.project?.ownerId) {
            NotificationTemplates.productRejected(
                product.project.ownerId,
                product.id,
                product.name,
                reason.trim()
            );
        }

        return sendSuccess(res, product, 'Product rejected');
    } catch (error: any) {
        console.error('Error rejecting product:', error);
        return sendError(res, 'SERVER_ERROR', 'Error rejecting product', 500, error);
    }
};

/**
 * Disable an approved product (admin moderation)
 */
export const disableProduct = async (req: Request, res: Response) => {
    try {
        const { id } = req.params;
        const { reason } = req.body;

        if (!reason || reason.trim() === '') {
            return sendError(res, 'VALIDATION_ERROR', 'Disable reason is required', 400);
        }

        const product = await Product.findByPk(id);
        if (!product) {
            return sendNotFound(res, 'Product');
        }

        // Store previous status in rejection_reason field with prefix
        await product.update({
            isAvailable: false,
            rejectionReason: `[DISABLED] ${reason.trim()}`,
        });

        await product.reload({ include: productDetailInclude });
        await attachOwnerToProduct(product);

        // Send notification to project owner
        if (product.project?.ownerId) {
            NotificationTemplates.productDisabled(
                product.project.ownerId,
                product.id,
                product.name,
                reason.trim()
            );
        }

        return sendSuccess(res, product, 'Product disabled');
    } catch (error: any) {
        console.error('Error disabling product:', error);
        return sendError(res, 'SERVER_ERROR', 'Error disabling product', 500, error);
    }
};

/**
 * Enable a disabled product
 */
export const enableProduct = async (req: Request, res: Response) => {
    try {
        const { id } = req.params;

        const product = await Product.findByPk(id);
        if (!product) {
            return sendNotFound(res, 'Product');
        }

        await product.update({
            isAvailable: true,
            rejectionReason: null,
        });

        await product.reload({ include: productDetailInclude });
        await attachOwnerToProduct(product);

        // Send notification to project owner
        if (product.project?.ownerId) {
            NotificationTemplates.productEnabled(
                product.project.ownerId,
                product.id,
                product.name
            );
        }

        return sendSuccess(res, product, 'Product enabled');
    } catch (error: any) {
        console.error('Error enabling product:', error);
        return sendError(res, 'SERVER_ERROR', 'Error enabling product', 500, error);
    }
};

