import { Request, Response, NextFunction } from 'express';
import { Op } from 'sequelize';
import Conversation from '../models/Conversation';
import Message from '../models/Message';
import Project from '../models/Project';
import User from '../models/User';
import { sendSuccess, sendError, sendPaginated } from '../utils/helpers';
import { ERROR_CODES } from '../config/constants';
import { NotificationTemplates } from '../services/notification.service';
import logger from '../utils/logger';

/**
 * Get user's conversations with last message
 */
export const getConversations = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = req.user!.id;

        // Get user's project if they are a project owner
        const userProject = await Project.findOne({ where: { ownerId: userId } });

        // Find conversations where user is customer OR project owner
        const whereClause: any = { customerId: userId };
        if (userProject) {
            whereClause[Op.or] = [
                { customerId: userId },
                { projectId: userProject.id },
            ];
            delete whereClause.customerId;
        }

        const conversations = await Conversation.findAll({
            where: whereClause,
            include: [
                {
                    model: User,
                    as: 'customer',
                    attributes: ['id', 'fullName', 'avatarUrl'],
                },
                {
                    model: Project,
                    as: 'project',
                    attributes: ['id', 'name', 'nameAr', 'logoUrl', 'ownerId'],
                    include: [
                        {
                            model: User,
                            as: 'owner',
                            attributes: ['id', 'fullName', 'avatarUrl'],
                        },
                    ],
                },
            ],
            order: [['lastMessageAt', 'DESC']],
        });

        // Get last message and unread count for each conversation
        const conversationsWithMessages = await Promise.all(
            conversations.map(async (conv) => {
                const lastMessage = await Message.findOne({
                    where: { conversationId: conv.id },
                    order: [['createdAt', 'DESC']],
                    include: [
                        {
                            model: User,
                            as: 'sender',
                            attributes: ['id', 'fullName'],
                        },
                    ],
                });

                const unreadCount = await Message.count({
                    where: {
                        conversationId: conv.id,
                        senderId: { [Op.ne]: userId },
                        isRead: false,
                    },
                });

                return {
                    id: conv.id,
                    customerId: conv.customerId,
                    projectId: conv.projectId,
                    lastMessageAt: conv.lastMessageAt,
                    createdAt: conv.createdAt,
                    customer: conv.customer,
                    project: conv.project,
                    lastMessage: lastMessage
                        ? {
                            id: lastMessage.id,
                            content: lastMessage.content,
                            messageType: lastMessage.messageType,
                            senderId: lastMessage.senderId,
                            senderName: lastMessage.sender?.fullName,
                            createdAt: lastMessage.createdAt,
                        }
                        : null,
                    unreadCount,
                };
            })
        );

        return sendSuccess(res, conversationsWithMessages);
    } catch (error) {
        next(error);
    }
};

/**
 * Get single conversation with messages
 */
export const getConversation = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = req.user!.id;
        const { id } = req.params;
        const page = parseInt(req.query.page as string) || 1;
        const limit = parseInt(req.query.limit as string) || 50;
        const offset = (page - 1) * limit;

        const conversation = await Conversation.findByPk(id, {
            include: [
                {
                    model: User,
                    as: 'customer',
                    attributes: ['id', 'fullName', 'avatarUrl'],
                },
                {
                    model: Project,
                    as: 'project',
                    attributes: ['id', 'name', 'nameAr', 'logoUrl', 'ownerId'],
                    include: [
                        {
                            model: User,
                            as: 'owner',
                            attributes: ['id', 'fullName', 'avatarUrl'],
                        },
                    ],
                },
            ],
        });

        if (!conversation) {
            return sendError(res, ERROR_CODES.NOT_FOUND, 'Conversation not found', 404);
        }

        // Check access
        const isCustomer = conversation.customerId === userId;
        const isProjectOwner = conversation.project?.ownerId === userId;

        if (!isCustomer && !isProjectOwner) {
            return sendError(res, ERROR_CODES.AUTHORIZATION_ERROR, 'Access denied', 403);
        }

        // Get messages with pagination (newest first for chat)
        const { count, rows: messages } = await Message.findAndCountAll({
            where: { conversationId: id },
            include: [
                {
                    model: User,
                    as: 'sender',
                    attributes: ['id', 'fullName', 'avatarUrl'],
                },
            ],
            order: [['createdAt', 'DESC']],
            limit,
            offset,
        });

        return sendPaginated(
            res,
            {
                conversation: {
                    id: conversation.id,
                    customerId: conversation.customerId,
                    projectId: conversation.projectId,
                    customer: conversation.customer,
                    project: conversation.project,
                },
                messages: messages.reverse(), // Reverse to show oldest first in UI
            },
            { page, limit, total: count }
        );
    } catch (error) {
        next(error);
    }
};

