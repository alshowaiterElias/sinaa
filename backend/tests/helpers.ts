import express, { Application } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import routes from '../src/routes';
import { notFoundHandler, errorHandler } from '../src/middleware/errorHandler';
import { API_PREFIX } from '../src/config/constants';

/**
 * Create a test application instance
 */
export const createTestApp = (): Application => {
  const app = express();

  app.use(helmet());
  app.use(cors());
  app.use(express.json());
  app.use(express.urlencoded({ extended: true }));

  app.use(API_PREFIX, routes);
  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
};

/**
 * Generate random email for testing
 */
export const generateTestEmail = (): string => {
  const random = Math.random().toString(36).substring(7);
  return `test_${random}@example.com`;
};

/**
 * Test user data factory
 */
export const createTestUserData = (overrides = {}) => ({
  email: generateTestEmail(),
  password: 'TestPass123',
  fullName: 'Test User',
  phone: '+966500000001',
  language: 'ar',
  ...overrides,
});

/**
 * Test project owner data factory
 */
export const createTestProjectOwnerData = (overrides = {}) => ({
  ...createTestUserData(),
  projectName: 'Test Project',
  projectNameAr: 'مشروع تجريبي',
  city: 'Riyadh',
  ...overrides,
});

/**
 * Extract access token from response
 */
export const getTokenFromResponse = (response: { body: { data?: { accessToken?: string } } }): string => {
  return response.body?.data?.accessToken || '';
};

/**
 * Create authorization header
 */
export const authHeader = (token: string): { Authorization: string } => ({
  Authorization: `Bearer ${token}`,
});

