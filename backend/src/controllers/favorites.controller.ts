import { Request, Response, NextFunction } from 'express';
import { UserFavorite, Project, User } from '../models';
import { AppError } from '../middleware/errorHandler';

/**
 * Add a project to user's favorites
 * POST /favorites/:projectId
 */
export const addFavorite = async (
    req: Request,
    res: Response,
    next: NextFunction
) => {
    try {
        const userId = req.user!.id;
        const projectId = parseInt(req.params.projectId, 10);

        // Check if project exists and is approved
        const project = await Project.findByPk(projectId);
        if (!project) {
            throw new AppError('Project not found', 404, 'PROJECT_NOT_FOUND');
        }

        if (project.status !== 'approved') {
            throw new AppError('Cannot favorite unapproved project', 400, 'PROJECT_NOT_APPROVED');
        }

        // Check if already favorited
        const existing = await UserFavorite.findOne({
            where: { userId, projectId },
        });

        if (existing) {
            throw new AppError('Project already in favorites', 400, 'ALREADY_FAVORITED');
        }

        // Create favorite
        const favorite = await UserFavorite.create({ userId, projectId });

        res.status(201).json({
            success: true,
            message: 'Project added to favorites',
            data: { id: favorite.id, projectId },
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Remove a project from user's favorites
 * DELETE /favorites/:projectId
 */
export const removeFavorite = async (
    req: Request,
    res: Response,
    next: NextFunction
) => {
    try {
        const userId = req.user!.id;
        const projectId = parseInt(req.params.projectId, 10);

        const deleted = await UserFavorite.destroy({
            where: { userId, projectId },
        });

        if (!deleted) {
            throw new AppError('Favorite not found', 404, 'FAVORITE_NOT_FOUND');
        }

        res.json({
            success: true,
            message: 'Project removed from favorites',
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Get user's favorite projects
 * GET /favorites
 */
export const getMyFavorites = async (
    req: Request,
    res: Response,
    next: NextFunction
) => {
    try {
        const userId = req.user!.id;
        const page = parseInt(req.query.page as string, 10) || 1;
        const limit = parseInt(req.query.limit as string, 10) || 20;
        const offset = (page - 1) * limit;

        const { count, rows } = await UserFavorite.findAndCountAll({
            where: { userId },
            include: [
                {
                    model: Project,
                    as: 'project',
                    include: [
                        {
                            model: User,
                            as: 'owner',
                            attributes: ['id', 'fullName', 'avatarUrl'],
                        },
                    ],
                },
            ],
            limit,
            offset,
            order: [['createdAt', 'DESC']],
        });

        res.json({
            success: true,
            data: {
                favorites: rows.map((fav) => ({
                    id: fav.id,
                    project: fav.project,
                    createdAt: fav.createdAt,
                })),
                pagination: {
                    page,
                    limit,
                    total: count,
                    totalPages: Math.ceil(count / limit),
                },
            },
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Check if a project is in user's favorites
 * GET /favorites/:projectId/check
 */
export const checkFavorite = async (
    req: Request,
    res: Response,
    next: NextFunction
) => {
    try {
        const userId = req.user!.id;
        const projectId = parseInt(req.params.projectId, 10);

        const favorite = await UserFavorite.findOne({
            where: { userId, projectId },
        });

        res.json({
            success: true,
            data: {
                isFavorite: !!favorite,
            },
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Toggle favorite status (convenience endpoint)
 * POST /favorites/:projectId/toggle
 */
export const toggleFavorite = async (
    req: Request,
    res: Response,
    next: NextFunction
) => {
    try {
        const userId = req.user!.id;
        const projectId = parseInt(req.params.projectId, 10);

        // Check if project exists
        const project = await Project.findByPk(projectId);
        if (!project) {
            throw new AppError('Project not found', 404, 'PROJECT_NOT_FOUND');
        }

        // Check current status
        const existing = await UserFavorite.findOne({
            where: { userId, projectId },
        });

        if (existing) {
            // Remove from favorites
            await existing.destroy();
            res.json({
                success: true,
                message: 'Project removed from favorites',
                data: { isFavorite: false },
            });
        } else {
            // Add to favorites
            if (project.status !== 'approved') {
                throw new AppError('Cannot favorite unapproved project', 400, 'PROJECT_NOT_APPROVED');
            }
            await UserFavorite.create({ userId, projectId });
            res.json({
                success: true,
                message: 'Project added to favorites',
                data: { isFavorite: true },
            });
        }
    } catch (error) {
        next(error);
    }
};
