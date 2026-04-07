import { Request, Response, NextFunction } from 'express';
import { Op } from 'sequelize';
import { Review, Transaction, User, Product, Notification } from '../models';
import Project from '../models/Project';

// Helper to get project owner ID from product
async function getProjectOwnerId(productId: number): Promise<number | null> {
    const product = await Product.findByPk(productId, {
        include: [{ model: Project, as: 'project', attributes: ['ownerId'] }],
    });
    return (product as any)?.project?.ownerId ?? null;
}

// Helper to recalculate product rating after review changes
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
            averageRating: Math.round(averageRating * 10) / 10, // Round to 1 decimal
            totalReviews,
        },
        { where: { id: productId } }
    );
}

// Helper to recalculate project rating from all its products' reviews
async function recalculateProjectRating(productId: number): Promise<void> {
    // Find the project this product belongs to
    const product = await Product.findByPk(productId, {
        attributes: ['id', 'projectId'],
    });
    if (!product || !product.projectId) return;

    // Get average of all approved reviews for products in this project
    const result = await Review.findOne({
        where: { status: 'approved' },
        include: [{
            model: Product,
            as: 'product',
            attributes: [],
            where: { projectId: product.projectId },
        }],
        attributes: [
            [Review.sequelize!.fn('AVG', Review.sequelize!.col('Review.rating')), 'avgRating'],
            [Review.sequelize!.fn('COUNT', Review.sequelize!.col('Review.id')), 'totalCount'],
        ],
        raw: true,
    }) as any;

    const averageRating = parseFloat(result?.avgRating || '0');
    const totalReviews = parseInt(result?.totalCount || '0', 10);

    await Project.update(
        {
            averageRating: Math.round(averageRating * 10) / 10,
            totalReviews,
        },
        { where: { id: product.projectId } }
    );
}

/**
 * Create a new review (requires confirmed transaction)
 * POST /reviews
 */
