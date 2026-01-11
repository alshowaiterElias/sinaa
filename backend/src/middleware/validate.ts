import { Request, Response, NextFunction } from 'express';
import { validationResult, ValidationChain, body, param, query } from 'express-validator';
import { sendValidationError } from '../utils/helpers';

/**
 * Validation middleware that runs validators and handles errors
 */
export const validate = (validations: ValidationChain[]) => {
  return async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    // Run all validations
    await Promise.all(validations.map((validation) => validation.run(req)));

    // Check for errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      const formattedErrors = errors.array().map((error) => ({
        field: 'path' in error ? error.path : 'unknown',
        message: error.msg,
      }));
      sendValidationError(res, formattedErrors);
      return;
    }

    next();
  };
};

// Common validation rules
export const commonValidations = {
  // Email validation
  email: body('email')
    .isEmail()
    .withMessage('Please provide a valid email address')
    .normalizeEmail(),

  // Password validation
  password: body('password')
    .isLength({ min: 8 })
    .withMessage('Password must be at least 8 characters long')
    .matches(/[A-Z]/)
    .withMessage('Password must contain at least one uppercase letter')
    .matches(/[a-z]/)
    .withMessage('Password must contain at least one lowercase letter')
    .matches(/\d/)
    .withMessage('Password must contain at least one number'),

  // Simple password (for login - just check not empty)
  loginPassword: body('password').notEmpty().withMessage('Password is required'),

  // Full name validation
  fullName: body('fullName')
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('Full name must be between 2 and 100 characters'),

  // Phone validation (optional, Saudi format)
  phone: body('phone')
    .optional({ nullable: true })
    .matches(/^(\+966|05)\d{8,9}$/)
    .withMessage('Please provide a valid Saudi phone number'),

  // Language validation
  language: body('language')
    .optional()
    .isIn(['ar', 'en'])
    .withMessage('Language must be either "ar" or "en"'),

  // Pagination
  page: query('page')
    .optional()
    .isInt({ min: 1 })
    .withMessage('Page must be a positive integer'),

  limit: query('limit')
    .optional()
    .isInt({ min: 1, max: 100 })
    .withMessage('Limit must be between 1 and 100'),

  // ID parameter
  idParam: (paramName: string = 'id') =>
    param(paramName)
      .isInt({ min: 1 })
      .withMessage(`${paramName} must be a positive integer`),

  // Project name
  projectName: body('projectName')
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('Project name must be between 2 and 100 characters'),

  projectNameAr: body('projectNameAr')
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('Arabic project name must be between 2 and 100 characters'),

  // City
  city: body('city')
    .trim()
    .notEmpty()
    .withMessage('City is required')
    .isLength({ max: 100 })
    .withMessage('City name is too long'),
};

// Auth validation schemas
export const authValidations = {
  register: [
    commonValidations.email,
    commonValidations.password,
    commonValidations.fullName,
    commonValidations.phone,
    commonValidations.language,
  ],

  registerProjectOwner: [
    commonValidations.email,
    commonValidations.password,
    commonValidations.fullName,
    commonValidations.phone,
    commonValidations.language,
    commonValidations.projectName,
    commonValidations.projectNameAr,
    commonValidations.city,
  ],

  login: [
    commonValidations.email,
    commonValidations.loginPassword,
  ],

  forgotPassword: [commonValidations.email],

  resetPassword: [
    body('token').notEmpty().withMessage('Reset token is required'),
    commonValidations.password,
  ],

  updateProfile: [
    body('fullName')
      .optional()
      .trim()
      .isLength({ min: 2, max: 100 })
      .withMessage('Full name must be between 2 and 100 characters'),
    body('phone')
      .optional({ nullable: true })
      .matches(/^(\+966|05)\d{8,9}$/)
      .withMessage('Please provide a valid Saudi phone number'),
    commonValidations.language,
    body('notificationsEnabled')
      .optional()
      .isBoolean()
      .withMessage('notificationsEnabled must be a boolean'),
  ],

  changePassword: [
    body('currentPassword').notEmpty().withMessage('Current password is required'),
    commonValidations.password.withMessage('New password requirements not met'),
  ],

  refreshToken: [
    body('refreshToken').notEmpty().withMessage('Refresh token is required'),
  ],
};

