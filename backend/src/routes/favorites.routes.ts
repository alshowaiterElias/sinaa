import { Router } from 'express';
import { authenticate } from '../middleware/auth';
import {
    addFavorite,
    removeFavorite,
    getMyFavorites,
    checkFavorite,
    toggleFavorite,
} from '../controllers/favorites.controller';

const router = Router();

// All routes require authentication
router.use(authenticate);

/**
 * @route   GET /favorites
 * @desc    Get user's favorite projects
 * @access  Private
 */
router.get('/', getMyFavorites);

/**
 * @route   POST /favorites/:projectId
 * @desc    Add a project to favorites
 * @access  Private
 */
router.post('/:projectId', addFavorite);

/**
 * @route   DELETE /favorites/:projectId
 * @desc    Remove a project from favorites
 * @access  Private
 */
router.delete('/:projectId', removeFavorite);

/**
 * @route   GET /favorites/:projectId/check
 * @desc    Check if project is in favorites
 * @access  Private
 */
router.get('/:projectId/check', checkFavorite);

/**
 * @route   POST /favorites/:projectId/toggle
 * @desc    Toggle favorite status
 * @access  Private
 */
router.post('/:projectId/toggle', toggleFavorite);

export default router;
