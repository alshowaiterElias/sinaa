import { Router } from 'express';
import { authenticate, authorize } from '../middleware/auth';
import { validate } from '../middleware/validate';
import { body, query, param } from 'express-validator';
import {
    getAllProducts,
    getProductById,
    approveProduct,
    rejectProduct,
    disableProduct,
    enableProduct,
} from '../controllers/admin.products.controller';

const router = Router();

// Middleware to ensure admin
router.use(authenticate, authorize('admin', 'super_admin' as any));

// Validation rules
const listValidation = [
    query('page').optional().isInt({ min: 1 }),
    query('limit').optional().isInt({ min: 1, max: 100 }),
    query('status').optional().isIn(['all', 'pending', 'approved', 'rejected']),
    query('categoryId').optional().isInt(),
    query('projectId').optional().isInt(),
    query('ownerId').optional().isInt(),
    query('sort').optional().isIn(['newest', 'oldest', 'name', 'price_high', 'price_low', 'rating', 'pending_first']),
];

const reasonValidation = [
    body('reason').trim().notEmpty().withMessage('Reason is required'),
];

// List all products with filters
router.get('/', validate(listValidation), getAllProducts);

// Get single product
router.get('/:id', validate([param('id').isInt()]), getProductById);

// Approve product
router.put('/:id/approve', validate([param('id').isInt()]), approveProduct);

// Reject product
router.put('/:id/reject', validate([param('id').isInt(), ...reasonValidation]), rejectProduct);

// Disable product
router.put('/:id/disable', validate([param('id').isInt(), ...reasonValidation]), disableProduct);

// Enable product
router.put('/:id/enable', validate([param('id').isInt()]), enableProduct);

export default router;

