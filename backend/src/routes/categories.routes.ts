import { Router } from 'express';
import {
  getCategories,
  getCategoryById,
  getCategoryProducts,
} from '../controllers/categories.controller';
import { validate, categoryValidations } from '../middleware/validate';

const router = Router();

// ==================== Public Routes ====================

/**
 * @route   GET /categories
 * @desc    Get all categories with subcategories
 * @access  Public
 */
router.get('/', getCategories);

/**
 * @route   GET /categories/:id
 * @desc    Get category by ID
 * @access  Public
 */
router.get('/:id', validate(categoryValidations.getById), getCategoryById);

/**
 * @route   GET /categories/:id/products
 * @desc    Get products in a category
 * @access  Public
 */
router.get(
  '/:id/products',
  validate(categoryValidations.getProducts),
  getCategoryProducts
);

export default router;

