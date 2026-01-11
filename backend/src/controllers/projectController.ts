import { Request, Response } from 'express';
import { Op } from 'sequelize';
import { Project, User, Product } from '../models';
import { PROJECT_STATUS } from '../config/constants';
import {
    sendSuccess,
    sendError,
    sendNotFound,
    sendForbidden,
    sendPaginated,
    getPaginationParams,
    sendConflict,
} from '../utils/helpers';
import { NotificationTemplates } from '../services/notification.service';
import {
    calculateDistance,
    formatDistance,
    getBoundingBox,
    isValidLatitude,
    isValidLongitude,
    DEFAULT_SEARCH_RADIUS_KM,
    MAX_SEARCH_RADIUS_KM,
} from '../utils/geo';

// ==================== Public/User Endpoints ====================

/**
 * Get all approved projects with pagination, filtering, and optional location-based search
 * 
 * Query params:
 * - city: filter by city name
 * - search: text search in name/description
 * - lat: user latitude (for distance calculation)
 * - lon: user longitude (for distance calculation)
 * - radius: search radius in km (default 50, max 100)
 * - sortBy: 'distance' | 'rating' | 'newest' (default 'rating')
 */
export const getProjects = async (req: Request, res: Response) => {
    const { page, limit, offset } = getPaginationParams(req.query as any);
    const { city, search, lat, lon, radius, sortBy } = req.query;

    const where: any = {
        status: PROJECT_STATUS.APPROVED,
    };

    // City filter
    if (city) {
        where.city = city;
    }

    // Text search filter
    if (search) {
        where[Op.or] = [
            { name: { [Op.like]: `%${search}%` } },
            { nameAr: { [Op.like]: `%${search}%` } },
            { description: { [Op.like]: `%${search}%` } },
            { descriptionAr: { [Op.like]: `%${search}%` } },
        ];
    }

    // Filter by minimum rating
    if (req.query.minRating) {
        where.averageRating = {
            [Op.gte]: Number(req.query.minRating)
        };
    }

    // Exclude own project if user is logged in
    if (req.user) {
        console.log('DEBUG: User is logged in:', req.user.id);
        where.ownerId = {
            [Op.ne]: req.user.id
        };
        console.log('DEBUG: Excluding project with ownerId:', req.user.id);
    } else {
        console.log('DEBUG: User is NOT logged in');
    }

    // Location-based search
    const userLat = lat ? parseFloat(lat as string) : null;
    const userLon = lon ? parseFloat(lon as string) : null;
    const searchRadius = radius
        ? Math.min(Math.max(1, parseInt(radius as string)), MAX_SEARCH_RADIUS_KM)
        : DEFAULT_SEARCH_RADIUS_KM;
    const orderBy = sortBy as string || 'rating';

    // Validate coordinates if provided
    if (userLat !== null || userLon !== null) {
        if (userLat === null || userLon === null) {
            return sendError(res, 'VALIDATION_ERROR', 'Both lat and lon must be provided together', 400);
        }
        if (!isValidLatitude(userLat)) {
            return sendError(res, 'VALIDATION_ERROR', 'Invalid latitude. Must be between -90 and 90.', 400);
        }
        if (!isValidLongitude(userLon)) {
            return sendError(res, 'VALIDATION_ERROR', 'Invalid longitude. Must be between -180 and 180.', 400);
        }

        // Add bounding box filter for initial spatial filtering (optimization)
        const boundingBox = getBoundingBox(userLat, userLon, searchRadius);
        where.latitude = {
            [Op.not]: null,
            [Op.between]: [boundingBox.minLat, boundingBox.maxLat],
        };
        where.longitude = {
            [Op.not]: null,
            [Op.between]: [boundingBox.minLon, boundingBox.maxLon],
        };
    }

    // Determine sort order
    let order: any[] = [['averageRating', 'DESC']];
    if (orderBy === 'newest') {
        order = [['createdAt', 'DESC']];
    }
    // Note: distance sorting is done in-memory after fetching

    // Fetch projects
    const { count, rows } = await Project.findAndCountAll({
        where,
        limit: userLat !== null ? undefined : limit, // Fetch all for distance sorting, then paginate
        offset: userLat !== null ? undefined : offset,
        order,
        include: [
            {
                model: User,
                as: 'owner',
                attributes: ['id', 'fullName', 'avatarUrl'],
            },
        ],
    });

    let projectsWithDistance: Array<any> = rows.map(project => project.toJSON());

    // Calculate distances and filter by radius if location provided
    if (userLat !== null && userLon !== null) {
        projectsWithDistance = projectsWithDistance
            .map(project => {
                if (project.latitude && project.longitude) {
                    const distance = calculateDistance(
                        userLat,
                        userLon,
                        Number(project.latitude),
                        Number(project.longitude)
                    );
                    return { ...project, distance: formatDistance(distance) };
                }
                return { ...project, distance: null };
            })
            .filter(project => {
                // Filter out projects without coordinates or outside radius
                if (project.distance === null) return false;
                return project.distance <= searchRadius;
            });

        // Sort by distance if requested
        if (orderBy === 'distance') {
            projectsWithDistance.sort((a, b) => (a.distance || 0) - (b.distance || 0));
        }

        // Apply pagination manually after filtering
        const totalFiltered = projectsWithDistance.length;
        projectsWithDistance = projectsWithDistance.slice(offset, offset + limit);

        return sendPaginated(res, projectsWithDistance, {
            page,
            limit,
            total: totalFiltered,
        });
    }

    return sendPaginated(res, projectsWithDistance, {
        page,
        limit,
        total: count,
    });
};

