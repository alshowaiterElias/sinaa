import { Request, Response } from 'express';
import { User, Project } from '../models';
import { hashPassword, comparePassword } from '../utils/password';
import {
  generateTokenPair,
  verifyRefreshToken,
  TokenPayload,
} from '../utils/jwt';
import {
  sendSuccess,
  sendError,
  sendUnauthorized,
  sendConflict,
  sendNotFound,
} from '../utils/helpers';
import { ERROR_CODES, USER_ROLES, PROJECT_STATUS } from '../config/constants';
import { asyncHandler } from '../middleware/errorHandler';
import sequelize from '../config/database';

/**
 * Register a new customer
 * POST /auth/register
 */
export const register = asyncHandler(async (req: Request, res: Response) => {
  const { email, password, fullName, phone, language } = req.body;

  // Check if email already exists
  const existingUser = await User.findOne({ where: { email } });
  if (existingUser) {
    return sendConflict(res, 'Email already registered');
  }

  // Hash password
  const passwordHash = await hashPassword(password);

  // Create user
  const user = await User.create({
    email,
    passwordHash,
    fullName,
    phone: phone || null,
    language: language || 'ar',
    role: USER_ROLES.CUSTOMER,
  });

  // Generate tokens
  const tokenPayload: TokenPayload = {
    userId: user.id,
    email: user.email,
    role: user.role,
  };
  const tokens = generateTokenPair(tokenPayload);

  // Save refresh token
  await user.update({ refreshToken: tokens.refreshToken });

  return sendSuccess(
    res,
    {
      user: user.toSafeJSON(),
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    },
    'Registration successful',
    201
  );
});

/**
 * Register a new project owner with their project
 * POST /auth/register/project-owner
 */
export const registerProjectOwner = asyncHandler(
  async (req: Request, res: Response) => {
    const {
      email,
      password,
      fullName,
      phone,
      language,
      projectName,
      projectNameAr,
      city,
      description,
      descriptionAr,
      latitude,
      longitude,
      workingHours,
      socialLinks,
    } = req.body;

    // Check if email already exists
    const existingUser = await User.findOne({ where: { email } });
    if (existingUser) {
      return sendConflict(res, 'Email already registered');
    }

    // Start transaction
    const transaction = await sequelize.transaction();

    try {
      // Hash password
      const passwordHash = await hashPassword(password);

      // Create user
      const user = await User.create(
        {
          email,
          passwordHash,
          fullName,
          phone: phone || null,
          language: language || 'ar',
          role: USER_ROLES.PROJECT_OWNER,
        },
        { transaction }
      );

      // Create project
      await Project.create(
        {
          ownerId: user.id,
          name: projectName,
          nameAr: projectNameAr,
          city,
          description: description || null,
          descriptionAr: descriptionAr || null,
          latitude: latitude || null,
          longitude: longitude || null,
          workingHours: workingHours || null,
          socialLinks: socialLinks || null,
          status: PROJECT_STATUS.PENDING,
        },
        { transaction }
      );

      // Commit transaction
      await transaction.commit();

      // Generate tokens
      const tokenPayload: TokenPayload = {
        userId: user.id,
        email: user.email,
        role: user.role,
      };
      const tokens = generateTokenPair(tokenPayload);

      // Save refresh token
      await user.update({ refreshToken: tokens.refreshToken });

      return sendSuccess(
        res,
        {
          user: user.toSafeJSON(),
          accessToken: tokens.accessToken,
          refreshToken: tokens.refreshToken,
        },
        'Registration successful. Your project is pending approval.',
        201
      );
    } catch (error) {
      await transaction.rollback();
      throw error;
    }
  }
);

/**
 * User login
 * POST /auth/login
 */
export const login = asyncHandler(async (req: Request, res: Response) => {
  const { email, password } = req.body;

  // Find user
  const user = await User.findOne({ where: { email } });
  if (!user) {
    return sendUnauthorized(res, 'Invalid email or password');
  }

  // Check password
  const isValidPassword = await comparePassword(password, user.passwordHash);
  if (!isValidPassword) {
    return sendUnauthorized(res, 'Invalid email or password');
  }

  // Check if user can access
  if (!user.canAccess()) {
    if (user.isBanned) {
      return sendError(
        res,
        ERROR_CODES.AUTHORIZATION_ERROR,
        `Account banned: ${user.banReason || 'Contact support'}`,
        403
      );
    }
    return sendError(
      res,
      ERROR_CODES.AUTHORIZATION_ERROR,
      'Account is deactivated',
      403
    );
  }

  // Generate tokens
  const tokenPayload: TokenPayload = {
    userId: user.id,
    email: user.email,
    role: user.role,
  };
  const tokens = generateTokenPair(tokenPayload);

  // Save refresh token
  await user.update({ refreshToken: tokens.refreshToken });

  // Get user with project if project owner
  let projectData = null;
  if (user.isProjectOwner()) {
    const project = await Project.findOne({ where: { ownerId: user.id } });
    projectData = project?.toJSON();
  }

  return sendSuccess(res, {
    user: user.toSafeJSON(),
    project: projectData,
    accessToken: tokens.accessToken,
    refreshToken: tokens.refreshToken,
  });
});

/**
 * User logout
 * POST /auth/logout
 */
export const logout = asyncHandler(async (req: Request, res: Response) => {
  const user = req.user!;

  // Clear refresh token
  await user.update({ refreshToken: null });

  return sendSuccess(res, null, 'Logged out successfully');
});

