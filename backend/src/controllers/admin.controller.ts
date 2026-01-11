import { Request, Response } from 'express';
import { Op, Sequelize } from 'sequelize';
import {
    User,
    Project,
    Product,
    Transaction,
    SupportTicket,
    Category,
} from '../models';
import { USER_ROLES } from '../config/constants';

export const getDashboardStats = async (req: Request, res: Response) => {
    try {
        const today = new Date();
        const sixMonthsAgo = new Date();
        sixMonthsAgo.setMonth(today.getMonth() - 6);

        // 1. Basic Counts
        const totalUsers = await User.count({ where: { role: USER_ROLES.CUSTOMER } });
        const totalProjects = await Project.count({ where: { status: 'approved' } });
        const totalProducts = await Product.count({ where: { status: 'approved' } });
        const pendingTickets = await SupportTicket.count({ where: { status: 'open' } });

        // 2. Graphs Data

        // A. User Growth (Last 6 months)
        const userGrowth = await User.findAll({
            attributes: [
                [Sequelize.fn('DATE_FORMAT', Sequelize.col('created_at'), '%Y-%m'), 'month'],
                [Sequelize.fn('COUNT', Sequelize.col('id')), 'count'],
            ],
            where: {
                createdAt: { [Op.gte]: sixMonthsAgo },
                role: USER_ROLES.CUSTOMER,
            },
            group: ['month'],
            order: [['month', 'ASC']],
        });

        // B. Product Growth (Last 30 Days)
        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

        const productGrowth = await Product.findAll({
            attributes: [
                // Aliasing as 'month' to match the existing frontend GraphPoint model
                // without needing to run build_runner to rename the field.
                [Sequelize.fn('DATE_FORMAT', Sequelize.col('created_at'), '%Y-%m-%d'), 'month'],
                [Sequelize.fn('COUNT', Sequelize.col('id')), 'count'],
            ],
            where: {
                createdAt: { [Op.gte]: thirtyDaysAgo },
            },
            group: ['month'], // Group by the aliased column name or the expression
            order: [['month', 'ASC']],
        });

        // C. Product Category Distribution
        // Group products by category
        const categoryDistribution = await Product.findAll({
            attributes: [
                [Sequelize.col('category.name'), 'name'],
                [Sequelize.fn('COUNT', Sequelize.col('Product.id')), 'count'],
            ],
            include: [{ model: Category, as: 'category', attributes: [] }],
            where: { status: 'approved' },
            group: ['category.id', 'category.name'],
            limit: 5,
        });

        // 4. Recent Activity (Newest 5 Users)
        const recentUsers = await User.findAll({
            where: { role: USER_ROLES.CUSTOMER },
            limit: 5,
            order: [['createdAt', 'DESC']],
            attributes: ['id', 'fullName', 'email', 'createdAt', 'avatarUrl'],
        });

        res.json({
            counts: {
                users: totalUsers,
                projects: totalProjects,
                products: totalProducts,
                pendingTickets: pendingTickets,
            },
            graphs: {
                userGrowth,
                productGrowth,
                categoryDistribution,
            },
            recentActivity: recentUsers,
        });
    } catch (error) {
        console.error('Dashboard stats error:', error);
        res.status(500).json({ message: 'Failed to fetch dashboard stats' });
    }
};
