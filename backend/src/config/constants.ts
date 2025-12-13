// Application constants
export const APP_NAME = 'Sinaa';
export const API_VERSION = 'v1';
export const API_PREFIX = `/api/${API_VERSION}`;

// User roles
export const USER_ROLES = {
  CUSTOMER: 'customer',
  PROJECT_OWNER: 'project_owner',
  ADMIN: 'admin',
} as const;

export type UserRole = (typeof USER_ROLES)[keyof typeof USER_ROLES];

// Status enums
export const PROJECT_STATUS = {
  PENDING: 'pending',
  APPROVED: 'approved',
  REJECTED: 'rejected',
  DISABLED: 'disabled',
} as const;

export const PRODUCT_STATUS = {
  PENDING: 'pending',
  APPROVED: 'approved',
  REJECTED: 'rejected',
} as const;

export const TRANSACTION_STATUS = {
  PENDING: 'pending',
  CONFIRMED: 'confirmed',
  DISPUTED: 'disputed',
  CANCELLED: 'cancelled',
} as const;

export const TICKET_STATUS = {
  OPEN: 'open',
  IN_PROGRESS: 'in_progress',
  RESOLVED: 'resolved',
  CLOSED: 'closed',
} as const;

export const TICKET_TYPES = {
  GENERAL: 'general',
  DISPUTE: 'dispute',
  REPORT: 'report',
  FEEDBACK: 'feedback',
} as const;

// Languages
export const LANGUAGES = {
  ARABIC: 'ar',
  ENGLISH: 'en',
} as const;

// Pagination defaults
export const PAGINATION = {
  DEFAULT_PAGE: 1,
  DEFAULT_LIMIT: 20,
  MAX_LIMIT: 100,
} as const;

// JWT
export const JWT_CONFIG = {
  ACCESS_TOKEN_EXPIRES: process.env.JWT_EXPIRES_IN || '15m',
  REFRESH_TOKEN_EXPIRES: process.env.JWT_REFRESH_EXPIRES_IN || '7d',
} as const;

// File upload
export const FILE_UPLOAD = {
  MAX_SIZE: parseInt(process.env.MAX_FILE_SIZE || '5242880'), // 5MB
  ALLOWED_TYPES: ['image/jpeg', 'image/png', 'image/gif', 'image/webp'],
  MAX_PRODUCT_IMAGES: 4,
} as const;

// Error codes
export const ERROR_CODES = {
  VALIDATION_ERROR: 'VALIDATION_ERROR',
  AUTHENTICATION_ERROR: 'AUTHENTICATION_ERROR',
  AUTHORIZATION_ERROR: 'AUTHORIZATION_ERROR',
  NOT_FOUND: 'NOT_FOUND',
  CONFLICT: 'CONFLICT',
  INTERNAL_ERROR: 'INTERNAL_ERROR',
  BAD_REQUEST: 'BAD_REQUEST',
} as const;
