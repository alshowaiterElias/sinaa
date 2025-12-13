import request from 'supertest';
import { Application } from 'express';
import {
  createTestApp,
  createTestUserData,
  createTestProjectOwnerData,
  getTokenFromResponse,
  authHeader,
  generateTestEmail,
} from './helpers';
import { sequelize } from '../src/config/database';
import { User, Project } from '../src/models';
import { hashPassword } from '../src/utils/password';

const API_PREFIX = '/api/v1';
let app: Application;

beforeAll(async () => {
  app = createTestApp();
  // Sync database for tests (create tables)
  await sequelize.sync({ force: true });
});

afterAll(async () => {
  await sequelize.close();
});

beforeEach(async () => {
  // Clear data before each test - order matters for foreign keys
  await Project.destroy({ where: {}, truncate: true, cascade: true });
  await User.destroy({ where: {}, truncate: true, cascade: true });
});

describe('Auth API', () => {
  // ==================== Registration Tests ====================
  describe('POST /auth/register', () => {
    it('should register a new customer successfully', async () => {
      const userData = createTestUserData();

      const response = await request(app)
        .post(`${API_PREFIX}/auth/register`)
        .send(userData)
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.data.user).toBeDefined();
      expect(response.body.data.user.email).toBe(userData.email.toLowerCase());
      expect(response.body.data.user.fullName).toBe(userData.fullName);
      expect(response.body.data.user.role).toBe('customer');
      expect(response.body.data.accessToken).toBeDefined();
      expect(response.body.data.refreshToken).toBeDefined();
      // Password should not be returned
      expect(response.body.data.user.passwordHash).toBeUndefined();
    });

    it('should fail registration with existing email', async () => {
      const userData = createTestUserData();

      // First registration
      await request(app)
        .post(`${API_PREFIX}/auth/register`)
        .send(userData)
        .expect(201);

      // Second registration with same email
      const response = await request(app)
        .post(`${API_PREFIX}/auth/register`)
        .send(userData)
        .expect(409);

      expect(response.body.success).toBe(false);
      expect(response.body.error.code).toBe('CONFLICT');
    });

    it('should fail registration with invalid email', async () => {
      const userData = createTestUserData({ email: 'invalid-email' });

      const response = await request(app)
        .post(`${API_PREFIX}/auth/register`)
        .send(userData)
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.error.code).toBe('VALIDATION_ERROR');
    });

    it('should fail registration with weak password', async () => {
      const userData = createTestUserData({ password: '123' });

      const response = await request(app)
        .post(`${API_PREFIX}/auth/register`)
        .send(userData)
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.error.code).toBe('VALIDATION_ERROR');
    });

    it('should fail registration without required fields', async () => {
      const response = await request(app)
        .post(`${API_PREFIX}/auth/register`)
        .send({ email: generateTestEmail() })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.error.code).toBe('VALIDATION_ERROR');
    });
  });

  // ==================== Project Owner Registration Tests ====================
  describe('POST /auth/register/project-owner', () => {
    it('should register a new project owner with project', async () => {
      const userData = createTestProjectOwnerData();

      const response = await request(app)
        .post(`${API_PREFIX}/auth/register/project-owner`)
        .send(userData)
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.data.user.role).toBe('project_owner');
      expect(response.body.data.accessToken).toBeDefined();

      // Verify project was created
      const project = await Project.findOne({
        where: { ownerId: response.body.data.user.id },
      });
      expect(project).not.toBeNull();
      expect(project?.name).toBe(userData.projectName);
      expect(project?.status).toBe('pending');
    });

    it('should fail without project details', async () => {
      const userData = createTestUserData();

      const response = await request(app)
        .post(`${API_PREFIX}/auth/register/project-owner`)
        .send(userData)
        .expect(400);

      expect(response.body.success).toBe(false);
    });
  });

  // ==================== Login Tests ====================
  describe('POST /auth/login', () => {
    let testUser: typeof User.prototype;

    beforeEach(async () => {
      const userData = createTestUserData();
      const response = await request(app)
        .post(`${API_PREFIX}/auth/register`)
        .send(userData);
      testUser = response.body.data.user;
    });

    it('should login successfully with valid credentials', async () => {
      const response = await request(app)
        .post(`${API_PREFIX}/auth/login`)
        .send({
          email: testUser.email,
          password: 'TestPass123',
        })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.user.id).toBe(testUser.id);
      expect(response.body.data.accessToken).toBeDefined();
      expect(response.body.data.refreshToken).toBeDefined();
    });

    it('should fail login with wrong password', async () => {
      const response = await request(app)
        .post(`${API_PREFIX}/auth/login`)
        .send({
          email: testUser.email,
          password: 'WrongPassword123',
        })
        .expect(401);

      expect(response.body.success).toBe(false);
      expect(response.body.error.code).toBe('AUTHENTICATION_ERROR');
    });

    it('should fail login with non-existent email', async () => {
      const response = await request(app)
        .post(`${API_PREFIX}/auth/login`)
        .send({
          email: 'nonexistent@example.com',
          password: 'TestPass123',
        })
        .expect(401);

      expect(response.body.success).toBe(false);
    });

    it('should fail login for banned user', async () => {
      // Ban the user
      await User.update(
        { isBanned: true, banReason: 'Test ban' },
        { where: { id: testUser.id } }
      );

      const response = await request(app)
        .post(`${API_PREFIX}/auth/login`)
        .send({
          email: testUser.email,
          password: 'TestPass123',
        })
        .expect(403);

      expect(response.body.success).toBe(false);
      expect(response.body.error.message).toContain('banned');
    });
  });

  // ==================== Get Profile Tests ====================
  describe('GET /auth/me', () => {
    let accessToken: string;

    beforeEach(async () => {
      const userData = createTestUserData();
      const response = await request(app)
        .post(`${API_PREFIX}/auth/register`)
        .send(userData);
      accessToken = getTokenFromResponse(response);
    });

    it('should return current user profile', async () => {
      const response = await request(app)
        .get(`${API_PREFIX}/auth/me`)
        .set(authHeader(accessToken))
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.user).toBeDefined();
      expect(response.body.data.user.passwordHash).toBeUndefined();
    });

    it('should fail without authorization token', async () => {
      const response = await request(app)
        .get(`${API_PREFIX}/auth/me`)
        .expect(401);

      expect(response.body.success).toBe(false);
    });

    it('should fail with invalid token', async () => {
      const response = await request(app)
        .get(`${API_PREFIX}/auth/me`)
        .set(authHeader('invalid-token'))
        .expect(401);

      expect(response.body.success).toBe(false);
    });
  });

  // ==================== Update Profile Tests ====================
  describe('PUT /auth/me', () => {
    let accessToken: string;

    beforeEach(async () => {
      const userData = createTestUserData();
      const response = await request(app)
        .post(`${API_PREFIX}/auth/register`)
        .send(userData);
      accessToken = getTokenFromResponse(response);
    });

    it('should update user profile', async () => {
      const updateData = {
        fullName: 'Updated Name',
        language: 'en',
      };

      const response = await request(app)
        .put(`${API_PREFIX}/auth/me`)
        .set(authHeader(accessToken))
        .send(updateData)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.user.fullName).toBe(updateData.fullName);
      expect(response.body.data.user.language).toBe(updateData.language);
    });

    it('should fail update with invalid phone format', async () => {
      const response = await request(app)
        .put(`${API_PREFIX}/auth/me`)
        .set(authHeader(accessToken))
        .send({ phone: 'invalid-phone' })
        .expect(400);

      expect(response.body.success).toBe(false);
    });
  });

  // ==================== Logout Tests ====================
  describe('POST /auth/logout', () => {
    let accessToken: string;

    beforeEach(async () => {
      const userData = createTestUserData();
      const response = await request(app)
        .post(`${API_PREFIX}/auth/register`)
        .send(userData);
      accessToken = getTokenFromResponse(response);
    });

    it('should logout successfully', async () => {
      const response = await request(app)
        .post(`${API_PREFIX}/auth/logout`)
        .set(authHeader(accessToken))
        .expect(200);

      expect(response.body.success).toBe(true);
    });

    it('should fail logout without token', async () => {
      const response = await request(app)
        .post(`${API_PREFIX}/auth/logout`)
        .expect(401);

      expect(response.body.success).toBe(false);
    });
  });

  // ==================== Refresh Token Tests ====================
  describe('POST /auth/refresh', () => {
    let refreshToken: string;

    beforeEach(async () => {
      const userData = createTestUserData();
      const response = await request(app)
        .post(`${API_PREFIX}/auth/register`)
        .send(userData);
      refreshToken = response.body.data.refreshToken;
    });

    it('should refresh tokens successfully', async () => {
      const response = await request(app)
        .post(`${API_PREFIX}/auth/refresh`)
        .send({ refreshToken })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.accessToken).toBeDefined();
      expect(response.body.data.refreshToken).toBeDefined();
      // New refresh token should be different
      expect(response.body.data.refreshToken).not.toBe(refreshToken);
    });

    it('should fail with invalid refresh token', async () => {
      const response = await request(app)
        .post(`${API_PREFIX}/auth/refresh`)
        .send({ refreshToken: 'invalid-token' })
        .expect(401);

      expect(response.body.success).toBe(false);
    });
  });

  // ==================== Change Password Tests ====================
  describe('PUT /auth/change-password', () => {
    let accessToken: string;

    beforeEach(async () => {
      const userData = createTestUserData();
      const response = await request(app)
        .post(`${API_PREFIX}/auth/register`)
        .send(userData);
      accessToken = getTokenFromResponse(response);
    });

    it('should change password successfully', async () => {
      const response = await request(app)
        .put(`${API_PREFIX}/auth/change-password`)
        .set(authHeader(accessToken))
        .send({
          currentPassword: 'TestPass123',
          password: 'NewTestPass456',
        })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.accessToken).toBeDefined();
    });

    it('should fail with wrong current password', async () => {
      const response = await request(app)
        .put(`${API_PREFIX}/auth/change-password`)
        .set(authHeader(accessToken))
        .send({
          currentPassword: 'WrongPassword',
          password: 'NewTestPass456',
        })
        .expect(400);

      expect(response.body.success).toBe(false);
    });

    it('should fail with weak new password', async () => {
      const response = await request(app)
        .put(`${API_PREFIX}/auth/change-password`)
        .set(authHeader(accessToken))
        .send({
          currentPassword: 'TestPass123',
          password: '123',
        })
        .expect(400);

      expect(response.body.success).toBe(false);
    });
  });

  // ==================== Forgot Password Tests ====================
  describe('POST /auth/forgot-password', () => {
    it('should return success for existing email', async () => {
      const userData = createTestUserData();
      await request(app)
        .post(`${API_PREFIX}/auth/register`)
        .send(userData);

      const response = await request(app)
        .post(`${API_PREFIX}/auth/forgot-password`)
        .send({ email: userData.email })
        .expect(200);

      expect(response.body.success).toBe(true);
    });

    it('should return success for non-existing email (prevent enumeration)', async () => {
      const response = await request(app)
        .post(`${API_PREFIX}/auth/forgot-password`)
        .send({ email: 'nonexistent@example.com' })
        .expect(200);

      expect(response.body.success).toBe(true);
    });
  });

  // ==================== Reset Password Tests ====================
  describe('POST /auth/reset-password', () => {
    it('should reject invalid reset token', async () => {
      const response = await request(app)
        .post(`${API_PREFIX}/auth/reset-password`)
        .send({
          token: 'invalid-token',
          password: 'NewPassword123',
        })
        .expect(501); // Not implemented yet

      expect(response.body.success).toBe(false);
    });

    it('should fail with weak new password', async () => {
      const response = await request(app)
        .post(`${API_PREFIX}/auth/reset-password`)
        .send({
          token: 'some-token',
          password: '123', // Weak password
        })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.error.code).toBe('VALIDATION_ERROR');
    });

    it('should fail without token', async () => {
      const response = await request(app)
        .post(`${API_PREFIX}/auth/reset-password`)
        .send({
          password: 'NewPassword123',
        })
        .expect(400);

      expect(response.body.success).toBe(false);
    });

    it('should fail without password', async () => {
      const response = await request(app)
        .post(`${API_PREFIX}/auth/reset-password`)
        .send({
          token: 'some-token',
        })
        .expect(400);

      expect(response.body.success).toBe(false);
    });
  });

  // ==================== Admin Login Tests ====================
  describe('POST /auth/admin/login', () => {
    it('should login admin successfully', async () => {
      // Create admin user
      const passwordHash = await hashPassword('AdminPass123');
      await User.create({
        email: 'admin@test.com',
        passwordHash,
        fullName: 'Test Admin',
        role: 'admin',
      });

      const response = await request(app)
        .post(`${API_PREFIX}/auth/admin/login`)
        .send({
          email: 'admin@test.com',
          password: 'AdminPass123',
        })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.user.role).toBe('admin');
    });

    it('should reject non-admin login at admin endpoint', async () => {
      const userData = createTestUserData();
      await request(app)
        .post(`${API_PREFIX}/auth/register`)
        .send(userData);

      const response = await request(app)
        .post(`${API_PREFIX}/auth/admin/login`)
        .send({
          email: userData.email,
          password: 'TestPass123',
        })
        .expect(401);

      expect(response.body.success).toBe(false);
    });
  });
});

