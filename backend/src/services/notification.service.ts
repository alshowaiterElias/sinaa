import { Server } from 'socket.io';
import Notification, { NotificationType, NotificationData, NotificationCreationAttributes } from '../models/Notification';
import logger from '../utils/logger';

// Store Socket.io instance for real-time notifications
let io: Server | null = null;

/**
 * Initialize the notification service with Socket.io
 */
export function initializeNotificationService(socketIo: Server): void {
    io = socketIo;
    logger.info('Notification service initialized');
}

/**
 * Create and send a notification
 */
export async function createNotification(params: {
    userId: number;
    type: NotificationType;
    title: string;
    titleAr: string;
    body?: string;
    bodyAr?: string;
    data?: NotificationData;
}): Promise<Notification> {
    logger.info(`Creating notification for user ${params.userId}, type: ${params.type}`);
    logger.info(`Notification params: ${JSON.stringify(params)}`);

    try {
        const notification = await Notification.create({
            userId: params.userId,
            type: params.type,
            title: params.title,
            titleAr: params.titleAr,
            body: params.body || null,
            bodyAr: params.bodyAr || null,
            data: params.data || null,
        });

        logger.info(`Notification created with ID: ${notification.id}`);

        // Emit real-time notification
        if (io) {
            io.to(`user:${params.userId}`).emit('notification', {
                id: notification.id,
                type: notification.type,
                title: notification.title,
                titleAr: notification.titleAr,
                body: notification.body,
                bodyAr: notification.bodyAr,
                data: notification.data,
                isRead: notification.isRead,
                createdAt: notification.createdAt,
            });
            logger.info(`Real-time notification emitted to user:${params.userId}`);
        } else {
            logger.warn('Socket.io not initialized, real-time notification not sent');
        }

        return notification;
    } catch (error) {
        logger.error('Error creating notification:', error);
        throw error;
    }
}

/**
 * Notification templates for different events
 */
