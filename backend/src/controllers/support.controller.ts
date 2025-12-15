import { Request, Response, NextFunction } from 'express';
import { Op } from 'sequelize';
import SupportTicket from '../models/SupportTicket';
import User from '../models/User';
import { sendSuccess, sendError, sendNotFound, sendPaginated, getPaginationParams } from '../utils/helpers';
import { ERROR_CODES } from '../config/constants';

/**
 * Get user's support tickets
 */
export const getMyTickets = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = req.user!.id;
        const { page, limit, offset } = getPaginationParams(req.query as { page?: string; limit?: string });
        const { status, type } = req.query;

        const where: any = { userId };

        if (status) {
            where.status = status;
        }

        if (type) {
            where.type = type;
        }

        const { count, rows } = await SupportTicket.findAndCountAll({
            where,
            include: [
                {
                    model: User,
                    as: 'assignee',
                    attributes: ['id', 'fullName', 'avatarUrl'],
                },
            ],
            order: [['createdAt', 'DESC']],
            limit,
            offset,
        });

        return sendPaginated(res, rows, {
            page,
            limit,
            total: count,
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Get single ticket by ID
 */
export const getTicketById = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = req.user!.id;
        const { id } = req.params;

        const ticket = await SupportTicket.findByPk(id, {
            include: [
                {
                    model: User,
                    as: 'user',
                    attributes: ['id', 'fullName', 'avatarUrl', 'email'],
                },
                {
                    model: User,
                    as: 'assignee',
                    attributes: ['id', 'fullName', 'avatarUrl'],
                },
            ],
        });

        if (!ticket) {
            return sendNotFound(res, 'Ticket');
        }

        // Check access - user can only view their own tickets
        if (ticket.userId !== userId) {
            return sendError(res, ERROR_CODES.AUTHORIZATION_ERROR, 'Access denied', 403);
        }

        return sendSuccess(res, ticket, 'Ticket retrieved successfully');
    } catch (error) {
        next(error);
    }
};

/**
 * Create a new support ticket
 */
export const createTicket = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = req.user!.id;
        const { type, subject, description, relatedId, relatedType } = req.body;

        // Validation
        if (!type || !['general', 'dispute', 'report', 'feedback'].includes(type)) {
            return sendError(res, ERROR_CODES.VALIDATION_ERROR, 'Invalid ticket type', 400);
        }

        if (!subject || subject.trim().length < 5) {
            return sendError(res, ERROR_CODES.VALIDATION_ERROR, 'Subject must be at least 5 characters', 400);
        }

        if (!description || description.trim().length < 10) {
            return sendError(res, ERROR_CODES.VALIDATION_ERROR, 'Description must be at least 10 characters', 400);
        }

        const ticket = await SupportTicket.create({
            userId,
            type,
            subject: subject.trim(),
            description: description.trim(),
            relatedId: relatedId || null,
            relatedType: relatedType || null,
        });

        await ticket.reload({
            include: [
                {
                    model: User,
                    as: 'user',
                    attributes: ['id', 'fullName', 'avatarUrl', 'email'],
                },
            ],
        });

        return sendSuccess(res, ticket, 'Ticket created successfully', 201);
    } catch (error) {
        next(error);
    }
};
