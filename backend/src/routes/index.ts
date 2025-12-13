import { Router } from 'express';
import authRoutes from './auth.routes';
import categoriesRoutes from './categories.routes';
import adminRoutes from './admin.routes';
import projectRoutes from './projects.routes';
import adminProjectRoutes from './admin.projects.routes';
import { authenticate, adminOnly } from '../middleware/auth';

const router = Router();

// Mount routes
router.use('/auth', authRoutes);
router.use('/categories', categoriesRoutes);
router.use('/projects', projectRoutes);

// Admin routes
router.use('/admin', adminRoutes);
router.use('/admin/projects', authenticate, adminOnly, adminProjectRoutes);

// Health check endpoint
router.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
  });
});

export default router;