/**
 * Start a new conversation with a project
 */
export const createConversation = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = req.user!.id;
        const { projectId } = req.body;

        if (!projectId) {
            return sendError(res, ERROR_CODES.VALIDATION_ERROR, 'Project ID is required', 400);
        }

        // Check if project exists
        const project = await Project.findByPk(projectId);
        if (!project) {
            return sendError(res, ERROR_CODES.NOT_FOUND, 'Project not found', 404);
        }

        // Can't message your own project
        if (project.ownerId === userId) {
            return sendError(res, ERROR_CODES.VALIDATION_ERROR, 'Cannot message your own project', 400);
        }

        // Find or create conversation
        const [conversation, created] = await Conversation.findOrCreate({
            where: {
                customerId: userId,
                projectId,
            },
            defaults: {
                customerId: userId,
                projectId,
            },
        });

        // Reload with associations
        await conversation.reload({
            include: [
                {
                    model: User,
                    as: 'customer',
                    attributes: ['id', 'fullName', 'avatarUrl'],
                },
                {
                    model: Project,
                    as: 'project',
                    attributes: ['id', 'name', 'nameAr', 'logoUrl', 'ownerId'],
                },
            ],
        });

        return sendSuccess(res, conversation, created ? 'Conversation created' : 'Conversation found', created ? 201 : 200);
    } catch (error) {
        next(error);
    }
};

/**
 * Send a message (REST fallback for when WebSocket is unavailable)
 */
export const sendMessage = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = req.user!.id;
        const { id } = req.params;
        const { content, messageType = 'text' } = req.body;

        if (!content || !content.trim()) {
            return sendError(res, ERROR_CODES.VALIDATION_ERROR, 'Message content is required', 400);
        }

        const conversation = await Conversation.findByPk(id, {
            include: [{ model: Project, as: 'project' }],
        });

        if (!conversation) {
            return sendError(res, ERROR_CODES.NOT_FOUND, 'Conversation not found', 404);
        }

        // Check access
        const isCustomer = conversation.customerId === userId;
        const isProjectOwner = conversation.project?.ownerId === userId;

        if (!isCustomer && !isProjectOwner) {
            return sendError(res, ERROR_CODES.AUTHORIZATION_ERROR, 'Access denied', 403);
        }

        // Create message
        const message = await Message.create({
            conversationId: parseInt(id),
            senderId: userId,
            content: content.trim(),
            messageType,
        });

        // Update conversation
        conversation.lastMessageAt = new Date();
        await conversation.save();

        // Reload with sender
        await message.reload({
            include: [
                {
                    model: User,
                    as: 'sender',
                    attributes: ['id', 'fullName', 'avatarUrl'],
                },
            ],
        });

        // Send notification to the other party
        const otherUserId = isCustomer ? conversation.project?.ownerId : conversation.customerId;
        if (otherUserId) {
            const senderName = req.user!.fullName || 'Someone';
            logger.info(`Sending notification to user ${otherUserId} from ${senderName}`);
            try {
                await NotificationTemplates.newMessage(
                    otherUserId,
                    senderName,
                    parseInt(id),
                    content.trim()
                );
                logger.info(`Notification sent successfully to user ${otherUserId}`);
            } catch (notifError) {
                logger.error('Failed to send notification:', notifError);
            }
        }

        return sendSuccess(res, message, 'Message sent', 201);
    } catch (error) {
        next(error);
    }
};

/**
 * Mark messages as read
 */
export const markAsRead = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = req.user!.id;
        const { id } = req.params;

        const conversation = await Conversation.findByPk(id, {
            include: [{ model: Project, as: 'project' }],
        });

        if (!conversation) {
            return sendError(res, ERROR_CODES.NOT_FOUND, 'Conversation not found', 404);
        }

        // Check access
        const isCustomer = conversation.customerId === userId;
        const isProjectOwner = conversation.project?.ownerId === userId;

        if (!isCustomer && !isProjectOwner) {
            return sendError(res, ERROR_CODES.AUTHORIZATION_ERROR, 'Access denied', 403);
        }

        // Mark all messages from the other party as read
        const [updated] = await Message.update(
            { isRead: true },
            {
                where: {
                    conversationId: id,
                    senderId: { [Op.ne]: userId },
                    isRead: false,
                },
            }
        );

        return sendSuccess(res, { markedAsRead: updated });
    } catch (error) {
        next(error);
    }
};