export const NotificationTemplates = {
    /**
     * New message notification
     */
    newMessage(userId: number, senderName: string, conversationId: number, messagePreview: string): Promise<Notification> {
        return createNotification({
            userId,
            type: 'message',
            title: `New message from ${senderName}`,
            titleAr: `رسالة جديدة من ${senderName}`,
            body: messagePreview.length > 100 ? messagePreview.substring(0, 100) + '...' : messagePreview,
            bodyAr: messagePreview.length > 100 ? messagePreview.substring(0, 100) + '...' : messagePreview,
            data: { conversationId, senderName },
        });
    },

    /**
     * New inquiry notification (for project owners)
     */
    newInquiry(userId: number, customerName: string, projectName: string, conversationId: number): Promise<Notification> {
        return createNotification({
            userId,
            type: 'inquiry',
            title: `New inquiry from ${customerName}`,
            titleAr: `استفسار جديد من ${customerName}`,
            body: `You have received a new inquiry about ${projectName}`,
            bodyAr: `لديك استفسار جديد حول ${projectName}`,
            data: { conversationId, senderName: customerName },
        });
    },

    /**
     * Transaction initiated notification
     */
    transactionInitiated(userId: number, transactionId: number, amount: number): Promise<Notification> {
        return createNotification({
            userId,
            type: 'transaction',
            title: 'New Transaction Initiated',
            titleAr: 'معاملة جديدة',
            body: `A new transaction for ${amount} SAR has been initiated`,
            bodyAr: `تم بدء معاملة جديدة بقيمة ${amount} ريال`,
            data: { transactionId },
        });
    },

    /**
     * Transaction confirmed notification
     */
    transactionConfirmed(userId: number, transactionId: number, amount: number): Promise<Notification> {
        return createNotification({
            userId,
            type: 'transaction',
            title: 'Transaction Confirmed',
            titleAr: 'تم تأكيد المعاملة',
            body: `Transaction of ${amount} SAR has been confirmed`,
            bodyAr: `تم تأكيد المعاملة بقيمة ${amount} ريال`,
            data: { transactionId },
        });
    },

    /**
     * Review received notification
     */
    reviewReceived(userId: number, reviewerId: string, rating: number, projectId: number): Promise<Notification> {
        return createNotification({
            userId,
            type: 'review',
            title: 'New Review Received',
            titleAr: 'تقييم جديد',
            body: `${reviewerId} gave you a ${rating}-star rating`,
            bodyAr: `قام ${reviewerId} بتقييمك ${rating} نجوم`,
            data: { projectId, rating },
        });
    },

    /**
     * Project approved notification
     */
    projectApproved(userId: number, projectId: number, projectName: string): Promise<Notification> {
        return createNotification({
            userId,
            type: 'project_approval',
            title: 'Project Approved!',
            titleAr: 'تمت الموافقة على المشروع!',
            body: `Your project "${projectName}" has been approved`,
            bodyAr: `تمت الموافقة على مشروعك "${projectName}"`,
            data: { projectId },
        });
    },

    /**
     * Project rejected notification
     */
    projectRejected(userId: number, projectId: number, projectName: string, reason?: string): Promise<Notification> {
        return createNotification({
            userId,
            type: 'project_approval',
            title: 'Project Needs Revision',
            titleAr: 'المشروع يحتاج تعديل',
            body: reason || `Your project "${projectName}" needs some changes`,
            bodyAr: reason || `مشروعك "${projectName}" يحتاج بعض التعديلات`,
            data: { projectId },
        });
    },

    /**
     * Product approved notification
     */
    productApproved(userId: number, productId: number, productName: string): Promise<Notification> {
        return createNotification({
            userId,
            type: 'product_approval',
            title: 'Product Approved!',
            titleAr: 'تمت الموافقة على المنتج!',
            body: `Your product "${productName}" has been approved`,
            bodyAr: `تمت الموافقة على منتجك "${productName}"`,
            data: { productId },
        });
    },

    /**
     * Product rejected notification
     */
    productRejected(userId: number, productId: number, productName: string, reason?: string): Promise<Notification> {
        return createNotification({
            userId,
            type: 'product_approval',
            title: 'Product Needs Revision',
            titleAr: 'المنتج يحتاج تعديل',
            body: reason || `Your product "${productName}" needs some changes`,
            bodyAr: reason || `منتجك "${productName}" يحتاج بعض التعديلات`,
            data: { productId },
        });
    },

    /**
     * Product disabled notification
     */
    productDisabled(userId: number, productId: number, productName: string, reason: string): Promise<Notification> {
        return createNotification({
            userId,
            type: 'product_approval',
            title: 'Product Disabled',
            titleAr: 'تم تعطيل المنتج',
            body: `Your product "${productName}" has been disabled: ${reason}`,
            bodyAr: `تم تعطيل منتجك "${productName}": ${reason}`,
            data: { productId },
        });
    },

    /**
     * Product enabled notification
     */
    productEnabled(userId: number, productId: number, productName: string): Promise<Notification> {
        return createNotification({
            userId,
            type: 'product_approval',
            title: 'Product Enabled',
            titleAr: 'تم تفعيل المنتج',
            body: `Your product "${productName}" has been re-enabled`,
            bodyAr: `تم إعادة تفعيل منتجك "${productName}"`,
            data: { productId },
        });
    },

    /**
     * Project disabled notification
     */
    projectDisabled(userId: number, projectId: number, projectName: string, reason: string): Promise<Notification> {
        return createNotification({
            userId,
            type: 'project_approval',
            title: 'Project Disabled',
            titleAr: 'تم تعطيل المشروع',
            body: `Your project "${projectName}" has been disabled: ${reason}`,
            bodyAr: `تم تعطيل مشروعك "${projectName}": ${reason}`,
            data: { projectId },
        });
    },

    /**
     * Project enabled notification
     */
    projectEnabled(userId: number, projectId: number, projectName: string): Promise<Notification> {
        return createNotification({
            userId,
            type: 'project_approval',
            title: 'Project Enabled',
            titleAr: 'تم تفعيل المشروع',
            body: `Your project "${projectName}" has been re-enabled`,
            bodyAr: `تم إعادة تفعيل مشروعك "${projectName}"`,
            data: { projectId },
        });
    },

    /**
     * New product from favorited project notification
     * Sent to users who have favorited a project when a new product is approved
     */
    newProductFromFavorite(userId: number, productId: number, productName: string, projectName: string, projectId: number, quantity: number): Promise<Notification> {
        return createNotification({
            userId,
            type: 'product_approval',
            title: `New product from ${projectName}`,
            titleAr: `منتج جديد من ${projectName}`,
            body: `${projectName} just added "${productName}" - ${quantity} available now!`,
            bodyAr: `${projectName} أضاف "${productName}" - ${quantity} متوفر الآن!`,
            data: { productId, projectId, quantity },
        });
    },
};
