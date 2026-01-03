import { Request, Response } from 'express';
import { Op } from 'sequelize';
import { Category } from '../models';
import { asyncHandler, sendSuccess, sendError, getPagination } from '../utils/helpers';
import { ERROR_CODES, PAGINATION } from '../config/constants';

// ==================== Public Endpoints ====================

/**
 * Get all categories with subcategories (hierarchical)
 * GET /categories
 */
export const getCategories = asyncHandler(
  async (req: Request, res: Response) => {
    const { includeInactive } = req.query;

    // Build where clause
    const whereClause: { status?: string } = {};

    // By default, only show active categories for public API
    if (includeInactive !== 'true') {
      whereClause.status = 'active';
    }

    // Get parent categories with their children
    const categories = await Category.findAll({
      where: {
        ...whereClause,
        parentId: null, // Only get parent categories
      },
      include: [
        {
          model: Category,
          as: 'children',
          where: includeInactive === 'true' ? {} : { status: 'active' },
          required: false,
          order: [['sortOrder', 'ASC']],
        },
      ],
      order: [
        ['sortOrder', 'ASC'],
        [{ model: Category, as: 'children' }, 'sortOrder', 'ASC'],
      ],
    });

    sendSuccess(res, { categories });
  }
);

/**
 * Get a single category by ID
 * GET /categories/:id
 */
export const getCategoryById = asyncHandler(
  async (req: Request, res: Response) => {
    const { id } = req.params;

    const category = await Category.findByPk(id, {
      include: [
        {
          model: Category,
          as: 'children',
          where: { status: 'active' },
          required: false,
          order: [['sortOrder', 'ASC']],
        },
        {
          model: Category,
          as: 'parent',
          required: false,
        },
      ],
    });

    if (!category) {
      return sendError(res, ERROR_CODES.NOT_FOUND, 'Category not found', 404);
    }

    // Check if category is active (for public access)
    if (category.status !== 'active') {
      return sendError(res, ERROR_CODES.NOT_FOUND, 'Category not found', 404);
    }

    sendSuccess(res, { category });
  }
);

/**
 * Get products in a category (placeholder - will be implemented with Products)
 * GET /categories/:id/products
 */
export const getCategoryProducts = asyncHandler(
  async (req: Request, res: Response) => {
    const { id } = req.params;
    const { page, limit } = req.query;

    // Verify category exists and is active
    const category = await Category.findByPk(id);

    if (!category || category.status !== 'active') {
      return sendError(res, ERROR_CODES.NOT_FOUND, 'Category not found', 404);
    }

    // Get pagination params
    const pagination = getPagination(
      Number(page) || PAGINATION.DEFAULT_PAGE,
      Number(limit) || PAGINATION.DEFAULT_LIMIT
    );

    // TODO: Implement when Product model is ready
    // For now, return empty array with category info
    sendSuccess(res, {
      category: {
        id: category.id,
        name: category.name,
        nameAr: category.nameAr,
      },
      products: [],
      pagination: {
        currentPage: pagination.page,
        totalPages: 0,
        totalItems: 0,
        itemsPerPage: pagination.limit,
      },
    });
  }
);

// ==================== Admin Endpoints ====================

/**
 * Get all categories for admin (including inactive)
 * GET /admin/categories
 */
export const adminGetCategories = asyncHandler(
  async (req: Request, res: Response) => {
    // Get parent categories with their children (including inactive)
    const categories = await Category.findAll({
      where: { parentId: null },
      include: [
        {
          model: Category,
          as: 'children',
          required: false,
        },
      ],
      order: [
        ['sortOrder', 'ASC'],
        [{ model: Category, as: 'children' }, 'sortOrder', 'ASC'],
      ],
    });

    // Get stats
    const totalCategories = await Category.count();
    const parentCategories = await Category.count({ where: { parentId: null } });
    const activeCategories = await Category.count({ where: { isActive: true } });

    sendSuccess(res, {
      categories,
      stats: {
        total: totalCategories,
        parents: parentCategories,
        subcategories: totalCategories - parentCategories,
        active: activeCategories,
        inactive: totalCategories - activeCategories,
      },
    });
  }
);

/**
 * Create a new category
 * POST /admin/categories
 */
export const createCategory = asyncHandler(
  async (req: Request, res: Response) => {
    const { name, nameAr, icon, parentId, sortOrder, isActive } = req.body;

    // If parentId provided, verify parent exists
    if (parentId) {
      const parentCategory = await Category.findByPk(parentId);
      if (!parentCategory) {
        return sendError(res, ERROR_CODES.NOT_FOUND, 'Parent category not found', 404);
      }
      // Ensure parent is not a subcategory (only 2 levels allowed)
      if (parentCategory.parentId !== null) {
        return sendError(
          res,
          ERROR_CODES.BAD_REQUEST,
          'Cannot create subcategory of a subcategory. Only 2 levels are allowed.',
          400
        );
      }
    }

    // Get max sort order if not provided
    let finalSortOrder = sortOrder;
    if (finalSortOrder === undefined) {
      const maxSortOrder = await Category.max('sortOrder', {
        where: { parentId: parentId || null },
      });
      finalSortOrder = (maxSortOrder as number || 0) + 1;
    }

    // Create category
    const category = await Category.create({
      name,
      nameAr,
      icon: icon || null,
      parentId: parentId || null,
      sortOrder: finalSortOrder,
      isActive: isActive !== false, // Default to true
    });

    sendSuccess(res, { category }, undefined, 201);
  }
);

