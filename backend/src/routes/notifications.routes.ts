import { Router } from 'express';
import {
    getNotifications,
    getUnreadCount,
    markAsRead,
    markAllAsRead,
    deleteNotification,
} from '../controllers/notifications.controller';
import { authenticate } from '../middleware/auth';

const router = Router();

// All routes require authentication
router.use(authenticate);

// GET /notifications - List user's notifications
router.get('/', getNotifications);

// GET /notifications/unread-count - Get unread count
router.get('/unread-count', getUnreadCount);

// PUT /notifications/read-all - Mark all as read
router.put('/read-all', markAllAsRead);

// PUT /notifications/:id/read - Mark single as read
router.put('/:id/read', markAsRead);

// DELETE /notifications/:id - Delete notification
router.delete('/:id', deleteNotification);

export default router;