/**
 * Get project by ID
 */
export const getProjectById = async (req: Request, res: Response) => {
    const { id } = req.params;

    const project = await Project.findByPk(id, {
        include: [
            {
                model: User,
                as: 'owner',
                attributes: ['id', 'fullName', 'avatarUrl', 'phone', 'email'],
            },
        ],
    });

    if (!project) {
        return sendNotFound(res, 'Project');
    }

    // If project is not approved, only owner or admin can view it
    if (!project.isApproved()) {
        const isOwner = req.user?.id === project.ownerId;
        const isAdmin = req.user?.role === 'admin';

        if (!isOwner && !isAdmin) {
            return sendNotFound(res, 'Project'); // Hide unapproved projects
        }
    }

    return sendSuccess(res, project);
};

/**
 * Get project products
 */
export const getProjectProducts = async (req: Request, res: Response) => {
    const { id } = req.params;
    const { page, limit, offset } = getPaginationParams(req.query as any);

    // Check if project exists
    const project = await Project.findByPk(id);
    if (!project) {
        return sendNotFound(res, 'Project');
    }

    // If project is not approved, only owner or admin can view products
    if (!project.isApproved()) {
        const isOwner = req.user?.id === project.ownerId;
        const isAdmin = req.user?.role === 'admin';

        if (!isOwner && !isAdmin) {
            return sendNotFound(res, 'Project');
        }
    }

    const { count, rows } = await Product.findAndCountAll({
        where: { projectId: id },
        limit,
        offset,
        order: [['createdAt', 'DESC']],
    });

    return sendPaginated(res, rows, {
        page,
        limit,
        total: count,
    });
};

/**
 * Get current user's project
 */
export const getMyProject = async (req: Request, res: Response) => {
    const userId = req.user!.id;

    const project = await Project.findOne({
        where: { ownerId: userId },
    });

    if (!project) {
        return sendNotFound(res, 'Project');
    }

    return sendSuccess(res, project);
};

/**
 * Create a new project
 */
export const createProject = async (req: Request, res: Response) => {
    const userId = req.user!.id;
    const {
        name,
        nameAr,
        description,
        descriptionAr,
        city,
        latitude,
        longitude,
        workingHours,
        socialLinks,
    } = req.body;

    // Check if user already has a project
    const existingProject = await Project.findOne({
        where: { ownerId: userId },
    });

    if (existingProject) {
        return sendConflict(res, 'User already has a project');
    }

    const project = await Project.create({
        ownerId: userId,
        name,
        nameAr,
        description,
        descriptionAr,
        city,
        latitude,
        longitude,
        workingHours,
        socialLinks,
        status: PROJECT_STATUS.PENDING,
    });

    return sendSuccess(res, project, 'Project created successfully', 201);
};

/**
 * Update project details
 */
export const updateProject = async (req: Request, res: Response) => {
    const { id } = req.params;
    const userId = req.user!.id;
    const updates = req.body;

    const project = await Project.findByPk(id);

    if (!project) {
        return sendNotFound(res, 'Project');
    }

    // Check ownership
    if (project.ownerId !== userId && req.user?.role !== 'admin') {
        return sendForbidden(res, 'You do not own this project');
    }

    // Prevent updating status or restricted fields
    delete updates.id;
    delete updates.ownerId;
    delete updates.status;
    delete updates.rejectionReason;
    delete updates.averageRating;
    delete updates.totalReviews;

    // Handle cover image
    if (req.file) {
        updates.coverUrl = `/uploads/projects/${req.file.filename}`;
    }

    // If user is updating project info (not admin), set status back to pending for re-approval
    const isAdmin = req.user?.role === 'admin';
    const hasContentChanges = updates.name || updates.nameAr || updates.description || updates.descriptionAr;

    if (!isAdmin && hasContentChanges && project.status === PROJECT_STATUS.APPROVED) {
        updates.status = PROJECT_STATUS.PENDING;
    }

    await project.update(updates);

    const message = updates.status === PROJECT_STATUS.PENDING
        ? 'Project updated - pending re-approval'
        : 'Project updated successfully';

    return sendSuccess(res, project, message);
};

