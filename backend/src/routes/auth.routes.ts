import { Router } from 'express';
import {
  register,
  registerProjectOwner,
  login,
  logout,
  refreshToken,
  getMe,
  updateMe,
  changePassword,
  forgotPassword,
  resetPassword,
  adminLogin,
} from '../controllers/auth.controller';
import { authenticate } from '../middleware/auth';
import { validate, authValidations } from '../middleware/validate';

const router = Router();

// Public routes
router.post('/register', validate(authValidations.register), register);
router.post(
  '/register/project-owner',
  validate(authValidations.registerProjectOwner),
  registerProjectOwner
);
router.post('/login', validate(authValidations.login), login);
router.post('/forgot-password', validate(authValidations.forgotPassword), forgotPassword);
router.post('/reset-password', validate(authValidations.resetPassword), resetPassword);
router.post('/refresh', validate(authValidations.refreshToken), refreshToken);

// Admin login (separate endpoint)
router.post('/admin/login', validate(authValidations.login), adminLogin);

// Protected routes (require authentication)
router.post('/logout', authenticate, logout);
router.get('/me', authenticate, getMe);
router.put('/me', authenticate, validate(authValidations.updateProfile), updateMe);
router.put(
  '/change-password',
  authenticate,
  validate(authValidations.changePassword),
  changePassword
);

export default router;
