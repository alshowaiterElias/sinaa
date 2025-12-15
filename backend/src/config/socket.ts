import { Server as HttpServer } from 'http';
import { Server, Socket } from 'socket.io';
import { verifyAccessToken } from '../utils/jwt';
import { User, Conversation, Message, Project } from '../models';
import logger from '../utils/logger';
import { NotificationTemplates, initializeNotificationService } from '../services/notification.service';

interface AuthenticatedSocket extends Socket {
    userId?: number;
    user?: User;
}

interface MessageData {
    conversationId: number;
    content: string;
    messageType?: 'text' | 'image';
}

interface TypingData {
    conversationId: number;
    isTyping: boolean;
}

// Track online users: Map<userId, Set<socketId>>
const onlineUsers = new Map<number, Set<string>>();

/**
 * Initialize Socket.io server
 */
export function initializeSocket(httpServer: HttpServer): Server {
    const io = new Server(httpServer, {
        cors: {
            origin: process.env.CORS_ORIGIN?.split(',') || '*',
            credentials: true,
        },
        pingTimeout: 60000,
        pingInterval: 25000,
    });

    // Authentication middleware
    io.use(async (socket: AuthenticatedSocket, next) => {
        try {
            const token = socket.handshake.auth.token || socket.handshake.query.token;

            if (!token) {
                return next(new Error('Authentication required'));
            }

            const payload = verifyAccessToken(token as string);
            if (!payload) {
                return next(new Error('Invalid token'));
            }

            const user = await User.findByPk(payload.userId);
            if (!user || !user.isActive || user.isBanned) {
                return next(new Error('User not found or inactive'));
            }

            socket.userId = user.id;
            socket.user = user;
            next();
        } catch (error) {
            logger.error('Socket authentication error:', error);
            next(new Error('Authentication failed'));
        }
    });

    // Connection handler
    io.on('connection', (socket: AuthenticatedSocket) => {
        const userId = socket.userId!;
        logger.info(`Socket connected: ${socket.id} (User: ${userId})`);

        // Track online status
        if (!onlineUsers.has(userId)) {
            onlineUsers.set(userId, new Set());
        }
        onlineUsers.get(userId)!.add(socket.id);

        // Broadcast online status
        socket.broadcast.emit('userOnline', { userId });

        // Join user's personal room for direct messages
        socket.join(`user:${userId}`);

        // Join conversation room
        socket.on('joinConversation', async (conversationId: number) => {
            try {
                // Verify user is part of this conversation
                const conversation = await Conversation.findByPk(conversationId, {
                    include: [{ model: Project, as: 'project' }],
                });

                if (!conversation) {
                    socket.emit('error', { message: 'Conversation not found' });
                    return;
                }

                // Check if user is customer or project owner
                const project = conversation.project;
                const isCustomer = conversation.customerId === userId;
                const isProjectOwner = project?.ownerId === userId;

                if (!isCustomer && !isProjectOwner) {
                    socket.emit('error', { message: 'Access denied' });
                    return;
                }

                socket.join(`conversation:${conversationId}`);
                logger.info(`User ${userId} joined conversation ${conversationId}`);
            } catch (error) {
                logger.error('Join conversation error:', error);
                socket.emit('error', { message: 'Failed to join conversation' });
            }
        });

        // Leave conversation room
        socket.on('leaveConversation', (conversationId: number) => {
            socket.leave(`conversation:${conversationId}`);
            logger.info(`User ${userId} left conversation ${conversationId}`);
        });

        // Send message
        socket.on('sendMessage', async (data: MessageData) => {
            try {
                const { conversationId, content, messageType = 'text' } = data;

                if (!content || !content.trim()) {
                    socket.emit('error', { message: 'Message content required' });
                    return;
                }

                // Verify conversation access
                const conversation = await Conversation.findByPk(conversationId, {
                    include: [{ model: Project, as: 'project' }],
                });

                if (!conversation) {
                    socket.emit('error', { message: 'Conversation not found' });
                    return;
                }

                const project = conversation.project;
                const isCustomer = conversation.customerId === userId;
                const isProjectOwner = project?.ownerId === userId;

                if (!isCustomer && !isProjectOwner) {
                    socket.emit('error', { message: 'Access denied' });
                    return;
                }

                // Create message
                const message = await Message.create({
                    conversationId,
                    senderId: userId,
                    content: content.trim(),
                    messageType,
                });

                // Update conversation last message time
                conversation.lastMessageAt = new Date();
                await conversation.save();

                // Load sender info
                await message.reload({
                    include: [{ model: User, as: 'sender', attributes: ['id', 'fullName', 'avatarUrl'] }],
                });

                // Broadcast to conversation room
                io.to(`conversation:${conversationId}`).emit('newMessage', {
                    message: {
                        id: message.id,
                        conversationId: message.conversationId,
                        senderId: message.senderId,
                        content: message.content,
                        messageType: message.messageType,
                        isRead: message.isRead,
                        createdAt: message.createdAt,
                        sender: message.sender,
                    },
                });

                // Notify the other party if not in room
                const otherUserId = isCustomer ? project?.ownerId : conversation.customerId;
                if (otherUserId) {
                    io.to(`user:${otherUserId}`).emit('conversationUpdated', {
                        conversationId,
                        lastMessage: message.content,
                        lastMessageAt: message.createdAt,
                    });

                    // Send notification to the other party
                    const senderName = socket.user?.fullName || 'Someone';
                    NotificationTemplates.newMessage(
                        otherUserId,
                        senderName,
                        conversationId,
                        message.content
                    );
                }

                logger.info(`Message sent in conversation ${conversationId} by user ${userId}`);
            } catch (error) {
                logger.error('Send message error:', error);
                socket.emit('error', { message: 'Failed to send message' });
            }
        });

        // Typing indicator
        socket.on('typing', (data: TypingData) => {
            const { conversationId, isTyping } = data;
            socket.to(`conversation:${conversationId}`).emit('userTyping', {
                conversationId,
                userId,
                isTyping,
            });
        });

        // Mark messages as read
        socket.on('markRead', async (conversationId: number) => {
            try {
                await Message.update(
                    { isRead: true },
                    {
                        where: {
                            conversationId,
                            senderId: { [require('sequelize').Op.ne]: userId },
                            isRead: false,
                        },
                    }
                );

                // Notify sender that messages were read
                socket.to(`conversation:${conversationId}`).emit('messagesRead', {
                    conversationId,
                    readBy: userId,
                });
            } catch (error) {
                logger.error('Mark read error:', error);
            }
        });

        // Disconnection
        socket.on('disconnect', () => {
            logger.info(`Socket disconnected: ${socket.id} (User: ${userId})`);

            // Remove from online tracking
            const userSockets = onlineUsers.get(userId);
            if (userSockets) {
                userSockets.delete(socket.id);
                if (userSockets.size === 0) {
                    onlineUsers.delete(userId);
                    // Broadcast offline status
                    socket.broadcast.emit('userOffline', { userId });
                }
            }
        });
    });

    // Initialize notification service with Socket.io instance
    initializeNotificationService(io);

    logger.info('Socket.io server initialized');
    return io;
}

/**
 * Check if a user is online
 */
export function isUserOnline(userId: number): boolean {
    return onlineUsers.has(userId) && onlineUsers.get(userId)!.size > 0;
}

/**
 * Get all online user IDs
 */
export function getOnlineUsers(): number[] {
    return Array.from(onlineUsers.keys());
}
