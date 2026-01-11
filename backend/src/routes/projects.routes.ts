import { Router } from 'express';
import {
    getProjects,
    getProjectById,
    getProjectProducts,
    getMyProject,
    createProject,
    updateProject,
} from '../controllers/projectController';
import { authenticate, projectOwnerOnly, optionalAuth } from '../middleware/auth';
import { validate, projectValidations, commonValidations } from '../middleware/validate';
import { upload, processProjectImage } from '../middleware/upload';

const router = Router();

// ==================== Public Routes ====================

/**
 * @route   GET /projects
 * @desc    Get all approved projects with pagination
 * @access  Public
 */
router.get(
    '/',
    optionalAuth,
    validate([commonValidations.page, commonValidations.limit]),
    getProjects
);

// ==================== Protected Routes ====================

/**
 * @route   GET /projects/my-project
 * @desc    Get current user's project
 * @access  Private (Project Owner)
 */
router.get('/my-project', authenticate, getMyProject);

/**
 * @route   POST /projects
 * @desc    Create a new project
 * @access  Private
 */
router.post(
    '/',
    authenticate,
    validate(projectValidations.create),
    createProject
);

/**
 * @route   PUT /projects/:id
 * @desc    Update project details
 * @access  Private (Owner/Admin)
 */
router.put(
    '/:id',
    authenticate,
    upload.single('coverImage'),
    processProjectImage,
    validate(projectValidations.update),
    updateProject
);

// ==================== Public Routes (ID params) ====================

/**
 * @route   GET /projects/:id
 * @desc    Get project by ID
 * @access  Public
 */
router.get(
    '/:id',
    validate(projectValidations.getById),
    getProjectById
);

/**
 * @route   GET /projects/:id/products
 * @desc    Get project products
 * @access  Public
 */
router.get(
    '/:id/products',
    validate([
        ...projectValidations.getById,
        commonValidations.page,
        commonValidations.limit,
    ]),
    getProjectProducts
);

export default router;
