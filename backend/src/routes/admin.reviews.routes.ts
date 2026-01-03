import { Router } from 'express';
import { authenticate, authorize } from '../middleware/auth';
import { validate } from '../middleware/validate';
import { body, query, param } from 'express-validator';
import {
    getAllReviews,
    getReviewById,
    approveReview,
    rejectReview,
} from '../controllers/admin.reviews.controller';

const router = Router();

// Middleware to ensure admin
router.use(authenticate, authorize('admin', 'super_admin' as any));

// Validation rules
const listValidation = [
    query('page').optional().isInt({ min: 1 }),
    query('limit').optional().isInt({ min: 1, max: 100 }),
    query('status').optional().isIn(['all', 'pending', 'approved', 'rejected']),
    query('productId').optional().isInt(),
    query('userId').optional().isInt(),
    query('sort').optional().isIn(['newest', 'oldest', 'rating_high', 'rating_low', 'pending_first']),
    query('search').optional().trim(),
    query('searchField').optional().isIn(['all', 'comment', 'userName', 'productName', 'projectOwner']),
];

const reasonValidation = [
    body('reason').optional().trim(),
];

// List all reviews with filters
router.get('/', validate(listValidation), getAllReviews);

// Get single review
router.get('/:id', validate([param('id').isInt()]), getReviewById);

// Approve review
router.put('/:id/approve', validate([param('id').isInt()]), approveReview);

// Reject review
router.put('/:id/reject', validate([param('id').isInt(), ...reasonValidation]), rejectReview);

export default router;