// ==================== Admin Endpoints ====================

/**
 * Get all projects (Admin)
 */
export const getAllProjects = async (req: Request, res: Response) => {
    const { page, limit, offset } = getPaginationParams(req.query as any);
    const { status, search } = req.query;

    const where: any = {};

    if (status) {
        where.status = status;
    }

    if (search) {
        where[Op.or] = [
            { name: { [Op.like]: `%${search}%` } },
            { nameAr: { [Op.like]: `%${search}%` } },
        ];
    }

    const { count, rows } = await Project.findAndCountAll({
        where,
        limit,
        offset,
        order: [['createdAt', 'DESC']],
        include: [
            {
                model: User,
                as: 'owner',
                attributes: ['id', 'fullName', 'email', 'phone'],
            },
        ],
    });

    return sendPaginated(res, rows, {
        page,
        limit,
        total: count,
    });
};

/**
 * Get pending projects (Admin)
 */
export const getPendingProjects = async (req: Request, res: Response) => {
    const { page, limit, offset } = getPaginationParams(req.query as any);

    const { count, rows } = await Project.findAndCountAll({
        where: { status: PROJECT_STATUS.PENDING },
        limit,
        offset,
        order: [['createdAt', 'ASC']],
        include: [
            {
                model: User,
                as: 'owner',
                attributes: ['id', 'fullName', 'email', 'phone'],
            },
        ],
    });

    return sendPaginated(res, rows, {
        page,
        limit,
        total: count,
    });
};

/**
 * Approve project (Admin)
 */
export const approveProject = async (req: Request, res: Response) => {
    const { id } = req.params;

    const project = await Project.findByPk(id);

    if (!project) {
        return sendNotFound(res, 'Project');
    }

    if (project.isApproved()) {
        return sendConflict(res, 'Project is already approved');
    }

    await project.update({
        status: PROJECT_STATUS.APPROVED,
        rejectionReason: null,
    });

    // Send notification to owner
    NotificationTemplates.projectApproved(
        project.ownerId,
        project.id,
        project.name
    );

    return sendSuccess(res, project, 'Project approved successfully');
};

/**
 * Reject project (Admin)
 */
export const rejectProject = async (req: Request, res: Response) => {
    const { id } = req.params;
    const { reason } = req.body;

    if (!reason) {
        return sendError(res, 'VALIDATION_ERROR', 'Rejection reason is required');
    }

    const project = await Project.findByPk(id);

    if (!project) {
        return sendNotFound(res, 'Project');
    }

    await project.update({
        status: PROJECT_STATUS.REJECTED,
        rejectionReason: reason,
    });

    // Send notification to owner
    NotificationTemplates.projectRejected(
        project.ownerId,
        project.id,
        project.name,
        reason
    );

    return sendSuccess(res, project, 'Project rejected successfully');
};

/**
 * Disable project (Admin)
 */
export const disableProject = async (req: Request, res: Response) => {
    const { id } = req.params;
    const { reason } = req.body;

    if (!reason) {
        return sendError(res, 'VALIDATION_ERROR', 'Disable reason is required');
    }

    const project = await Project.findByPk(id);

    if (!project) {
        return sendNotFound(res, 'Project');
    }

    if (project.status === PROJECT_STATUS.DISABLED) {
        return sendConflict(res, 'Project is already disabled');
    }

    await project.update({
        status: PROJECT_STATUS.DISABLED,
        disableReason: reason,
    });

    // Send notification to owner
    NotificationTemplates.projectDisabled(
        project.ownerId,
        project.id,
        project.name,
        reason
    );

    return sendSuccess(res, project, 'Project disabled successfully');
};

/**
 * Enable project (Admin)
 */
export const enableProject = async (req: Request, res: Response) => {
    const { id } = req.params;

    const project = await Project.findByPk(id);

    if (!project) {
        return sendNotFound(res, 'Project');
    }

    if (project.status !== PROJECT_STATUS.DISABLED) {
        return sendConflict(res, 'Project is not disabled');
    }

    await project.update({
        status: PROJECT_STATUS.APPROVED,
    });

    // Send notification to owner
    NotificationTemplates.projectEnabled(
        project.ownerId,
        project.id,
        project.name
    );

    return sendSuccess(res, project, 'Project enabled successfully');
};

