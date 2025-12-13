import { Router } from 'express';
import {
    getAllProjects,
    getPendingProjects,
    getProjectById,
    approveProject,
    rejectProject,
    disableProject,
    enableProject,
} from '../controllers/projectController';
import { validate, projectValidations, commonValidations } from '../middleware/validate';

const router = Router();

// Note: Authentication and Admin role check are handled in the parent router (index.ts or admin.routes.ts)

/**
 * @route   GET /admin/projects
 * @desc    Get all projects (with filtering)
 * @access  Admin
 */
router.get(
    '/',
    validate([commonValidations.page, commonValidations.limit]),
    getAllProjects
);

/**
 * @route   GET /admin/projects/pending
 * @desc    Get pending projects
 * @access  Admin
 */
router.get(
    '/pending',
    validate([commonValidations.page, commonValidations.limit]),
    getPendingProjects
);

/**
 * @route   GET /admin/projects/:id
 * @desc    Get project details
 * @access  Admin
 */
router.get(
    '/:id',
    validate(projectValidations.getById),
    getProjectById
);

/**
 * @route   PUT /admin/projects/:id/approve
 * @desc    Approve a project
 * @access  Admin
 */
router.put(
    '/:id/approve',
    validate(projectValidations.getById),
    approveProject
);

/**
 * @route   PUT /admin/projects/:id/reject
 * @desc    Reject a project
 * @access  Admin
 */
router.put(
    '/:id/reject',
    validate(projectValidations.reject),
    rejectProject
);

/**
 * @route   PUT /admin/projects/:id/disable
 * @desc    Disable a project
 * @access  Admin
 */
router.put(
    '/:id/disable',
    validate(projectValidations.disable),
    disableProject
);

/**
 * @route   PUT /admin/projects/:id/enable
 * @desc    Enable a project
 * @access  Admin
 */
router.put(
    '/:id/enable',
    validate(projectValidations.getById),
    enableProject
);

export default router;
