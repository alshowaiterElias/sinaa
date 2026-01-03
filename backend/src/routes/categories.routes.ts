import { Router } from 'express';
import {
  getCategories,
  getCategoryById,
  getCategoryProducts,
} from '../controllers/categories.controller';
import { validate, categoryValidations } from '../middleware/validate';
import { authenticate } from '../middleware/auth';
import {
  requestCategory,
  getMyRequests,
} from '../controllers/categories.request.controller';

const router = Router();

// ==================== Protected Routes ====================

/**
 * @route   POST /categories/request
 * @desc    Request a new category
 * @access  Private
 */
router.post(
  '/request',
  authenticate,
  validate(categoryValidations.create),
  requestCategory
);

/**
 * @route   GET /categories/my-requests
 * @desc    Get my requested categories
 * @access  Private
 */
router.get('/my-requests', authenticate, getMyRequests);

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
