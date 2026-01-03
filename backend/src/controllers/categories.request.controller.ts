import { Request, Response } from 'express';
import { Category } from '../models';
import { asyncHandler, sendSuccess, sendError } from '../utils/helpers';
import { ERROR_CODES } from '../config/constants';

/**
 * Request a new category
 * POST /categories/request
 */
export const requestCategory = asyncHandler(
    async (req: Request, res: Response) => {
        const { name, nameAr, icon, parentId } = req.body;
        const userId = req.user?.id;

        if (!userId) {
            return sendError(res, ERROR_CODES.AUTHENTICATION_ERROR, 'User not found', 401);
        }

        // If parentId provided, verify parent exists and is active
        if (parentId) {
            const parentCategory = await Category.findByPk(parentId);
            if (!parentCategory) {
                return sendError(res, ERROR_CODES.NOT_FOUND, 'Parent category not found', 404);
            }
            if (parentCategory.status !== 'active') {
                return sendError(res, ERROR_CODES.BAD_REQUEST, 'Parent category is not active', 400);
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

        // Create category with pending status
        const category = await Category.create({
            name,
            nameAr,
            icon: icon || null,
            parentId: parentId || null,
            sortOrder: 0, // Default sort order
            isActive: true, // Technically active but status is pending
            status: 'pending',
            createdBy: userId,
        });

        sendSuccess(res, { category }, 'Category request submitted successfully', 201);
    }
);

/**
 * Get my requested categories
 * GET /categories/my-requests
 */
export const getMyRequests = asyncHandler(
    async (req: Request, res: Response) => {
        const userId = req.user?.id;

        if (!userId) {
            return sendError(res, ERROR_CODES.AUTHENTICATION_ERROR, 'User not found', 401);
        }

        const categories = await Category.findAll({
            where: { createdBy: userId },
            include: [
                {
                    model: Category,
                    as: 'parent',
                    attributes: ['id', 'name', 'nameAr'],
                },
            ],
            order: [['createdAt', 'DESC']],
        });

        sendSuccess(res, { categories });
    }
);
