import { Router } from 'express';
import {
  adminGetCategories,
  createCategory,
  updateCategory,
  deleteCategory,
  reorderCategories,
  toggleCategory,
  getCategoryRequests,
  approveCategory,
  rejectCategory,
} from '../controllers/admin.categories.controller';
import { getDashboardStats } from '../controllers/admin.controller';
import { validate, categoryValidations } from '../middleware/validate';
import { authenticate, adminOnly } from '../middleware/auth';
import { getUsers, toggleUserBan } from '../controllers/admin.users.controller';

const router = Router();

// All admin routes require authentication and admin role
router.use(authenticate, adminOnly);

// ==================== Dashboard ====================

/**
 * @route   GET /admin/stats/dashboard
 * @desc    Get dashboard statistics
 * @access  Admin
 */
router.get('/stats/dashboard', getDashboardStats);

// ==================== User Management ====================

/**
 * @route   GET /admin/users
 * @desc    Get all users with pagination and filters
 * @access  Admin
 */
router.get('/users', getUsers);

/**
 * @route   PUT /admin/users/:id/ban
 * @desc    Toggle user ban status
 * @access  Admin
 */
router.put('/users/:id/ban', toggleUserBan);

// ==================== Category Management ====================

/**
 * @route   GET /admin/categories
 * @desc    Get all categories (including inactive) for admin
 * @access  Admin
 */
router.get('/categories', adminGetCategories);

/**
 * @route   GET /admin/categories/requests
 * @desc    Get category requests (pending)
 * @access  Admin
 */
router.get('/categories/requests', getCategoryRequests);

/**
 * @route   POST /admin/categories
 * @desc    Create a new category
 * @access  Admin
 */
router.post('/categories', validate(categoryValidations.create), createCategory);

/**
 * @route   PUT /admin/categories/reorder
 * @desc    Reorder categories
 * @access  Admin
 */
router.put('/categories/reorder', validate(categoryValidations.reorder), reorderCategories);

/**
 * @route   PUT /admin/categories/:id
 * @desc    Update a category
 * @access  Admin
 */
router.put('/categories/:id', validate(categoryValidations.update), updateCategory);

/**
 * @route   PUT /admin/categories/:id/toggle
 * @desc    Toggle category active status
 * @access  Admin
 */
router.put('/categories/:id/toggle', validate(categoryValidations.getById), toggleCategory);

/**
 * @route   PUT /admin/categories/:id/approve
 * @desc    Approve a category request
 * @access  Admin
 */
router.put('/categories/:id/approve', validate(categoryValidations.getById), approveCategory);

/**
 * @route   PUT /admin/categories/:id/reject
 * @desc    Reject a category request
 * @access  Admin
 */
router.put('/categories/:id/reject', validate(categoryValidations.getById), rejectCategory);

/**
 * @route   DELETE /admin/categories/:id
 * @desc    Delete a category
 * @access  Admin
 */
router.delete('/categories/:id', validate(categoryValidations.getById), deleteCategory);

export default router;

