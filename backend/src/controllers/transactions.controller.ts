import { Request, Response, NextFunction } from 'express';
import { Op } from 'sequelize';
import { Transaction, User, Conversation, Product, SupportTicket, SystemSetting, Notification } from '../models';
import Project from '../models/Project';
import Message from '../models/Message';

// Helper to calculate auto-confirm date
async function getAutoConfirmDate(): Promise<Date> {
    const days = await SystemSetting.getAutoConfirmDays();
    const date = new Date();
    date.setDate(date.getDate() + days);
    return date;
}

// Helper to get the other party in a conversation
async function getOtherPartyId(conversationId: number, currentUserId: number): Promise<number | null> {
    const conversation = await Conversation.findByPk(conversationId);
    if (!conversation) return null;

    if (conversation.customerId === currentUserId) {
        // Current user is customer, get seller (project owner)
        const project = await Project.findByPk(conversation.projectId);
        return project?.ownerId ?? null;
    } else {
        // Current user is seller, return customer
        return conversation.customerId;
    }
}

// Helper to determine if user is customer or seller in conversation
async function getUserRole(conversationId: number, userId: number): Promise<'customer' | 'seller' | null> {
    const conversation = await Conversation.findByPk(conversationId);
    if (!conversation) return null;

    if (conversation.customerId === userId) {
        return 'customer';
    }

    const project = await Project.findByPk(conversation.projectId);
    if (project?.ownerId === userId) {
        return 'seller';
    }

    return null;
}

/**
 * Initiate a new transaction (rating request)
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

        // Verify conversation exists and user is part of it
        const conversation = await Conversation.findByPk(conversationId);
        if (!conversation) {
            return res.status(404).json({
                success: false,
                error: { code: 'NOT_FOUND', message: 'Conversation not found' },
            });
        }

        // Check if user is part of the conversation
        const userRole = await getUserRole(conversationId, userId);
        if (!userRole) {
            return res.status(403).json({
                success: false,
                error: { code: 'FORBIDDEN', message: 'You are not part of this conversation' },
            });
        }

        // Check for existing pending transaction in this conversation
        const existingPendingTransaction = await Transaction.findOne({
            where: {
                conversationId,
                status: 'pending',
            },
        });

        if (existingPendingTransaction) {
            return res.status(400).json({
                success: false,
                error: { code: 'ALREADY_EXISTS', message: 'A pending transaction already exists for this conversation' },
            });
        }

        // Check for existing transaction for this specific product (pending or confirmed)
        if (productId) {
            const existingProductTransaction = await Transaction.findOne({
                where: {
                    productId,
                    status: ['pending', 'confirmed'],
                },
            });

            if (existingProductTransaction) {
                return res.status(400).json({
                    success: false,
                    error: { code: 'PRODUCT_ALREADY_RATED', message: 'A transaction already exists for this product' },
                });
            }
        }

        // Verify product if provided
        if (productId) {
            const product = await Product.findByPk(productId);
            if (!product) {
                return res.status(404).json({
                    success: false,
                    error: { code: 'NOT_FOUND', message: 'Product not found' },
                });
            }
        }

        // Calculate auto-confirm date
        const autoConfirmAt = await getAutoConfirmDate();

        // Determine which side to auto-confirm based on who initiated
        const isCustomerInitiator = userRole === 'customer';
        const isSellerInitiator = userRole === 'seller';

        // Create transaction with initiator's side auto-confirmed
        const transaction = await Transaction.create({
            conversationId,
            productId: productId || null,
            initiatedBy: userId,
            autoConfirmAt,
            customerConfirmed: isCustomerInitiator,
            sellerConfirmed: isSellerInitiator,
            customerConfirmedAt: isCustomerInitiator ? new Date() : null,
            sellerConfirmedAt: isSellerInitiator ? new Date() : null,
        });

        // Notify the other party
        const otherPartyId = await getOtherPartyId(conversationId, userId);
        if (otherPartyId) {
            await Notification.create({
                userId: otherPartyId,
                type: 'transaction_initiated',
                title: 'New Rating Request',
                titleAr: 'طلب تقييم جديد',
                data: { transactionId: transaction.id },
            });
        }

        // Create a transaction message in the chat
        await Message.create({
            conversationId,
            senderId: userId,
            content: JSON.stringify({
                transactionId: transaction.id,
                productId: productId || null,
            }),
            messageType: 'transaction',
        });

        // Update conversation's lastMessageAt
        await Conversation.update(
            { lastMessageAt: new Date() },
            { where: { id: conversationId } }
        );

        // Fetch with associations
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

        // Build where clause - get transactions where user is initiator or other party
        const whereClause: any = {};

        if (status && status !== 'all') {
            whereClause.status = status;
        }

        // Get conversations where user is involved
        const userConversations = await Conversation.findAll({
            where: {
                [Op.or]: [
                    { customerId: userId },
                ],
            },
            attributes: ['id'],
        });

        // Also get conversations for projects user owns
        const userProjects = await Project.findAll({
            where: { ownerId: userId },
            attributes: ['id'],
        });

        const projectConversations = await Conversation.findAll({
            where: {
                projectId: { [Op.in]: userProjects.map(p => p.id) },
            },
            attributes: ['id'],
        });

        const conversationIds = [
            ...userConversations.map(c => c.id),
            ...projectConversations.map(c => c.id),
        ];

        whereClause.conversationId = { [Op.in]: conversationIds };

        const { count, rows } = await Transaction.findAndCountAll({
            where: whereClause,
            include: [
                { model: User, as: 'initiator', attributes: ['id', 'fullName', 'avatarUrl'] },
                { model: Product, as: 'product', attributes: ['id', 'name', 'basePrice'] },
                {
                    model: Conversation,
                    as: 'conversation',
                    include: [
                        { model: User, as: 'customer', attributes: ['id', 'fullName', 'avatarUrl'] },
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
                { model: Product, as: 'product', attributes: ['id', 'name', 'basePrice'] },
                {
                    model: Conversation,
                    as: 'conversation',
                    include: [
                        { model: User, as: 'customer', attributes: ['id', 'fullName', 'avatarUrl'] },
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

        // Verify user is part of the transaction
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
 * Confirm transaction
 * PUT /transactions/:id/confirm
 */
