import { Request, Response, NextFunction } from 'express';
import { verifyAccessToken, TokenPayload } from '../utils/jwt';
import { sendUnauthorized, sendForbidden } from '../utils/helpers';
import { User } from '../models';
import { UserRole, USER_ROLES } from '../config/constants';

// Extend Express Request type to include user
declare global {
  namespace Express {
    interface Request {
      user?: User;
      tokenPayload?: TokenPayload;
    }
  }
}

/**
 * Authentication middleware
 * Verifies JWT token and attaches user to request
 */
export const authenticate = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    // Get token from header
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      sendUnauthorized(res, 'Access token required');
      return;
    }

    const token = authHeader.substring(7);

    // Verify token
    const payload = verifyAccessToken(token);
    if (!payload) {
      sendUnauthorized(res, 'Invalid or expired token');
      return;
    }

    // Find user
    const user = await User.findByPk(payload.userId);
    if (!user) {
      sendUnauthorized(res, 'User not found');
      return;
    }

    // Check if user is active and not banned
    if (!user.canAccess()) {
      if (user.isBanned) {
        sendForbidden(res, `Account banned: ${user.banReason || 'Contact support'}`);
        return;
      }
      sendForbidden(res, 'Account is deactivated');
      return;
    }

    // Attach user and payload to request
    req.user = user;
    req.tokenPayload = payload;

    next();
  } catch (error) {
    sendUnauthorized(res, 'Authentication failed');
  }
};

/**
 * Optional authentication middleware
 * Attaches user if token is valid, but doesn't require it
 */
export const optionalAuth = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      next();
      return;
    }

    const token = authHeader.substring(7);
    const payload = verifyAccessToken(token);

    if (payload) {
      const user = await User.findByPk(payload.userId);
      if (user && user.canAccess()) {
        req.user = user;
        req.tokenPayload = payload;
      }
    }

    next();
  } catch {
    // Continue without user on error
    next();
  }
};

/**
 * Role-based authorization middleware
 * Requires authentication middleware to run first
 */
export const authorize = (...allowedRoles: UserRole[]) => {
  return (req: Request, res: Response, next: NextFunction): void => {
    if (!req.user) {
      sendUnauthorized(res, 'Authentication required');
      return;
    }

    if (!allowedRoles.includes(req.user.role)) {
      sendForbidden(res, 'You do not have permission to access this resource');
      return;
    }

    next();
  };
};

/**
 * Admin only middleware
 */
export const adminOnly = authorize(USER_ROLES.ADMIN);

/**
 * Project owner only middleware
 */
export const projectOwnerOnly = authorize(USER_ROLES.PROJECT_OWNER);

/**
 * Project owner or admin middleware
 */
export const projectOwnerOrAdmin = authorize(
  USER_ROLES.PROJECT_OWNER,
  USER_ROLES.ADMIN
);

/**
 * Check if user owns the resource
 */
export const requireOwnership = (
  getResourceOwnerId: (req: Request) => Promise<number | null>
) => {
  return async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    if (!req.user) {
      sendUnauthorized(res, 'Authentication required');
      return;
    }

    // Admins can access any resource
    if (req.user.isAdmin()) {
      next();
      return;
    }

    const ownerId = await getResourceOwnerId(req);
    if (ownerId === null) {
      sendForbidden(res, 'Resource not found');
      return;
    }

    if (req.user.id !== ownerId) {
      sendForbidden(res, 'You do not own this resource');
      return;
    }

    next();
  };
};
