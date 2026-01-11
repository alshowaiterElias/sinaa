import { Router } from 'express';
import {
    getMe,
    updateProfile,
    updateLocation,
    updateLocationSharing,
} from '../controllers/user.controller';
import { authenticate } from '../middleware/auth';

const router = Router();

/**
 * @route   GET /users/me
 * @desc    Get current user profile
 * @access  Private
 */
router.get('/me', authenticate, getMe);

/**
 * @route   PUT /users/me
 * @desc    Update current user profile
 * @access  Private
 */
router.put('/me', authenticate, updateProfile);

/**
 * @route   PUT /users/me/location
 * @desc    Update current user's location (city + optional coordinates)
 * @access  Private
 */
router.put('/me/location', authenticate, updateLocation);

/**
 * @route   PUT /users/me/location-sharing
 * @desc    Enable/disable location sharing for nearby features
 * @access  Private
 */
router.put('/me/location-sharing', authenticate, updateLocationSharing);

export default router;
