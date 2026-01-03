import { Request, Response, NextFunction } from 'express';
import { Op } from 'sequelize';
import { Review, User, Product, Notification } from '../models';
import Project from '../models/Project';

// Helper to recalculate product rating after review status changes
async function recalculateProductRating(productId: number): Promise<void> {
    const result = await Review.findOne({
        where: { productId, status: 'approved' },
        attributes: [
            [Review.sequelize!.fn('AVG', Review.sequelize!.col('rating')), 'avgRating'],
            [Review.sequelize!.fn('COUNT', Review.sequelize!.col('id')), 'totalCount'],
        ],
        raw: true,
    }) as any;

    const averageRating = parseFloat(result?.avgRating || '0');
    const totalReviews = parseInt(result?.totalCount || '0', 10);

    await Product.update(
        {
            averageRating: Math.round(averageRating * 10) / 10,
            totalReviews,
        },
        { where: { id: productId } }
    );
}

/**
 * Get all reviews with filters (admin)
 * GET /admin/reviews
 */
export const getAllReviews = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const {
            page = 1,
            limit = 20,
            status,
            productId,
            userId,
            sort = 'newest',
            search,
            searchField = 'all', // 'all', 'comment', 'userName', 'productName', 'projectOwner'
        } = req.query;

        const offset = (Number(page) - 1) * Number(limit);

        // Build where clause
        const whereClause: any = {};
        const userWhereClause: any = {};
        const productWhereClause: any = {};
        const projectWhereClause: any = {};

        if (status && status !== 'all') {
            whereClause.status = status;
        }

        if (productId) {
            whereClause.productId = Number(productId);
        }

        if (userId) {
            whereClause.userId = Number(userId);
        }

        // Handle search
        if (search && typeof search === 'string' && search.trim()) {
            const searchTerm = `%${search.trim()}%`;

            switch (searchField) {
                case 'comment':
                    whereClause.comment = { [Op.like]: searchTerm };
                    break;
                case 'userName':
                    userWhereClause.fullName = { [Op.like]: searchTerm };
                    break;
                case 'productName':
                    productWhereClause[Op.or] = [
                        { name: { [Op.like]: searchTerm } },
                        { nameAr: { [Op.like]: searchTerm } },
                    ];
                    break;
                case 'projectOwner':
                    projectWhereClause[Op.or] = [
                        { name: { [Op.like]: searchTerm } },
                        { nameAr: { [Op.like]: searchTerm } },
                    ];
                    break;
                case 'all':
                default:
                    // Search across all fields using subqueries
                    whereClause[Op.or] = [
                        { comment: { [Op.like]: searchTerm } },
                        { '$user.full_name$': { [Op.like]: searchTerm } },
                        { '$product.name$': { [Op.like]: searchTerm } },
                        { '$product.name_ar$': { [Op.like]: searchTerm } },
                        { '$product->project.name$': { [Op.like]: searchTerm } },
                        { '$product->project.name_ar$': { [Op.like]: searchTerm } },
                    ];
                    break;
            }
        }

        // Build order
        let order: any[] = [['createdAt', 'DESC']];
        switch (sort) {
            case 'oldest':
                order = [['createdAt', 'ASC']];
                break;
            case 'rating_high':
                order = [['rating', 'DESC']];
                break;
            case 'rating_low':
                order = [['rating', 'ASC']];
                break;
            case 'pending_first':
                order = [
                    [Review.sequelize!.literal("CASE WHEN `Review`.`status` = 'pending' THEN 0 ELSE 1 END"), 'ASC'],
                    ['createdAt', 'DESC'],
                ];
                break;
        }

        // Build include with conditional where clauses
        const userInclude: any = {
            model: User,
            as: 'user',
            attributes: ['id', 'fullName', 'email', 'avatarUrl'],
        };
        if (Object.keys(userWhereClause).length > 0) {
            userInclude.where = userWhereClause;
        }

        const projectInclude: any = {
            model: Project,
            as: 'project',
            attributes: ['id', 'name', 'nameAr'],
        };
        if (Object.keys(projectWhereClause).length > 0) {
            projectInclude.where = projectWhereClause;
        }

        const productInclude: any = {
            model: Product,
            as: 'product',
            attributes: ['id', 'name', 'nameAr', 'posterImageUrl'],
            include: [projectInclude],
        };
        if (Object.keys(productWhereClause).length > 0) {
            productInclude.where = productWhereClause;
        }

        const { count, rows } = await Review.findAndCountAll({
            where: whereClause,
            include: [userInclude, productInclude],
            order,
            limit: Number(limit),
            offset,
            subQuery: false, // Required for searching on associated models
        });

        res.json({
            success: true,
            data: rows,
            pagination: {
                total: count,
                page: Number(page),
                limit: Number(limit),
                totalPages: Math.ceil(count / Number(limit)),
            },
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Get review by ID (admin)
 * GET /admin/reviews/:id
 */
export const getReviewById = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { id } = req.params;

        const review = await Review.findByPk(id, {
            include: [
                { model: User, as: 'user', attributes: ['id', 'fullName', 'email', 'avatarUrl'] },
                {
                    model: Product,
                    as: 'product',
                    attributes: ['id', 'name', 'nameAr', 'posterImageUrl'],
                    include: [
                        { model: Project, as: 'project', attributes: ['id', 'name', 'nameAr', 'ownerId'] },
                    ],
                },
            ],
        });

        if (!review) {
            return res.status(404).json({
                success: false,
                error: { code: 'NOT_FOUND', message: 'Review not found' },
            });
        }

        res.json({
            success: true,
            data: review,
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Approve a review (admin)
 * PUT /admin/reviews/:id/approve
 */
export const approveReview = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { id } = req.params;

        const review = await Review.findByPk(id);

        if (!review) {
            return res.status(404).json({
                success: false,
                error: { code: 'NOT_FOUND', message: 'Review not found' },
            });
        }

        review.status = 'approved';
        await review.save();

        // Recalculate product rating
        await recalculateProductRating(review.productId);

        // Notify user that their review was approved
        await Notification.create({
            userId: review.userId,
            type: 'review_approved',
            title: 'Review Approved',
            titleAr: 'تمت الموافقة على تقييمك',
            data: { reviewId: review.id, productId: review.productId },
        });

        const fullReview = await Review.findByPk(id, {
            include: [
                { model: User, as: 'user', attributes: ['id', 'fullName', 'email', 'avatarUrl'] },
                { model: Product, as: 'product', attributes: ['id', 'name', 'nameAr'] },
            ],
        });

        res.json({
            success: true,
            data: fullReview,
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Reject a review (admin)
 * PUT /admin/reviews/:id/reject
 */
export const rejectReview = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { id } = req.params;
        const { reason } = req.body;

        const review = await Review.findByPk(id);

        if (!review) {
            return res.status(404).json({
                success: false,
                error: { code: 'NOT_FOUND', message: 'Review not found' },
            });
        }

        const wasApproved = review.status === 'approved';
        review.status = 'rejected';
        await review.save();

        // Recalculate product rating if was previously approved
        if (wasApproved) {
            await recalculateProductRating(review.productId);
        }

        // Notify user that their review was rejected
        await Notification.create({
            userId: review.userId,
            type: 'review_rejected',
            title: 'Review Rejected',
            titleAr: 'تم رفض تقييمك',
            data: { reviewId: review.id, productId: review.productId, reason },
        });

        const fullReview = await Review.findByPk(id, {
            include: [
                { model: User, as: 'user', attributes: ['id', 'fullName', 'email', 'avatarUrl'] },
                { model: Product, as: 'product', attributes: ['id', 'name', 'nameAr'] },
            ],
        });

        res.json({
            success: true,
            data: fullReview,
        });
    } catch (error) {
        next(error);
    }
};
