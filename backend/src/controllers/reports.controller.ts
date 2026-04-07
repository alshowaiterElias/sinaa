import { Request, Response } from 'express';
import { Op, fn, col, literal } from 'sequelize';
import sequelize from '../config/database';
import { Product, Transaction, Conversation, Review, User } from '../models';
import Project from '../models/Project';

/**
 * Get owner reports / dashboard analytics
 * GET /projects/my-project/reports
 */
export const getOwnerReports = async (req: Request, res: Response) => {
    try {
        const userId = req.user!.id;

        // Find the owner's project
        const project = await Project.findOne({ where: { ownerId: userId } });
        if (!project) {
            return res.status(404).json({
                success: false,
                error: { code: 'NO_PROJECT', message: 'You do not have a project' },
            });
        }

        const projectId = project.id;

        // 1. Product counts by status
        const productCounts = await Product.findAll({
            where: { projectId },
            attributes: [
                'status',
                [fn('COUNT', col('id')), 'count'],
            ],
            group: ['status'],
            raw: true,
        }) as any[];

        const products: Record<string, number> = { total: 0, approved: 0, pending: 0, rejected: 0 };
        for (const row of productCounts) {
            products[row.status] = parseInt(row.count, 10);
            products.total += parseInt(row.count, 10);
        }

        // 2. Active conversations count
        const activeConversations = await Conversation.count({
            where: { projectId },
        });

        // 3. Get all conversation IDs for this project
        const projectConversations = await Conversation.findAll({
            where: { projectId },
            attributes: ['id'],
            raw: true,
        });
        const conversationIds = projectConversations.map((c: any) => c.id);

        // 4. Order counts by status
        let orders: Record<string, number> = { total: 0, pending: 0, preparing: 0, ready_to_deliver: 0, delivered: 0, cancelled: 0, disputed: 0 };
        let totalRevenue = 0;
        let mostOrderedProduct: any = null;
        let topProducts: any[] = [];
        let recentOrders: any[] = [];

        if (conversationIds.length > 0) {
            const orderCounts = await Transaction.findAll({
                where: { conversationId: { [Op.in]: conversationIds } },
                attributes: [
                    'status',
                    [fn('COUNT', col('Transaction.id')), 'count'],
                ],
                group: ['status'],
                raw: true,
            }) as any[];

            for (const row of orderCounts) {
                orders[row.status] = parseInt(row.count, 10);
                orders.total += parseInt(row.count, 10);
            }

            // 5. Total revenue (sum of base_price for delivered transactions)
            const revenueResult = await Transaction.findOne({
                where: {
                    conversationId: { [Op.in]: conversationIds },
                    status: 'delivered',
                },
                include: [{
                    model: Product,
                    as: 'product',
                    attributes: [],
                }],
                attributes: [
                    [fn('SUM', col('product.base_price')), 'totalRevenue'],
                ],
                raw: true,
            }) as any;

            totalRevenue = parseFloat(revenueResult?.totalRevenue || '0');

            // 6. Most ordered product
            const topProductRows = await Transaction.findAll({
                where: {
                    conversationId: { [Op.in]: conversationIds },
                    productId: { [Op.ne]: null as any },
                },
                include: [{
                    model: Product,
                    as: 'product',
                    attributes: ['id', 'name', 'nameAr', 'basePrice', 'posterImageUrl', 'averageRating'],
                }],
                attributes: [
                    'productId',
                    [fn('COUNT', col('Transaction.id')), 'orderCount'],
                ],
                group: ['productId', 'product.id', 'product.name', 'product.name_ar', 'product.base_price', 'product.poster_image_url', 'product.average_rating'],
                order: [[literal('orderCount'), 'DESC']],
                limit: 5,
                raw: true,
                nest: true,
            }) as any[];

            topProducts = topProductRows.map((row: any) => ({
                id: row.product?.id || row.productId,
                name: row.product?.name || '',
                nameAr: row.product?.nameAr || row.product?.name_ar || '',
                basePrice: parseFloat(row.product?.basePrice || row.product?.base_price || '0'),
                posterImageUrl: row.product?.posterImageUrl || row.product?.poster_image_url || null,
                averageRating: parseFloat(row.product?.averageRating || row.product?.average_rating || '0'),
                orderCount: parseInt(row.orderCount, 10),
            }));

            if (topProducts.length > 0) {
                mostOrderedProduct = topProducts[0];
            }

            // 7. Recent orders (last 5) 
            const recentTx = await Transaction.findAll({
                where: { conversationId: { [Op.in]: conversationIds } },
                include: [
                    {
                        model: Product,
                        as: 'product',
                        attributes: ['id', 'name', 'nameAr', 'basePrice'],
                    },
                    {
                        model: User,
                        as: 'initiator',
                        attributes: ['id', 'fullName'],
                    },
                ],
                order: [['createdAt', 'DESC']],
                limit: 5,
            });

            recentOrders = recentTx.map((tx: any) => ({
                id: tx.id,
                status: tx.status,
                createdAt: tx.createdAt,
                productName: tx.product?.name || null,
                productNameAr: tx.product?.nameAr || null,
                productPrice: tx.product?.basePrice ? parseFloat(tx.product.basePrice) : null,
                customerName: tx.initiator?.fullName || null,
            }));
        }

        // 8. Average rating across project products
        const ratingResult = await Product.findOne({
            where: { projectId, status: 'approved' },
            attributes: [
                [fn('AVG', col('average_rating')), 'avgRating'],
                [fn('SUM', col('total_reviews')), 'totalReviews'],
            ],
            raw: true,
        }) as any;

        const averageRating = parseFloat(ratingResult?.avgRating || '0');
        const totalReviews = parseInt(ratingResult?.totalReviews || '0', 10);

        res.json({
            success: true,
            data: {
                project: {
                    id: project.id,
                    name: project.name,
                    nameAr: project.nameAr,
                },
                products,
                activeConversations,
                orders,
                totalRevenue: Math.round(totalRevenue * 100) / 100,
                averageRating: Math.round(averageRating * 10) / 10,
                totalReviews,
                mostOrderedProduct,
                topProducts,
                recentOrders,
            },
        });
    } catch (error) {
        console.error('[Reports] Error:', error);
        res.status(500).json({
            success: false,
            error: { code: 'SERVER_ERROR', message: 'Failed to generate reports' },
        });
    }
};
