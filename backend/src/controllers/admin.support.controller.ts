import { Request, Response, NextFunction } from 'express';
import { Op } from 'sequelize';
import SupportTicket from '../models/SupportTicket';
import User from '../models/User';
import { sendSuccess, sendError, sendNotFound, sendPaginated, getPaginationParams } from '../utils/helpers';
import { ERROR_CODES } from '../config/constants';

/**
 * Get all support tickets (Admin)
 */
export const getAllTickets = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { page, limit, offset } = getPaginationParams(req.query as { page?: string; limit?: string });
        const { status, type, assignedTo, search } = req.query;

        const where: any = {};

        if (status) {
            where.status = status;
        }

        if (type) {
            where.type = type;
        }

        if (assignedTo) {
            where.assignedTo = assignedTo === 'unassigned' ? null : assignedTo;
        }

        if (search) {
            where[Op.or] = [
                { subject: { [Op.like]: `%${search}%` } },
                { description: { [Op.like]: `%${search}%` } },
            ];
        }

        const { count, rows } = await SupportTicket.findAndCountAll({
            where,
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
 * Get ticket by ID (Admin)
 */
export const getTicketById = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { id } = req.params;

        const ticket = await SupportTicket.findByPk(id, {
            include: [
                {
                    model: User,
                    as: 'user',
                    attributes: ['id', 'fullName', 'avatarUrl', 'email', 'phone'],
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

        return sendSuccess(res, ticket, 'Ticket retrieved successfully');
    } catch (error) {
        next(error);
    }
};

/**
 * Update ticket status (Admin)
 */
export const updateTicketStatus = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { id } = req.params;
        const { status } = req.body;

        if (!status || !['open', 'in_progress', 'resolved', 'closed'].includes(status)) {
            return sendError(res, ERROR_CODES.VALIDATION_ERROR, 'Invalid status', 400);
        }

        const ticket = await SupportTicket.findByPk(id);

        if (!ticket) {
            return sendNotFound(res, 'Ticket');
        }

        await ticket.update({ status });

        await ticket.reload({
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

        return sendSuccess(res, ticket, 'Ticket status updated');
    } catch (error) {
        next(error);
    }
};

/**
 * Assign ticket to admin (Admin)
 */
export const assignTicket = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { id } = req.params;
        const { adminId } = req.body;
        const currentAdminId = req.user!.id;

        const ticket = await SupportTicket.findByPk(id);

        if (!ticket) {
            return sendNotFound(res, 'Ticket');
        }

        // If no adminId provided, assign to self
        const assignTo = adminId || currentAdminId;

        // Verify the assignee is an admin
        const admin = await User.findByPk(assignTo);
        if (!admin || admin.role !== 'admin') {
            return sendError(res, ERROR_CODES.VALIDATION_ERROR, 'Invalid admin user', 400);
        }

        await ticket.update({
            assignedTo: assignTo,
            status: ticket.status === 'open' ? 'in_progress' : ticket.status,
        });

        await ticket.reload({
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

        return sendSuccess(res, ticket, 'Ticket assigned successfully');
    } catch (error) {
        next(error);
    }
};

/**
 * Resolve ticket with resolution notes (Admin)
 */
export const resolveTicket = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { id } = req.params;
        const { resolution } = req.body;

        if (!resolution || resolution.trim().length < 10) {
            return sendError(res, ERROR_CODES.VALIDATION_ERROR, 'Resolution notes must be at least 10 characters', 400);
        }

        const ticket = await SupportTicket.findByPk(id);

        if (!ticket) {
            return sendNotFound(res, 'Ticket');
        }

        await ticket.update({
            resolution: resolution.trim(),
            status: 'resolved',
        });

        await ticket.reload({
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

        return sendSuccess(res, ticket, 'Ticket resolved successfully');
    } catch (error) {
        next(error);
    }
};