// Category validation schemas
export const categoryValidations = {
  getById: [commonValidations.idParam('id')],

  getProducts: [
    commonValidations.idParam('id'),
    commonValidations.page,
    commonValidations.limit,
  ],

  create: [
    body('name')
      .trim()
      .isLength({ min: 2, max: 100 })
      .withMessage('Category name must be between 2 and 100 characters'),
    body('nameAr')
      .trim()
      .isLength({ min: 2, max: 100 })
      .withMessage('Arabic category name must be between 2 and 100 characters'),
    body('icon')
      .optional({ nullable: true })
      .isLength({ max: 100 })
      .withMessage('Icon name is too long'),
    body('parentId')
      .optional({ nullable: true })
      .isInt({ min: 1 })
      .withMessage('Parent ID must be a positive integer'),
    body('sortOrder')
      .optional()
      .isInt({ min: 0 })
      .withMessage('Sort order must be a non-negative integer'),
    body('isActive')
      .optional()
      .isBoolean()
      .withMessage('isActive must be a boolean'),
  ],

  update: [
    commonValidations.idParam('id'),
    body('name')
      .optional()
      .trim()
      .isLength({ min: 2, max: 100 })
      .withMessage('Category name must be between 2 and 100 characters'),
    body('nameAr')
      .optional()
      .trim()
      .isLength({ min: 2, max: 100 })
      .withMessage('Arabic category name must be between 2 and 100 characters'),
    body('icon')
      .optional({ nullable: true })
      .isLength({ max: 100 })
      .withMessage('Icon name is too long'),
    body('parentId')
      .optional({ nullable: true })
      .custom((value) => {
        if (value !== null && (!Number.isInteger(Number(value)) || Number(value) < 1)) {
          throw new Error('Parent ID must be null or a positive integer');
        }
        return true;
      }),
    body('sortOrder')
      .optional()
      .isInt({ min: 0 })
      .withMessage('Sort order must be a non-negative integer'),
    body('isActive')
      .optional()
      .isBoolean()
      .withMessage('isActive must be a boolean'),
  ],

  reorder: [
    body('orders')
      .isArray({ min: 1 })
      .withMessage('Orders must be a non-empty array'),
    body('orders.*.id')
      .isInt({ min: 1 })
      .withMessage('Each order must have a valid category ID'),
    body('orders.*.sortOrder')
      .isInt({ min: 0 })
      .withMessage('Each order must have a valid sort order'),
  ],
};

// Project validation schemas
export const projectValidations = {
  create: [
    commonValidations.projectName.withMessage('Project name is required'),
    commonValidations.projectNameAr.withMessage('Arabic project name is required'),
    commonValidations.city,
    body('description').optional().trim(),
    body('descriptionAr').optional().trim(),
    body('latitude').optional({ nullable: true }).isFloat({ min: -90, max: 90 }),
    body('longitude').optional({ nullable: true }).isFloat({ min: -180, max: 180 }),
    body('workingHours').optional({ nullable: true }).isObject(),
    body('socialLinks').optional({ nullable: true }).isObject(),
  ],

  update: [
    commonValidations.idParam('id'),
    commonValidations.projectName.optional(),
    commonValidations.projectNameAr.optional(),
    commonValidations.city.optional(),
    body('description').optional().trim(),
    body('descriptionAr').optional().trim(),
    body('latitude').optional({ nullable: true }).isFloat({ min: -90, max: 90 }),
    body('longitude').optional({ nullable: true }).isFloat({ min: -180, max: 180 }),
    body('workingHours').optional({ nullable: true }).isObject(),
    body('socialLinks').optional({ nullable: true }).isObject(),
  ],

  getById: [commonValidations.idParam('id')],

  reject: [
    commonValidations.idParam('id'),
    body('reason').trim().notEmpty().withMessage('Rejection reason is required'),
  ],

  disable: [
    commonValidations.idParam('id'),
    body('reason').trim().notEmpty().withMessage('Disable reason is required'),
  ],
};

export { body, param, query } from 'express-validator';
