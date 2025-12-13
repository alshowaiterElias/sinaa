import { Request, Response, NextFunction } from 'express';
import { sendError } from '../utils/helpers';
import { ERROR_CODES } from '../config/constants';
import logger from '../utils/logger';

// Custom error class
export class AppError extends Error {
  public statusCode: number;
  public code: string;
  public isOperational: boolean;

  constructor(
    message: string,
    statusCode: number = 500,
    code: string = ERROR_CODES.INTERNAL_ERROR
  ) {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
    this.isOperational = true;

    Error.captureStackTrace(this, this.constructor);
  }
}

// Not found error handler (for undefined routes)
export const notFoundHandler = (
  req: Request,
  res: Response,
  _next: NextFunction
): void => {
  sendError(
    res,
    ERROR_CODES.NOT_FOUND,
    `Route ${req.method} ${req.originalUrl} not found`,
    404
  );
};

// Global error handler
export const errorHandler = (
  err: Error | AppError,
  _req: Request,
  res: Response,
  _next: NextFunction
): void => {
  // Log error
  logger.error('Error occurred:', {
    message: err.message,
    stack: err.stack,
    ...(err instanceof AppError && { code: err.code, statusCode: err.statusCode }),
  });

  // Handle AppError
  if (err instanceof AppError) {
    sendError(res, err.code, err.message, err.statusCode);
    return;
  }

  // Handle Sequelize validation errors
  if (err.name === 'SequelizeValidationError') {
    const validationError = err as { errors?: Array<{ path: string; message: string }> };
    const errors = validationError.errors?.map((e) => ({
      field: e.path,
      message: e.message,
    }));
    sendError(res, ERROR_CODES.VALIDATION_ERROR, 'Validation failed', 400, errors);
    return;
  }

  // Handle Sequelize unique constraint errors
  if (err.name === 'SequelizeUniqueConstraintError') {
    const uniqueError = err as { errors?: Array<{ path: string }> };
    const field = uniqueError.errors?.[0]?.path || 'field';
    sendError(res, ERROR_CODES.CONFLICT, `${field} already exists`, 409);
    return;
  }

  // Handle JWT errors
  if (err.name === 'JsonWebTokenError') {
    sendError(res, ERROR_CODES.AUTHENTICATION_ERROR, 'Invalid token', 401);
    return;
  }

  if (err.name === 'TokenExpiredError') {
    sendError(res, ERROR_CODES.AUTHENTICATION_ERROR, 'Token expired', 401);
    return;
  }

  // Handle syntax errors (malformed JSON)
  if (err instanceof SyntaxError && 'body' in err) {
    sendError(res, ERROR_CODES.BAD_REQUEST, 'Invalid JSON body', 400);
    return;
  }

  // Default error (don't expose details in production)
  const message =
    process.env.NODE_ENV === 'production'
      ? 'An unexpected error occurred'
      : err.message;

  sendError(res, ERROR_CODES.INTERNAL_ERROR, message, 500);
};

// Async handler wrapper to catch async errors
export const asyncHandler = <T>(
  fn: (req: Request, res: Response, next: NextFunction) => Promise<T>
) => {
  return (req: Request, res: Response, next: NextFunction): void => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};
