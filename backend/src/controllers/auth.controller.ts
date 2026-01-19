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
import { sendVerificationEmail } from '../services/email.service';
import crypto from 'crypto';
import { logger } from '../utils/logger';

/**
 * Register a new customer
 * POST /auth/register
 */
export const register = asyncHandler(async (req: Request, res: Response) => {
  const { email, password, fullName, phone, language, city, latitude, longitude, locationSharingEnabled } = req.body;

  // Debug logging for location data
  console.log('[REGISTER] Received location data:', {
    city,
    latitude,
    longitude,
    locationSharingEnabled,
    latitudeType: typeof latitude,
    longitudeType: typeof longitude,
  });

  // Check if email already exists
  const existingUser = await User.findOne({ where: { email } });
  if (existingUser) {
    return sendConflict(res, 'Email already registered');
  }

  // Hash password
  const passwordHash = await hashPassword(password);

  // Parse location coordinates
  const parsedLatitude = latitude !== undefined && latitude !== null ? parseFloat(latitude) : null;
  const parsedLongitude = longitude !== undefined && longitude !== null ? parseFloat(longitude) : null;
  const hasLocation = parsedLatitude !== null && parsedLongitude !== null && !isNaN(parsedLatitude) && !isNaN(parsedLongitude);

  console.log('[REGISTER] Parsed location:', {
    parsedLatitude,
    parsedLongitude,
    hasLocation,
    cityToSave: city || null,
  });

  // Create user data object explicitly
  const verificationToken = crypto.randomInt(100000, 999999).toString();
  const verificationTokenExpires = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24 hours

  const userData = {
    email,
    passwordHash,
    fullName,
    phone: phone || null,
    language: language || 'ar',
    city: city || null,
    latitude: hasLocation ? parsedLatitude : null,
    longitude: hasLocation ? parsedLongitude : null,
    locationSharingEnabled: locationSharingEnabled !== false, // Default to true
    locationUpdatedAt: hasLocation || city ? new Date() : null,
    role: USER_ROLES.CUSTOMER,
    verificationToken,
    verificationTokenExpires,
    isVerified: false,
  };

  logger.info('[REGISTER] Creating user with data:', { ...userData, passwordHash: '***' });

  // Create user
  const user = await User.create(userData);

  // Send verification email
  await sendVerificationEmail(user.email, verificationToken);

  // Generate tokens
  const tokenPayload: TokenPayload = {
    userId: user.id,
    email: user.email,
    role: user.role,
  };
  const tokens = generateTokenPair(tokenPayload);

  // Save refresh token
  await user.update({ refreshToken: tokens.refreshToken });

  logger.info(`[REGISTER] User registered successfully: ${user.id}`);

  return sendSuccess(
    res,
    {
      user: user.toSafeJSON(),
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    },
    'Registration successful. Please check your email to verify your account.',
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
      // User location fields
      userCity,
      userLatitude,
      userLongitude,
      locationSharingEnabled,
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

      const verificationToken = crypto.randomInt(100000, 999999).toString();
      const verificationTokenExpires = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24 hours

      // Create user
      const user = await User.create(
        {
          email,
          passwordHash,
          fullName,
          phone: phone || null,
          language: language || 'ar',
          role: USER_ROLES.PROJECT_OWNER,
          city: userCity || null,
          latitude: userLatitude || null,
          longitude: userLongitude || null,
          locationSharingEnabled: locationSharingEnabled !== false,
          locationUpdatedAt: userLatitude || userCity ? new Date() : null,
          verificationToken,
          verificationTokenExpires,
          isVerified: false,
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
          coverUrl: req.file ? `/uploads/projects/${req.file.filename}` : null,
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

      // Send verification email
      await sendVerificationEmail(user.email, verificationToken);

      // Generate tokens
      const tokenPayload: TokenPayload = {
        userId: user.id,
        email: user.email,
        role: user.role,
      };
      const tokens = generateTokenPair(tokenPayload);

      // Save refresh token
      await user.update({ refreshToken: tokens.refreshToken });

      logger.info(`[REGISTER_PO] Project Owner registered successfully: ${user.id}`);

      return sendSuccess(
        res,
        {
          user: user.toSafeJSON(),
          accessToken: tokens.accessToken,
          refreshToken: tokens.refreshToken,
        },
        'Registration successful. Please check your email to verify your account. Your project is pending approval.',
        201
      );
    } catch (error) {
      await transaction.rollback();
      logger.error('[REGISTER_PO] Error registering project owner', { error });
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
  const { fullName, phone, language, city, latitude, longitude, locationSharingEnabled, notificationsEnabled } = req.body;

  console.log('[UPDATE_ME] Received:', { fullName, phone, language, city, latitude, longitude, locationSharingEnabled, notificationsEnabled });

  // Update fields
  const updateData: Partial<{
    fullName: string;
    phone: string | null;
    language: 'ar' | 'en';
    city: string | null;
    latitude: number | null;
    longitude: number | null;
    locationSharingEnabled: boolean;
    notificationsEnabled: boolean;
    locationUpdatedAt: Date | null;
  }> = {};

  if (fullName !== undefined) updateData.fullName = fullName;
  if (phone !== undefined) updateData.phone = phone;
  if (language !== undefined) updateData.language = language;

  // Handle location fields
  if (city !== undefined) {
    updateData.city = city ? city.trim() : null;
  }

  if (latitude !== undefined && longitude !== undefined) {
    const parsedLat = parseFloat(latitude);
    const parsedLon = parseFloat(longitude);
    console.log('[UPDATE_ME] Parsed coordinates:', { parsedLat, parsedLon });
    if (!isNaN(parsedLat) && !isNaN(parsedLon)) {
      updateData.latitude = parsedLat;
      updateData.longitude = parsedLon;
      updateData.locationUpdatedAt = new Date();
    }
  }

  if (locationSharingEnabled !== undefined) {
    updateData.locationSharingEnabled = Boolean(locationSharingEnabled);
  }

  if (notificationsEnabled !== undefined) {
    updateData.notificationsEnabled = Boolean(notificationsEnabled);
  }

  console.log('[UPDATE_ME] Update data:', updateData);

  await user.update(updateData);

  // Reload to get fresh data from DB
  await user.reload();

  console.log('[UPDATE_ME] User after update:', user.toSafeJSON());

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

/**
 * Verify email
 * POST /auth/verify-email
 */
export const verifyEmail = asyncHandler(async (req: Request, res: Response) => {
  const { token } = req.body;

  if (!token) {
    return sendError(res, ERROR_CODES.VALIDATION_ERROR, 'Token is required', 400);
  }

  const user = await User.findOne({ where: { verificationToken: token } });

  if (!user) {
    return sendError(res, ERROR_CODES.VALIDATION_ERROR, 'Invalid verification token', 400);
  }

  if (user.isVerified) {
    return sendSuccess(res, null, 'Email already verified');
  }

  if (user.verificationTokenExpires && user.verificationTokenExpires < new Date()) {
    return sendError(res, ERROR_CODES.VALIDATION_ERROR, 'Verification token expired', 400);
  }

  // Update user
  await user.update({
    isVerified: true,
    verificationToken: null,
    verificationTokenExpires: null,
  });

  logger.info(`[VERIFY_EMAIL] User verified successfully: ${user.id}`);

  return sendSuccess(res, null, 'Email verified successfully');
});

/**
 * Resend verification email
 * POST /auth/resend-verification
 */
export const resendVerificationEmail = asyncHandler(async (req: Request, res: Response) => {
  const { email } = req.body;

  if (!email) {
    return sendError(res, ERROR_CODES.VALIDATION_ERROR, 'Email is required', 400);
  }

  const user = await User.findOne({ where: { email } });

  if (!user) {
    // Return success to prevent email enumeration
    return sendSuccess(res, null, 'If an account exists, a verification email has been sent');
  }

  if (user.isVerified) {
    return sendSuccess(res, null, 'Email already verified');
  }

  // Generate new token
  const verificationToken = crypto.randomInt(100000, 999999).toString();
  const verificationTokenExpires = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24 hours

  await user.update({
    verificationToken,
    verificationTokenExpires,
  });

  // Send email
  await sendVerificationEmail(user.email, verificationToken);

  logger.info(`[RESEND_VERIFICATION] Verification email resent to: ${email}`);

  return sendSuccess(res, null, 'Verification email sent');
});
