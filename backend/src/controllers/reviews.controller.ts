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

        // Check if transaction is confirmed (either by both parties or auto-confirmed)
        if (transaction.status !== 'confirmed') {
            // Check if auto-confirm time has passed
            if (transaction.status === 'pending' && new Date() >= transaction.autoConfirmAt) {
                // Auto-confirm the transaction
                transaction.status = 'confirmed';
                await transaction.save();
            } else {
                return res.status(400).json({
                    success: false,
                    error: {
                        code: 'NOT_CONFIRMED',
                        message: 'Transaction must be confirmed before leaving a review',
                        autoConfirmAt: transaction.autoConfirmAt,
                    },
                });
            }
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
                { model: Product, as: 'product', attributes: ['id', 'name', 'price'] },
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

        // Reset to pending if edited
        review.status = 'pending';

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

        await review.destroy();

        res.json({
            success: true,
            message: 'Review deleted successfully',
        });
    } catch (error) {
        next(error);
    }
};
