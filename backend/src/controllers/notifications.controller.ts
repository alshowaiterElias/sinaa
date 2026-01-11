import { Request, Response, NextFunction } from 'express';
import { Op } from 'sequelize';
import Notification from '../models/Notification';
import { sendSuccess, sendError, sendPaginated } from '../utils/helpers';
import { ERROR_CODES, PAGINATION } from '../config/constants';

/**
 * Get user's notifications (paginated)
 */
export const getNotifications = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = req.user!.id;
        const page = parseInt(req.query.page as string) || PAGINATION.DEFAULT_PAGE;
        const limit = Math.min(
            parseInt(req.query.limit as string) || PAGINATION.DEFAULT_LIMIT,
            PAGINATION.MAX_LIMIT
        );
        const offset = (page - 1) * limit;
        const unreadOnly = req.query.unread === 'true';

        const whereClause: any = { userId };
        if (unreadOnly) {
            whereClause.isRead = false;
        }

        const { count, rows: notifications } = await Notification.findAndCountAll({
            where: whereClause,
            order: [['createdAt', 'DESC']],
            limit,
            offset,
        });

        return sendPaginated(res, notifications, { page, limit, total: count });
    } catch (error) {
        next(error);
    }
};

/**
 * Get unread notifications count
 */
export const getUnreadCount = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = req.user!.id;

        const count = await Notification.count({
            where: {
                userId,
                isRead: false,
            },
        });

        return sendSuccess(res, { count });
    } catch (error) {
        next(error);
    }
};

/**
 * Mark single notification as read
 */
export const markAsRead = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = req.user!.id;
        const { id } = req.params;

        const notification = await Notification.findOne({
            where: { id, userId },
        });

        if (!notification) {
            return sendError(res, ERROR_CODES.NOT_FOUND, 'Notification not found', 404);
        }

        notification.isRead = true;
        await notification.save();

        return sendSuccess(res, notification);
    } catch (error) {
        next(error);
    }
};

/**
 * Mark all notifications as read
 */
export const markAllAsRead = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = req.user!.id;

        const [updated] = await Notification.update(
            { isRead: true },
            {
                where: {
                    userId,
                    isRead: false,
                },
            }
        );

        return sendSuccess(res, { markedAsRead: updated });
    } catch (error) {
        next(error);
    }
};

/**
 * Delete a notification
 */
export const deleteNotification = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = req.user!.id;
        const { id } = req.params;

        const notification = await Notification.findOne({
            where: { id, userId },
        });

        if (!notification) {
            return sendError(res, ERROR_CODES.NOT_FOUND, 'Notification not found', 404);
        }

        await notification.destroy();

        return sendSuccess(res, null, 'Notification deleted');
    } catch (error) {
        next(error);
    }
};

/**
 * Delete all notifications for the current user
 */
export const deleteAll = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = req.user!.id;

        await Notification.destroy({
            where: { userId },
        });

        return sendSuccess(res, null, 'All notifications deleted');
    } catch (error) {
        next(error);
    }
};
