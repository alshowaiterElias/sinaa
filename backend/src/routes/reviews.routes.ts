import { Router } from 'express';
import { authenticate } from '../middleware/auth';
import {
    createReview,
    getProductReviews,
    getMyReviews,
    updateReview,
    deleteReview,
} from '../controllers/reviews.controller';

const router = Router();

// Public routes (no auth required for viewing product reviews)
router.get('/product/:productId', getProductReviews);

// Protected routes
router.use(authenticate);
router.post('/', createReview);
router.get('/my', getMyReviews);
router.put('/:id', updateReview);
router.delete('/:id', deleteReview);

export default router;