export const confirmTransaction = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = req.user!.id;
        const { id } = req.params;

        const transaction = await Transaction.findByPk(id);

        if (!transaction) {
            return res.status(404).json({
                success: false,
                error: { code: 'NOT_FOUND', message: 'Transaction not found' },
            });
        }

        if (transaction.status !== 'pending') {
            return res.status(400).json({
                success: false,
                error: { code: 'INVALID_STATUS', message: 'Transaction is not pending' },
            });
        }

        // Get user role in conversation
        const userRole = await getUserRole(transaction.conversationId, userId);
        if (!userRole) {
            return res.status(403).json({
                success: false,
                error: { code: 'FORBIDDEN', message: 'You are not authorized to confirm this transaction' },
            });
        }

        const now = new Date();

        // Update confirmation based on role
        if (userRole === 'customer') {
            if (transaction.customerConfirmed) {
                return res.status(400).json({
                    success: false,
                    error: { code: 'ALREADY_CONFIRMED', message: 'You have already confirmed this transaction' },
                });
            }
            transaction.customerConfirmed = true;
            transaction.customerConfirmedAt = now;
        } else {
            if (transaction.sellerConfirmed) {
                return res.status(400).json({
                    success: false,
                    error: { code: 'ALREADY_CONFIRMED', message: 'You have already confirmed this transaction' },
                });
            }
            transaction.sellerConfirmed = true;
            transaction.sellerConfirmedAt = now;
        }

        // Check if both parties have confirmed
        if (transaction.customerConfirmed && transaction.sellerConfirmed) {
            transaction.status = 'confirmed';
        }

        await transaction.save();

        // Notify the other party
        const otherPartyId = await getOtherPartyId(transaction.conversationId, userId);
        if (otherPartyId) {
            await Notification.create({
                userId: otherPartyId,
                type: 'transaction_confirmed',
                title: 'Rating Confirmed',
                titleAr: 'تأكيد التقييم',
                data: { transactionId: transaction.id },
            });
        }

        // Fetch with associations
        const fullTransaction = await Transaction.findByPk(transaction.id, {
            include: [
                { model: User, as: 'initiator', attributes: ['id', 'fullName', 'avatarUrl'] },
                { model: Product, as: 'product', attributes: ['id', 'name', 'basePrice'] },
            ],
        });

        res.json({
            success: true,
            data: fullTransaction,
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Deny transaction (still allows rating after waiting period)
 * PUT /transactions/:id/deny
 */
export const denyTransaction = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = req.user!.id;
        const { id } = req.params;

        const transaction = await Transaction.findByPk(id);

        if (!transaction) {
            return res.status(404).json({
                success: false,
                error: { code: 'NOT_FOUND', message: 'Transaction not found' },
            });
        }

        if (transaction.status !== 'pending') {
            return res.status(400).json({
                success: false,
                error: { code: 'INVALID_STATUS', message: 'Transaction is not pending' },
            });
        }

        // Verify user is part of the conversation but NOT the initiator
        const userRole = await getUserRole(transaction.conversationId, userId);
        if (!userRole) {
            return res.status(403).json({
                success: false,
                error: { code: 'FORBIDDEN', message: 'You are not authorized to deny this transaction' },
            });
        }

        if (transaction.initiatedBy === userId) {
            return res.status(400).json({
                success: false,
                error: { code: 'CANNOT_DENY_OWN', message: 'You cannot deny your own transaction' },
            });
        }

        // Denying just means they don't confirm - the auto-confirm will happen after waiting period
        // Notify the initiator that their request was denied but will auto-confirm
        await Notification.create({
            userId: transaction.initiatedBy,
            type: 'transaction_denied',
            title: 'Rating Request Denied',
            titleAr: 'رفض طلب التقييم',
            data: { transactionId: transaction.id, autoConfirmAt: transaction.autoConfirmAt },
        });

        res.json({
            success: true,
            message: 'Transaction denial recorded. Rating will be available after waiting period.',
            data: {
                autoConfirmAt: transaction.autoConfirmAt,
            },
        });
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
                error: { code: 'NOT_FOUND', message: 'Transaction not found' },
            });
        }

        // Verify user is part of the conversation
        const userRole = await getUserRole(transaction.conversationId, userId);
        if (!userRole) {
            return res.status(403).json({
                success: false,
                error: { code: 'FORBIDDEN', message: 'You are not authorized to dispute this transaction' },
            });
        }

        // Update transaction status
        transaction.status = 'disputed';
        await transaction.save();

        // Create support ticket for dispute
        const ticket = await SupportTicket.create({
            userId,
            type: 'dispute',
            subject: reason,
            description,
            relatedId: transaction.id,
            relatedType: 'transaction',
        });

        // Notify admin and other party
        const otherPartyId = await getOtherPartyId(transaction.conversationId, userId);
        if (otherPartyId) {
            await Notification.create({
                userId: otherPartyId,
                type: 'transaction_disputed',
                title: 'Rating Dispute Opened',
                titleAr: 'نزاع على التقييم',
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
 * Cancel transaction (by initiator or recipient, only if pending)
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
                error: { code: 'NOT_FOUND', message: 'Transaction not found' },
            });
        }

        if (transaction.status !== 'pending') {
            return res.status(400).json({
                success: false,
                error: { code: 'INVALID_STATUS', message: 'Only pending transactions can be cancelled' },
            });
        }

        // Only the initiator can cancel
        if (transaction.initiatedBy !== userId) {
            return res.status(403).json({
                success: false,
                error: { code: 'FORBIDDEN', message: 'Only the initiator can cancel a transaction' },
            });
        }

        transaction.status = 'cancelled';
        await transaction.save();

        // Notify the other party
        const otherPartyId = await getOtherPartyId(transaction.conversationId, userId);
        if (otherPartyId) {
            await Notification.create({
                userId: otherPartyId,
                type: 'transaction_cancelled',
                title: 'Rating Request Cancelled',
                titleAr: 'إلغاء طلب التقييم',
                data: { transactionId: transaction.id },
            });
        }

        res.json({
            success: true,
            message: 'Transaction cancelled successfully',
        });
    } catch (error) {
        next(error);
    }
};
