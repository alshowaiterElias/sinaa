import { Request, Response } from 'express';
import { Op } from 'sequelize';
import { User } from '../models';

export const getUsers = async (req: Request, res: Response) => {
    try {
        const page = parseInt(req.query.page as string) || 1;
        const limit = parseInt(req.query.limit as string) || 10;
        const search = req.query.search as string;
        const role = req.query.role as string;
        const status = req.query.status as string;

        const offset = (page - 1) * limit;
        const where: any = {};

        if (search) {
            where[Op.or] = [
                { fullName: { [Op.like]: `%${search}%` } },
                { email: { [Op.like]: `%${search}%` } },
                { phone: { [Op.like]: `%${search}%` } },
            ];
        }

        if (role && role !== 'all') {
            where.role = role;
        }

        if (status && status !== 'all') {
            if (status === 'active') {
                where.isActive = true;
                where.isBanned = false;
            } else if (status === 'banned') {
                where.isBanned = true;
            } else if (status === 'inactive') {
                where.isActive = false;
            }
        }

        const { count, rows } = await User.findAndCountAll({
            where,
            limit,
            offset,
            order: [['createdAt', 'DESC']],
            attributes: { exclude: ['password'] },
        });

        res.json({
            users: rows,
            total: count,
            page,
            totalPages: Math.ceil(count / limit),
        });
    } catch (error) {
        console.error('Get users error:', error);
        res.status(500).json({ message: 'Failed to fetch users' });
    }
};

export const toggleUserBan = async (req: Request, res: Response) => {
    try {
        const { id } = req.params;
        const user = await User.findByPk(id);

        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        // Toggle ban status
        const isBanned = !user.isBanned;
        await user.update({
            isBanned,
            isActive: !isBanned, // If banned, inactive. If unbanned, active.
            banReason: isBanned ? 'Banned by admin' : null,
        });

        res.json({
            message: isBanned ? 'User banned successfully' : 'User unbanned successfully',
            user: {
                id: user.id,
                isBanned: user.isBanned,
                isActive: user.isActive,
            },
        });
    } catch (error) {
        console.error('Toggle user ban error:', error);
        res.status(500).json({ message: 'Failed to update user status' });
    }
};

/**
 * Create a new admin account
 */
export const createAdmin = async (req: Request, res: Response) => {
    try {
        const { email, password, fullName } = req.body;

        if (!email || !password || !fullName) {
            return res.status(400).json({ message: 'Email, password and full name are required' });
        }

        // Check if email already exists
        const existingUser = await User.findOne({ where: { email } });
        if (existingUser) {
            return res.status(409).json({ message: 'Email already registered' });
        }

        // Hash password
        const { hashPassword } = await import('../utils/password');
        const passwordHash = await hashPassword(password);

        // Create admin user (pre-verified)
        const user = await User.create({
            email,
            passwordHash,
            fullName,
            role: 'admin' as any,
            isVerified: true,
            isActive: true,
        });

        res.status(201).json({
            message: 'Admin account created successfully',
            user: {
                id: user.id,
                email: user.email,
                fullName: user.fullName,
                role: user.role,
            },
        });
    } catch (error) {
        console.error('Create admin error:', error);
        res.status(500).json({ message: 'Failed to create admin account' });
    }
};