/**
 * Update a category
 * PUT /admin/categories/:id
 */
export const updateCategory = asyncHandler(
  async (req: Request, res: Response) => {
    const { id } = req.params;
    const { name, nameAr, icon, parentId, sortOrder, isActive } = req.body;

    // Find category
    const category = await Category.findByPk(id);
    if (!category) {
      return sendError(res, ERROR_CODES.NOT_FOUND, 'Category not found', 404);
    }

    // Validate parentId if provided
    if (parentId !== undefined) {
      if (parentId !== null) {
        // Can't be own parent
        if (Number(parentId) === category.id) {
          return sendError(
            res,
            ERROR_CODES.BAD_REQUEST,
            'Category cannot be its own parent',
            400
          );
        }

        // Verify parent exists
        const parentCategory = await Category.findByPk(parentId);
        if (!parentCategory) {
          return sendError(res, ERROR_CODES.NOT_FOUND, 'Parent category not found', 404);
        }

        // Ensure parent is not a subcategory
        if (parentCategory.parentId !== null) {
          return sendError(
            res,
            ERROR_CODES.BAD_REQUEST,
            'Cannot set parent to a subcategory. Only 2 levels are allowed.',
            400
          );
        }

        // Can't make a parent category (with children) into a subcategory
        if (category.parentId === null) {
          const hasChildren = await Category.count({ where: { parentId: category.id } });
          if (hasChildren > 0) {
            return sendError(
              res,
              ERROR_CODES.BAD_REQUEST,
              'Cannot convert a parent category with subcategories to a subcategory. Remove or reassign children first.',
              400
            );
          }
        }
      }
    }

    // Update category
    await category.update({
      name: name ?? category.name,
      nameAr: nameAr ?? category.nameAr,
      icon: icon !== undefined ? icon : category.icon,
      parentId: parentId !== undefined ? parentId : category.parentId,
      sortOrder: sortOrder ?? category.sortOrder,
      isActive: isActive !== undefined ? isActive : category.isActive,
    });

    // Reload with associations
    await category.reload({
      include: [
        { model: Category, as: 'parent' },
        { model: Category, as: 'children' },
      ],
    });

    sendSuccess(res, { category });
  }
);

/**
 * Delete a category
 * DELETE /admin/categories/:id
 */
export const deleteCategory = asyncHandler(
  async (req: Request, res: Response) => {
    const { id } = req.params;

    const category = await Category.findByPk(id, {
      include: [{ model: Category, as: 'children' }],
    });

    if (!category) {
      return sendError(res, ERROR_CODES.NOT_FOUND, 'Category not found', 404);
    }

    // Check if category has children
    const childCount = await Category.count({ where: { parentId: category.id } });
    if (childCount > 0) {
      return sendError(
        res,
        ERROR_CODES.BAD_REQUEST,
        `Cannot delete category with ${childCount} subcategories. Delete or reassign subcategories first.`,
        400
      );
    }

    // TODO: Check if category has products when Product model is ready
    // const productCount = await Product.count({ where: { categoryId: category.id } });
    // if (productCount > 0) {
    //   return sendError(res, ERROR_CODES.BAD_REQUEST, `Cannot delete category with ${productCount} products`, 400);
    // }

    // Delete category
    await category.destroy();

    sendSuccess(res, { message: 'Category deleted successfully' });
  }
);

/**
 * Reorder categories
 * PUT /admin/categories/reorder
 */
export const reorderCategories = asyncHandler(
  async (req: Request, res: Response) => {
    const { orders } = req.body;
    // orders: [{ id: 1, sortOrder: 0 }, { id: 2, sortOrder: 1 }, ...]

    if (!Array.isArray(orders) || orders.length === 0) {
      return sendError(
        res,
        ERROR_CODES.BAD_REQUEST,
        'Please provide an array of category orders',
        400
      );
    }

    // Update each category's sort order
    const updatePromises = orders.map(({ id, sortOrder }: { id: number; sortOrder: number }) =>
      Category.update({ sortOrder }, { where: { id } })
    );

    await Promise.all(updatePromises);

    // Fetch updated categories
    const categories = await Category.findAll({
      where: { parentId: null },
      include: [{ model: Category, as: 'children' }],
      order: [
        ['sortOrder', 'ASC'],
        [{ model: Category, as: 'children' }, 'sortOrder', 'ASC'],
      ],
    });

    sendSuccess(res, {
      message: 'Categories reordered successfully',
      categories,
    });
  }
);

/**
 * Toggle category active status
 * PUT /admin/categories/:id/toggle
 */
export const toggleCategory = asyncHandler(
  async (req: Request, res: Response) => {
    const { id } = req.params;

    const category = await Category.findByPk(id);
    if (!category) {
      return sendError(res, ERROR_CODES.NOT_FOUND, 'Category not found', 404);
    }

    // Toggle isActive
    await category.update({ isActive: !category.isActive });

    // If disabling a parent category, also disable its children
    if (!category.isActive && category.parentId === null) {
      await Category.update(
        { isActive: false },
        { where: { parentId: category.id } }
      );
    }

    sendSuccess(res, {
      message: `Category ${category.isActive ? 'activated' : 'deactivated'} successfully`,
      category,
    });
  }
);

