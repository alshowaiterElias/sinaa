import { Request, Response } from 'express';
import { User } from '../models';
import {
    sendSuccess,
    sendError,
    sendNotFound,
} from '../utils/helpers';
import { isValidLatitude, isValidLongitude } from '../utils/geo';

/**
 * Get current user profile
 */
export const getMe = async (req: Request, res: Response) => {
    const userId = req.user!.id;

    const user = await User.findByPk(userId);

    if (!user) {
        return sendNotFound(res, 'User');
    }

    return sendSuccess(res, user.toSafeJSON());
};

/**
 * Update current user's location
 * 
 * Body: { city: string, latitude?: number, longitude?: number }
 */
export const updateLocation = async (req: Request, res: Response) => {
    const userId = req.user!.id;
    const { city, latitude, longitude, locationSharingEnabled } = req.body;

    const user = await User.findByPk(userId);

    if (!user) {
        return sendNotFound(res, 'User');
    }

    // Validate city is provided
    if (!city || typeof city !== 'string' || city.trim().length === 0) {
        return sendError(res, 'VALIDATION_ERROR', 'City is required', 400);
    }

    // Build update object
    const updateData: {
        city: string;
        latitude?: number | null;
        longitude?: number | null;
        locationSharingEnabled?: boolean;
        locationUpdatedAt: Date;
    } = {
        city: city.trim(),
        locationUpdatedAt: new Date(),
    };

    // Validate and add coordinates if provided
    if (latitude !== undefined && longitude !== undefined) {
        const lat = parseFloat(latitude);
        const lon = parseFloat(longitude);

        if (!isValidLatitude(lat)) {
            return sendError(res, 'VALIDATION_ERROR', 'Invalid latitude. Must be between -90 and 90.', 400);
        }

        if (!isValidLongitude(lon)) {
            return sendError(res, 'VALIDATION_ERROR', 'Invalid longitude. Must be between -180 and 180.', 400);
        }

        updateData.latitude = lat;
        updateData.longitude = lon;
    } else if (latitude !== undefined || longitude !== undefined) {
        // If only one is provided, that's an error
        return sendError(res, 'VALIDATION_ERROR', 'Both latitude and longitude must be provided together', 400);
    }

    // Handle location sharing preference
    if (locationSharingEnabled !== undefined) {
        updateData.locationSharingEnabled = Boolean(locationSharingEnabled);
    }

    await user.update(updateData);

    return sendSuccess(res, user.toSafeJSON(), 'Location updated successfully');
};

/**
 * Update current user profile
 * 
 * Body: { fullName?, phone?, avatarUrl?, language?, city?, latitude?, longitude?, locationSharingEnabled? }
 */
export const updateProfile = async (req: Request, res: Response) => {
    const userId = req.user!.id;
    const { fullName, phone, avatarUrl, language, city, latitude, longitude, locationSharingEnabled } = req.body;

    const user = await User.findByPk(userId);

    if (!user) {
        return sendNotFound(res, 'User');
    }

    // Build update object with only allowed fields
    const updates: Partial<{
        fullName: string;
        phone: string | null;
        avatarUrl: string | null;
        language: 'ar' | 'en';
        city: string | null;
        latitude: number | null;
        longitude: number | null;
        locationSharingEnabled: boolean;
        notificationsEnabled: boolean;
        locationUpdatedAt: Date | null;
    }> = {};

    if (fullName !== undefined) {
        if (typeof fullName !== 'string' || fullName.trim().length < 2) {
            return sendError(res, 'VALIDATION_ERROR', 'Full name must be at least 2 characters', 400);
        }
        updates.fullName = fullName.trim();
    }

    if (phone !== undefined) {
        updates.phone = phone ? phone.trim() : null;
    }

    if (avatarUrl !== undefined) {
        updates.avatarUrl = avatarUrl ? avatarUrl.trim() : null;
    }

    if (language !== undefined) {
        if (!['ar', 'en'].includes(language)) {
            return sendError(res, 'VALIDATION_ERROR', 'Language must be "ar" or "en"', 400);
        }
        updates.language = language;
    }

    // Handle location fields
    if (city !== undefined) {
        updates.city = city ? city.trim() : null;
    }

    if (latitude !== undefined && longitude !== undefined) {
        const parsedLat = parseFloat(latitude);
        const parsedLon = parseFloat(longitude);
        if (!isNaN(parsedLat) && !isNaN(parsedLon)) {
            updates.latitude = parsedLat;
            updates.longitude = parsedLon;
            updates.locationUpdatedAt = new Date();
        }
    }

    if (locationSharingEnabled !== undefined) {
        updates.locationSharingEnabled = Boolean(locationSharingEnabled);
    }

    if (req.body.notificationsEnabled !== undefined) {
        console.log('Updating notificationsEnabled:', req.body.notificationsEnabled, 'Type:', typeof req.body.notificationsEnabled);
        updates.notificationsEnabled = Boolean(req.body.notificationsEnabled);
    }

    console.log('Updates object:', JSON.stringify(updates));

    if (Object.keys(updates).length === 0) {
        return sendError(res, 'VALIDATION_ERROR', 'No valid fields to update', 400);
    }

    // await user.update(updates);
    user.set(updates);
    // DEBUG: Force set to false to test persistence
    if (req.body.notificationsEnabled !== undefined) {
        user.notificationsEnabled = Boolean(req.body.notificationsEnabled);
        console.log('Forced notificationsEnabled to:', user.notificationsEnabled);
    }

    console.log('Updates applied:', JSON.stringify(updates));
    console.log('User changed fields:', user.changed());
    console.log('Value before save:', user.notificationsEnabled);
    await user.save();
    await user.reload();
    console.log('User updated & reloaded. New notificationsEnabled:', user.notificationsEnabled);

    return sendSuccess(res, { user: user.toSafeJSON() }, 'Profile updated successfully');
};

/**
 * Update location sharing preference
 */
export const updateLocationSharing = async (req: Request, res: Response) => {
    const userId = req.user!.id;
    const { enabled } = req.body;

    if (typeof enabled !== 'boolean') {
        return sendError(res, 'VALIDATION_ERROR', 'enabled must be a boolean', 400);
    }

    const user = await User.findByPk(userId);

    if (!user) {
        return sendNotFound(res, 'User');
    }

    await user.update({ locationSharingEnabled: enabled });

    return sendSuccess(res, user.toSafeJSON(),
        enabled ? 'Location sharing enabled' : 'Location sharing disabled'
    );
};
