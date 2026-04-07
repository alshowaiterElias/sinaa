import { Request, Response, NextFunction } from 'express';
import { Op } from 'sequelize';
import { Transaction, User, Conversation, Product, SupportTicket, Notification } from '../models';
import Project from '../models/Project';
import Message from '../models/Message';

// Helper to get the other party in a conversation
async function getOtherPartyId(conversationId: number, currentUserId: number): Promise<number | null> {
    const conversation = await Conversation.findByPk(conversationId);
    if (!conversation) return null;

    if (conversation.user1Id === currentUserId) {
        return conversation.user2Id;
    } else if (conversation.user2Id === currentUserId) {
        return conversation.user1Id;
    }
    return null;
}

// Helper to determine if user is customer or seller in conversation
async function getUserRole(conversationId: number, userId: number): Promise<'customer' | 'seller' | null> {
    const conversation = await Conversation.findByPk(conversationId, {
        include: [{ model: Project, as: 'project' }],
    });
    if (!conversation) return null;

    if (conversation.user1Id !== userId && conversation.user2Id !== userId) {
        return null;
    }

    if (conversation.project?.ownerId === userId) {
        return 'seller';
    }

    return 'customer';
}

/**
 * Initiate a new transaction (Order Request)
 * POST /transactions
 */
export const initiateTransaction = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = req.user!.id;
        const { conversationId, productId } = req.body;

        if (!conversationId) {
            return res.status(400).json({
                success: false,
                error: { code: 'MISSING_FIELD', message: 'Conversation ID is required' },
            });
        }

        const conversation = await Conversation.findByPk(conversationId);
        if (!conversation) {
            return res.status(404).json({
                success: false,
                error: { code: 'NOT_FOUND', message: 'Conversation not found' },
            });
        }

        const userRole = await getUserRole(conversationId, userId);
        if (!userRole || userRole !== 'customer') {
            return res.status(403).json({
                success: false,
                error: { code: 'FORBIDDEN', message: 'Only a customer can initiate an order.' },
            });
        }

        // Allow multiple transactions per conversation as long as products are different
        if (productId) {
            const existingProductTransaction = await Transaction.findOne({
                where: {
                    conversationId,
                    productId,
                    status: ['pending', 'preparing', 'ready_to_deliver'],
                },
            });

            if (existingProductTransaction) {
                return res.status(400).json({
                    success: false,
                    error: { code: 'PRODUCT_ORDER_ACTIVE', message: 'An active order already exists for this product' },
                });
            }
        }

        let productName: string | null = null;
        let productNameAr: string | null = null;
        if (productId) {
            const product = await Product.findByPk(productId);
            if (!product) {
                return res.status(404).json({
                    success: false,
                    error: { code: 'NOT_FOUND', message: 'Product not found' },
                });
            }
            productName = product.name;
            productNameAr = product.nameAr || product.name;
        }

        const transaction = await Transaction.create({
            conversationId,
            productId: productId || null,
            initiatedBy: userId,
            status: 'pending'
        });

        const otherPartyId = await getOtherPartyId(conversationId, userId);
        if (otherPartyId) {
            await Notification.create({
                userId: otherPartyId,
                type: 'transaction_initiated',
                title: 'New Order Request',
                titleAr: 'طلب جديد',
                data: { transactionId: transaction.id, conversationId },
            });
        }

        await Message.create({
            conversationId,
            senderId: userId,
            content: JSON.stringify({
                transactionId: transaction.id,
                productId: productId || null,
                productName: productName,
                productNameAr: productNameAr,
            }),
            messageType: 'transaction',
        });

        await Conversation.update(
            { lastMessageAt: new Date(), deletedByUser1: false, deletedByUser2: false },
            { where: { id: conversationId } }
        );

        const fullTransaction = await Transaction.findByPk(transaction.id, {
            include: [
                { model: User, as: 'initiator', attributes: ['id', 'fullName', 'avatarUrl'] },
                { model: Product, as: 'product', attributes: ['id', 'name', 'basePrice'] },
            ],
        });

        res.status(201).json({
            success: true,
            data: fullTransaction,
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Get user's transactions
 * GET /transactions
 */
export const getTransactions = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = req.user!.id;
        const { status, page = 1, limit = 20 } = req.query;

        const offset = (Number(page) - 1) * Number(limit);

        const whereClause: any = {};

        if (status && status !== 'all') {
            whereClause.status = status;
        }

        const userConversations = await Conversation.findAll({
            where: {
                [Op.or]: [
                    { user1Id: userId },
                    { user2Id: userId },
                ],
            },
            attributes: ['id'],
        });

        const conversationIds = userConversations.map(c => c.id);

        whereClause.conversationId = { [Op.in]: conversationIds };

        const { count, rows } = await Transaction.findAndCountAll({
            where: whereClause,
            include: [
                { model: User, as: 'initiator', attributes: ['id', 'fullName', 'avatarUrl'] },
                {
                    model: Product,
                    as: 'product',
                    attributes: ['id', 'name', 'basePrice'],
                    include: [
                        { model: Project, as: 'project', attributes: ['id', 'ownerId'] },
                    ],
                },
                {
                    model: Conversation,
                    as: 'conversation',
                    include: [
                        { model: User, as: 'user1', attributes: ['id', 'fullName', 'avatarUrl'] },
                        { model: User, as: 'user2', attributes: ['id', 'fullName', 'avatarUrl'] },
                    ],
                },
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
 * Get transaction by ID
 * GET /transactions/:id
 */
export const getTransactionById = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = req.user!.id;
        const { id } = req.params;

        const transaction = await Transaction.findByPk(id, {
            include: [
                { model: User, as: 'initiator', attributes: ['id', 'fullName', 'avatarUrl'] },
                {
                    model: Product,
                    as: 'product',
                    attributes: ['id', 'name', 'basePrice'],
                    include: [
                        { model: Project, as: 'project', attributes: ['id', 'ownerId'] },
                    ],
                },
                {
                    model: Conversation,
                    as: 'conversation',
                    include: [
                        { model: User, as: 'user1', attributes: ['id', 'fullName', 'avatarUrl'] },
                        { model: User, as: 'user2', attributes: ['id', 'fullName', 'avatarUrl'] },
                    ],
                },
            ],
        });

        if (!transaction) {
            return res.status(404).json({
                success: false,
                error: { code: 'NOT_FOUND', message: 'Transaction not found' },
            });
        }

        const userRole = await getUserRole(transaction.conversationId, userId);
        if (!userRole) {
            return res.status(403).json({
                success: false,
                error: { code: 'FORBIDDEN', message: 'You are not authorized to view this transaction' },
            });
        }

        res.json({
            success: true,
            data: transaction,
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Accept Order (Owner only)
 * PUT /transactions/:id/accept
 */
export const acceptOrder = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = req.user!.id;
        const { id } = req.params;

        const transaction = await Transaction.findByPk(id);

        if (!transaction) {
            return res.status(404).json({ success: false, error: { code: 'NOT_FOUND', message: 'Order not found' }});
        }

        if (transaction.status !== 'pending') {
            return res.status(400).json({ success: false, error: { code: 'INVALID_STATUS', message: 'Order is not pending' }});
        }

        const userRole = await getUserRole(transaction.conversationId, userId);
        if (userRole !== 'seller') {
            return res.status(403).json({ success: false, error: { code: 'FORBIDDEN', message: 'Only the project owner can accept the order' }});
        }

        transaction.status = 'preparing';
        transaction.preparingAt = new Date();
        await transaction.save();

        const customerId = await getOtherPartyId(transaction.conversationId, userId);
        if (customerId) {
            await Notification.create({
                userId: customerId,
                type: 'order_accepted',
                title: 'Order Accepted',
                titleAr: 'تم قبول الطلب',
                data: { transactionId: transaction.id, conversationId: transaction.conversationId },
            });
        }

        res.json({ success: true, data: transaction });
    } catch (error) {
        next(error);
    }
};

/**
 * Mark as Deliverable (Owner only)
 * PUT /transactions/:id/deliverable
 */
export const markDeliverable = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = req.user!.id;
        const { id } = req.params;

        const transaction = await Transaction.findByPk(id);

        if (!transaction) {
            return res.status(404).json({ success: false, error: { code: 'NOT_FOUND', message: 'Order not found' }});
        }

        if (transaction.status !== 'preparing') {
            return res.status(400).json({ success: false, error: { code: 'INVALID_STATUS', message: 'Order is not in preparing stage' }});
        }

        const userRole = await getUserRole(transaction.conversationId, userId);
        if (userRole !== 'seller') {
            return res.status(403).json({ success: false, error: { code: 'FORBIDDEN', message: 'Only the project owner can mark this as deliverable' }});
        }

        transaction.status = 'ready_to_deliver';
        transaction.readyToDeliverAt = new Date();
        await transaction.save();

        const customerId = await getOtherPartyId(transaction.conversationId, userId);
        if (customerId) {
            await Notification.create({
                userId: customerId,
                type: 'order_ready',
                title: 'Order Ready To Deliver',
                titleAr: 'الطلب جاهز للتسليم',
                data: { transactionId: transaction.id, conversationId: transaction.conversationId },
            });
        }

        res.json({ success: true, data: transaction });
    } catch (error) {
        next(error);
    }
};

/**
 * Receive Order (Customer only)
 * PUT /transactions/:id/receive
 */
export const receiveOrder = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = req.user!.id;
        const { id } = req.params;

        const transaction = await Transaction.findByPk(id);

        if (!transaction) {
            return res.status(404).json({ success: false, error: { code: 'NOT_FOUND', message: 'Order not found' }});
        }

        if (transaction.status !== 'ready_to_deliver') {
            return res.status(400).json({ success: false, error: { code: 'INVALID_STATUS', message: 'Order is not ready to deliver yet' }});
        }

        const userRole = await getUserRole(transaction.conversationId, userId);
        if (userRole !== 'customer') {
            return res.status(403).json({ success: false, error: { code: 'FORBIDDEN', message: 'Only the customer can receive the order' }});
        }

        transaction.status = 'delivered';
        transaction.deliveredAt = new Date();
        await transaction.save();

        const sellerId = await getOtherPartyId(transaction.conversationId, userId);
        if (sellerId) {
            await Notification.create({
                userId: sellerId,
                type: 'order_delivered',
                title: 'Order Delivered',
                titleAr: 'تم استلام الطلب',
                data: { transactionId: transaction.id, conversationId: transaction.conversationId },
            });
        }

        res.json({ success: true, data: transaction });
    } catch (error) {
        next(error);
    }
};

/**
 * Open dispute for transaction
 * POST /transactions/:id/dispute
 */
export const openDispute = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = req.user!.id;
        const { id } = req.params;
        const { reason, description } = req.body;

        if (!reason || !description) {
            return res.status(400).json({
                success: false,
                error: { code: 'MISSING_FIELDS', message: 'Reason and description are required' },
            });
        }

        const transaction = await Transaction.findByPk(id);

        if (!transaction) {
            return res.status(404).json({
                success: false,
                error: { code: 'NOT_FOUND', message: 'Order not found' },
            });
        }

        const userRole = await getUserRole(transaction.conversationId, userId);
        if (!userRole) {
            return res.status(403).json({
                success: false,
                error: { code: 'FORBIDDEN', message: 'You are not authorized to dispute this order' },
            });
        }

        transaction.status = 'disputed';
        await transaction.save();

        const ticket = await SupportTicket.create({
            userId,
            type: 'dispute',
            subject: reason,
            description,
            relatedId: transaction.id,
            relatedType: 'transaction',
        });

        const otherPartyId = await getOtherPartyId(transaction.conversationId, userId);
        if (otherPartyId) {
            await Notification.create({
                userId: otherPartyId,
                type: 'transaction_disputed',
                title: 'Order Disputed',
                titleAr: 'نزاع على الطلب',
                data: { transactionId: transaction.id, ticketId: ticket.id },
            });
        }

        res.status(201).json({
            success: true,
            message: 'Dispute opened successfully',
            data: {
                transaction,
                ticket,
            },
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Cancel transaction
 * PUT /transactions/:id/cancel
 */
export const cancelTransaction = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = req.user!.id;
        const { id } = req.params;

        const transaction = await Transaction.findByPk(id);

        if (!transaction) {
            return res.status(404).json({
                success: false,
                error: { code: 'NOT_FOUND', message: 'Order not found' },
            });
        }

        if (transaction.status !== 'pending') {
            return res.status(400).json({
                success: false,
                error: { code: 'INVALID_STATUS', message: 'Only pending orders can be cancelled' },
            });
        }

        const userRole = await getUserRole(transaction.conversationId, userId);
        if (!userRole) {
            return res.status(403).json({
                success: false,
                error: { code: 'FORBIDDEN', message: 'Not authorized' },
            });
        }

        transaction.status = 'cancelled';
        await transaction.save();

        const otherPartyId = await getOtherPartyId(transaction.conversationId, userId);
        if (otherPartyId) {
            await Notification.create({
                userId: otherPartyId,
                type: 'transaction_cancelled',
                title: 'Order Cancelled',
                titleAr: 'إلغاء الطلب',
                data: { transactionId: transaction.id },
            });
        }

        res.json({
            success: true,
            message: 'Order cancelled successfully',
            data: transaction,
        });
    } catch (error) {
        next(error);
    }
};
