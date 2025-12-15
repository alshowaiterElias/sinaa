import { Router } from 'express';
import {
    getConversations,
    getConversation,
    createConversation,
    sendMessage,
    markAsRead,
} from '../controllers/conversations.controller';
import { authenticate } from '../middleware/auth';

const router = Router();

// All routes require authentication
router.use(authenticate);

// GET /conversations - List user's conversations
router.get('/', getConversations);

// POST /conversations - Start new conversation
router.post('/', createConversation);

// GET /conversations/:id - Get conversation with messages
router.get('/:id', getConversation);

// POST /conversations/:id/messages - Send message (REST fallback)
router.post('/:id/messages', sendMessage);

// PUT /conversations/:id/read - Mark as read
router.put('/:id/read', markAsRead);

export default router;
