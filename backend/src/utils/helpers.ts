import { Request, Response, NextFunction } from 'express';
import { ERROR_CODES } from '../config/constants';

/**
 * Async handler wrapper to catch errors in async route handlers
 */
export const asyncHandler = (
  fn: (req: Request, res: Response, next: NextFunction) => Promise<unknown>
) => {
  return (req: Request, res: Response, next: NextFunction): void => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};

// API Response Types
interface SuccessResponse<T> {
  success: true;
  data: T;
  message?: string;
}

interface ErrorResponse {
  success: false;
  error: {
    code: string;
    message: string;
    details?: unknown;
  };
}

interface PaginatedResponse<T> extends SuccessResponse<T> {
  pagination: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
    hasMore: boolean;
  };
}

/**
 * Send success response
 */
export const sendSuccess = <T>(
  res: Response,
  data: T,
  message?: string,
  statusCode: number = 200
): Response => {
  const response: SuccessResponse<T> = {
    success: true,
    data,
    ...(message ? { message } : {}),
  };
  return res.status(statusCode).json(response);
};

/**
 * Send error response
 */
export const sendError = (
  res: Response,
  code: string,
  message: string,
  statusCode: number = 400,
  details?: unknown
): Response => {
  const response: ErrorResponse = {
    success: false,
    error: {
      code,
      message,
      ...(details !== undefined ? { details } : {}),
    },
  };
  return res.status(statusCode).json(response);
};

/**
 * Send paginated response
 */
export const sendPaginated = <T>(
  res: Response,
  data: T,
  pagination: {
    page: number;
    limit: number;
    total: number;
  }
): Response => {
  const totalPages = Math.ceil(pagination.total / pagination.limit);
  const response: PaginatedResponse<T> = {
    success: true,
    data,
    pagination: {
      ...pagination,
      totalPages,
      hasMore: pagination.page < totalPages,
    },
  };
  return res.status(200).json(response);
};

/**
 * Send validation error
 */
export const sendValidationError = (
  res: Response,
  errors: Array<{ field: string; message: string }>
): Response => {
  return sendError(
    res,
    ERROR_CODES.VALIDATION_ERROR,
    'Validation failed',
    400,
    errors
  );
};

/**
 * Send unauthorized error
 */
export const sendUnauthorized = (
  res: Response,
  message: string = 'Unauthorized'
): Response => {
  return sendError(res, ERROR_CODES.AUTHENTICATION_ERROR, message, 401);
};

/**
 * Send forbidden error
 */
export const sendForbidden = (
  res: Response,
  message: string = 'Access denied'
): Response => {
  return sendError(res, ERROR_CODES.AUTHORIZATION_ERROR, message, 403);
};

/**
 * Send not found error
 */
export const sendNotFound = (
  res: Response,
  resource: string = 'Resource'
): Response => {
  return sendError(res, ERROR_CODES.NOT_FOUND, `${resource} not found`, 404);
};

/**
 * Send conflict error
 */
export const sendConflict = (res: Response, message: string): Response => {
  return sendError(res, ERROR_CODES.CONFLICT, message, 409);
};

/**
 * Extract pagination parameters from query
 */
export const getPaginationParams = (query: {
  page?: string;
  limit?: string;
}): { page: number; limit: number; offset: number } => {
  const page = Math.max(1, parseInt(query.page || '1'));
  const limit = Math.min(100, Math.max(1, parseInt(query.limit || '20')));
  const offset = (page - 1) * limit;
  return { page, limit, offset };
};

/**
 * Get pagination object from page/limit numbers
 */
export const getPagination = (
  page: number,
  limit: number
): { page: number; limit: number; offset: number } => {
  const validPage = Math.max(1, page);
  const validLimit = Math.min(100, Math.max(1, limit));
  const offset = (validPage - 1) * validLimit;
  return { page: validPage, limit: validLimit, offset };
};

/**
 * Sanitize user object for response (remove sensitive fields)
 */
export const sanitizeUser = (user: {
  id: number;
  email: string;
  fullName: string;
  phone?: string | null;
  avatarUrl?: string | null;
  role: string;
  language: string;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
  [key: string]: unknown;
}) => {
  const { passwordHash, refreshToken, ...safeUser } = user as {
    passwordHash?: string;
    refreshToken?: string;
    [key: string]: unknown;
  };
  return safeUser;
};

/**
 * Generate a random string
 */
export const generateRandomString = (length: number = 32): string => {
  const chars =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  let result = '';
  for (let i = 0; i < length; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
};

/**
 * Sleep utility for async operations
 */
export const sleep = (ms: number): Promise<void> => {
  return new Promise((resolve) => setTimeout(resolve, ms));
};
