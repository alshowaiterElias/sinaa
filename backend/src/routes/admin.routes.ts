import { Router } from 'express';
import {
  adminGetCategories,
  createCategory,
  updateCategory,
  deleteCategory,
  reorderCategories,
  toggleCategory,
} from '../controllers/categories.controller';
import { validate, categoryValidations } from '../middleware/validate';
import { authenticate, adminOnly } from '../middleware/auth';

const router = Router();

// All admin routes require authentication and admin role
router.use(authenticate, adminOnly);

// ==================== Category Management ====================

/**
 * @route   GET /admin/categories
 * @desc    Get all categories (including inactive) for admin
 * @access  Admin
 */
router.get('/categories', adminGetCategories);

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
 * @route   DELETE /admin/categories/:id
 * @desc    Delete a category
 * @access  Admin
 */
router.delete('/categories/:id', validate(categoryValidations.getById), deleteCategory);

export default router;