/**
 * Refresh access token
 * POST /auth/refresh
 */
export const refreshToken = asyncHandler(
  async (req: Request, res: Response) => {
    const { refreshToken: token } = req.body;

    // Verify refresh token
    const payload = verifyRefreshToken(token);
    if (!payload) {
      return sendUnauthorized(res, 'Invalid or expired refresh token');
    }

    // Find user and validate stored refresh token
    const user = await User.findByPk(payload.userId);
    if (!user || user.refreshToken !== token) {
      return sendUnauthorized(res, 'Invalid refresh token');
    }

    // Check if user can access
    if (!user.canAccess()) {
      return sendUnauthorized(res, 'Account access denied');
    }

    // Generate new tokens
    const tokenPayload: TokenPayload = {
      userId: user.id,
      email: user.email,
      role: user.role,
    };
    const tokens = generateTokenPair(tokenPayload);

    // Save new refresh token
    await user.update({ refreshToken: tokens.refreshToken });

    return sendSuccess(res, {
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    });
  }
);

/**
 * Get current user profile
 * GET /auth/me
 */
export const getMe = asyncHandler(async (req: Request, res: Response) => {
  const user = req.user!;

  // Get project if project owner
  let projectData = null;
  if (user.isProjectOwner()) {
    const project = await Project.findOne({ where: { ownerId: user.id } });
    projectData = project?.toJSON();
  }

  return sendSuccess(res, {
    user: user.toSafeJSON(),
    project: projectData,
  });
});

/**
 * Update current user profile
 * PUT /auth/me
 */
export const updateMe = asyncHandler(async (req: Request, res: Response) => {
  const user = req.user!;
  const { fullName, phone, language } = req.body;

  // Update fields
  const updateData: Partial<{ fullName: string; phone: string | null; language: 'ar' | 'en' }> = {};
  if (fullName !== undefined) updateData.fullName = fullName;
  if (phone !== undefined) updateData.phone = phone;
  if (language !== undefined) updateData.language = language;

  await user.update(updateData);

  return sendSuccess(res, { user: user.toSafeJSON() }, 'Profile updated successfully');
});

/**
 * Change password
 * PUT /auth/change-password
 */
export const changePassword = asyncHandler(
  async (req: Request, res: Response) => {
    const user = req.user!;
    const { currentPassword, password: newPassword } = req.body;

    // Verify current password
    const isValidPassword = await comparePassword(
      currentPassword,
      user.passwordHash
    );
    if (!isValidPassword) {
      return sendError(
        res,
        ERROR_CODES.VALIDATION_ERROR,
        'Current password is incorrect',
        400
      );
    }

    // Hash new password
    const passwordHash = await hashPassword(newPassword);

    // Update password and clear refresh token (logout all devices)
    await user.update({ passwordHash, refreshToken: null });

    // Generate new tokens
    const tokenPayload: TokenPayload = {
      userId: user.id,
      email: user.email,
      role: user.role,
    };
    const tokens = generateTokenPair(tokenPayload);

    // Save new refresh token
    await user.update({ refreshToken: tokens.refreshToken });

    return sendSuccess(
      res,
      {
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      },
      'Password changed successfully'
    );
  }
);

/**
 * Request password reset
 * POST /auth/forgot-password
 */
export const forgotPassword = asyncHandler(
  async (req: Request, res: Response) => {
    const { email } = req.body;

    // Find user
    const user = await User.findOne({ where: { email } });

    // Always return success to prevent email enumeration
    if (!user) {
      return sendSuccess(
        res,
        null,
        'If an account exists with this email, a reset link has been sent'
      );
    }

    // TODO: Generate reset token and send email
    // For now, just return success message

    return sendSuccess(
      res,
      null,
      'If an account exists with this email, a reset link has been sent'
    );
  }
);

/**
 * Reset password with token
 * POST /auth/reset-password
 */
export const resetPassword = asyncHandler(
  async (req: Request, res: Response) => {
    const { token, password } = req.body;

    // TODO: Implement password reset token verification
    // For now, return not implemented

    sendError(
      res,
      ERROR_CODES.BAD_REQUEST,
      'Password reset is not implemented yet',
      501
    );
  }
);

/**
 * Admin login (separate for admin panel)
 * POST /auth/admin/login
 */
export const adminLogin = asyncHandler(async (req: Request, res: Response) => {
  const { email, password } = req.body;

  // Find user
  const user = await User.findOne({ where: { email } });
  if (!user) {
    return sendUnauthorized(res, 'Invalid credentials');
  }

  // Check if admin
  if (!user.isAdmin()) {
    return sendUnauthorized(res, 'Invalid credentials');
  }

  // Check password
  const isValidPassword = await comparePassword(password, user.passwordHash);
  if (!isValidPassword) {
    return sendUnauthorized(res, 'Invalid credentials');
  }

  // Check if user can access
  if (!user.canAccess()) {
    return sendError(
      res,
      ERROR_CODES.AUTHORIZATION_ERROR,
      'Account access denied',
      403
    );
  }

  // Generate tokens
  const tokenPayload: TokenPayload = {
    userId: user.id,
    email: user.email,
    role: user.role,
  };
  const tokens = generateTokenPair(tokenPayload);

  // Save refresh token
  await user.update({ refreshToken: tokens.refreshToken });

  return sendSuccess(res, {
    user: user.toSafeJSON(),
    accessToken: tokens.accessToken,
    refreshToken: tokens.refreshToken,
  });
});
