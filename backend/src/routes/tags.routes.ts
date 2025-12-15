import { Router } from 'express';
import { getAllTags, createTag, findOrCreateTag } from '../controllers/tags.controller';
import { authenticate } from '../middleware/auth';

const router = Router();

// Public routes
router.get('/', getAllTags);

// Protected routes (require authentication)
router.post('/', authenticate, createTag);
router.post('/find-or-create', authenticate, findOrCreateTag);

export default router;