export const createReview = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = req.user!.id;
        const { transactionId, productId, rating, comment } = req.body;

        // Validate input
        if (!transactionId || !productId || !rating) {
            return res.status(400).json({
                success: false,
                error: { code: 'MISSING_FIELDS', message: 'Transaction ID, product ID, and rating are required' },
            });
        }

        if (rating < 1 || rating > 5) {
            return res.status(400).json({
                success: false,
                error: { code: 'INVALID_RATING', message: 'Rating must be between 1 and 5' },
            });
        }

        // Verify transaction exists and is confirmed
        const transaction = await Transaction.findByPk(transactionId);
        if (!transaction) {
            return res.status(404).json({
                success: false,
                error: { code: 'NOT_FOUND', message: 'Transaction not found' },
            });
        }

        // Check if transaction is delivered
        if (transaction.status !== 'delivered') {
            return res.status(400).json({
                success: false,
                error: {
                    code: 'NOT_DELIVERED',
                    message: 'Transaction must be delivered before leaving a review'
                },
            });
        }

        // Verify product matches transaction (if transaction has a product)
        if (transaction.productId && transaction.productId !== productId) {
            return res.status(400).json({
                success: false,
                error: { code: 'PRODUCT_MISMATCH', message: 'Product does not match transaction' },
            });
        }

        // Check for existing review
        const existingReview = await Review.findOne({
            where: {
                productId,
                userId,
                transactionId,
            },
        });

        if (existingReview) {
            return res.status(400).json({
                success: false,
                error: { code: 'ALREADY_REVIEWED', message: 'You have already reviewed this product for this transaction' },
            });
        }

        // Create review
        const review = await Review.create({
            productId,
            userId,
            transactionId,
            rating,
            comment: comment || null,
        });

        // Notify product owner
        const ownerId = await getProjectOwnerId(productId);
        if (ownerId) {
            await Notification.create({
                userId: ownerId,
                type: 'new_review',
                title: 'New Review',
                titleAr: 'تقييم جديد',
                data: { reviewId: review.id, productId, rating },
            });
        }

        // Fetch with associations
        const fullReview = await Review.findByPk(review.id, {
            include: [
                { model: User, as: 'user', attributes: ['id', 'fullName', 'avatarUrl'] },
                { model: Product, as: 'product', attributes: ['id', 'name'] },
            ],
        });

        // Recalculate product rating
        await recalculateProductRating(productId);

        // Recalculate project rating (aggregate from all products)
        await recalculateProjectRating(productId);

        res.status(201).json({
            success: true,
            data: fullReview,
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Get reviews for a product
 * GET /reviews/product/:productId
 */
export const getProductReviews = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { productId } = req.params;
        const { page = 1, limit = 20, status } = req.query;

        const offset = (Number(page) - 1) * Number(limit);

        const whereClause: any = {
            productId,
        };

        // By default, show only approved reviews to regular users
        // TODO: Check if user is admin or product owner to show all
        if (status) {
            whereClause.status = status;
        } else {
            whereClause.status = 'approved';
        }

        const { count, rows } = await Review.findAndCountAll({
            where: whereClause,
            include: [
                { model: User, as: 'user', attributes: ['id', 'fullName', 'avatarUrl'] },
            ],
            order: [['createdAt', 'DESC']],
            limit: Number(limit),
            offset,
        });

        // Calculate average rating
        const avgResult = await Review.findOne({
            where: { productId, status: 'approved' },
            attributes: [
                [Review.sequelize!.fn('AVG', Review.sequelize!.col('rating')), 'avgRating'],
                [Review.sequelize!.fn('COUNT', Review.sequelize!.col('id')), 'totalCount'],
            ],
            raw: true,
        }) as any;

        res.json({
            success: true,
            data: rows,
            stats: {
                averageRating: parseFloat(avgResult?.avgRating || '0').toFixed(1),
                totalReviews: parseInt(avgResult?.totalCount || '0', 10),
            },
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
 * Get user's reviews
 * GET /reviews/my
 */
export const getMyReviews = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = req.user!.id;
        const { page = 1, limit = 20 } = req.query;

        const offset = (Number(page) - 1) * Number(limit);

        const { count, rows } = await Review.findAndCountAll({
            where: { userId },
            include: [
                { model: Product, as: 'product', attributes: ['id', 'name', 'basePrice'] },
            ],
            order: [['createdAt', 'DESC']],
            limit: Number(limit),
            offset,
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
 * Update a review (only by owner)
 * PUT /reviews/:id
 */
export const updateReview = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = req.user!.id;
        const { id } = req.params;
        const { rating, comment } = req.body;

        const review = await Review.findByPk(id);

        if (!review) {
            return res.status(404).json({
                success: false,
                error: { code: 'NOT_FOUND', message: 'Review not found' },
            });
        }

        if (review.userId !== userId) {
            return res.status(403).json({
                success: false,
                error: { code: 'FORBIDDEN', message: 'You can only update your own reviews' },
            });
        }

        // Update fields
        if (rating !== undefined) {
            if (rating < 1 || rating > 5) {
                return res.status(400).json({
                    success: false,
                    error: { code: 'INVALID_RATING', message: 'Rating must be between 1 and 5' },
                });
            }
            review.rating = rating;
        }

        if (comment !== undefined) {
            review.comment = comment;
        }

        await review.save();

        const fullReview = await Review.findByPk(review.id, {
            include: [
                { model: User, as: 'user', attributes: ['id', 'fullName', 'avatarUrl'] },
                { model: Product, as: 'product', attributes: ['id', 'name'] },
            ],
        });

        // Recalculate product rating (in case rating changed)
        await recalculateProductRating(review.productId);

        res.json({
            success: true,
            data: fullReview,
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Delete a review (only by owner)
 * DELETE /reviews/:id
 */
export const deleteReview = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = req.user!.id;
        const { id } = req.params;

        const review = await Review.findByPk(id);

        if (!review) {
            return res.status(404).json({
                success: false,
                error: { code: 'NOT_FOUND', message: 'Review not found' },
            });
        }

        if (review.userId !== userId) {
            return res.status(403).json({
                success: false,
                error: { code: 'FORBIDDEN', message: 'You can only delete your own reviews' },
            });
        }

        const productId = review.productId;
        await review.destroy();

        // Recalculate product rating
        await recalculateProductRating(productId);

        res.json({
            success: true,
            message: 'Review deleted successfully',
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Reply to a review (only by product/project owner, once only)
 * POST /reviews/:id/reply
 */
export const replyToReview = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = req.user!.id;
        const { id } = req.params;
        const { reply } = req.body;

        if (!reply || !reply.trim()) {
            return res.status(400).json({
                success: false,
                error: { code: 'MISSING_FIELDS', message: 'Reply content is required' },
            });
        }

        const review = await Review.findByPk(id, {
            include: [
                {
                    model: Product,
                    as: 'product',
                    include: [{ model: Project, as: 'project', attributes: ['id', 'ownerId'] }],
                },
            ],
        });

        if (!review) {
            return res.status(404).json({
                success: false,
                error: { code: 'NOT_FOUND', message: 'Review not found' },
            });
        }

        // Check that current user is the project owner
        const projectOwnerId = (review as any).product?.project?.ownerId;
        if (projectOwnerId !== userId) {
            return res.status(403).json({
                success: false,
                error: { code: 'FORBIDDEN', message: 'Only the project owner can reply to reviews' },
            });
        }

        // Check if already replied
        if (review.ownerReply) {
            return res.status(400).json({
                success: false,
                error: { code: 'ALREADY_REPLIED', message: 'You have already replied to this review' },
            });
        }

        review.ownerReply = reply.trim();
        review.ownerReplyAt = new Date();
        await review.save();

        const fullReview = await Review.findByPk(review.id, {
            include: [
                { model: User, as: 'user', attributes: ['id', 'fullName', 'avatarUrl'] },
                { model: Product, as: 'product', attributes: ['id', 'name'] },
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
 * Update owner reply to a review
 * PUT /reviews/:id/reply
 */
export const updateReply = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = req.user!.id;
        const { id } = req.params;
        const { reply } = req.body;

        if (!reply || !reply.trim()) {
            return res.status(400).json({
                success: false,
                error: { code: 'MISSING_FIELDS', message: 'Reply content is required' },
            });
        }

        const review = await Review.findByPk(id, {
            include: [
                {
                    model: Product,
                    as: 'product',
                    include: [{ model: Project, as: 'project', attributes: ['id', 'ownerId'] }],
                },
            ],
        });

        if (!review) {
            return res.status(404).json({
                success: false,
                error: { code: 'NOT_FOUND', message: 'Review not found' },
            });
        }

        const projectOwnerId = (review as any).product?.project?.ownerId;
        if (projectOwnerId !== userId) {
            return res.status(403).json({
                success: false,
                error: { code: 'FORBIDDEN', message: 'Only the project owner can edit replies' },
            });
        }

        if (!review.ownerReply) {
            return res.status(400).json({
                success: false,
                error: { code: 'NO_REPLY', message: 'No reply exists to update' },
            });
        }

        review.ownerReply = reply.trim();
        review.ownerReplyAt = new Date();
        await review.save();

        const fullReview = await Review.findByPk(review.id, {
            include: [
                { model: User, as: 'user', attributes: ['id', 'fullName', 'avatarUrl'] },
                { model: Product, as: 'product', attributes: ['id', 'name'] },
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
 * Delete owner reply from a review
 * DELETE /reviews/:id/reply
 */
export const deleteReply = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = req.user!.id;
        const { id } = req.params;

        const review = await Review.findByPk(id, {
            include: [
                {
                    model: Product,
                    as: 'product',
                    include: [{ model: Project, as: 'project', attributes: ['id', 'ownerId'] }],
                },
            ],
        });

        if (!review) {
            return res.status(404).json({
                success: false,
                error: { code: 'NOT_FOUND', message: 'Review not found' },
            });
        }

        const projectOwnerId = (review as any).product?.project?.ownerId;
        if (projectOwnerId !== userId) {
            return res.status(403).json({
                success: false,
                error: { code: 'FORBIDDEN', message: 'Only the project owner can delete replies' },
            });
        }

        review.ownerReply = null as any;
        review.ownerReplyAt = null as any;
        await review.save();

        res.json({
            success: true,
            message: 'Reply deleted successfully',
        });
    } catch (error) {
        next(error);
    }
};
