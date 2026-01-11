import { Router } from 'express';
import authRoutes from './auth.routes';
import categoriesRoutes from './categories.routes';
import adminRoutes from './admin.routes';
import projectRoutes from './projects.routes';
import adminProjectRoutes from './admin.projects.routes';
import productRoutes from './products.routes';
import adminProductRoutes from './admin.products.routes';
import tagsRoutes from './tags.routes';
import cartRoutes from './cart.routes';
import conversationsRoutes from './conversations.routes';
import notificationsRoutes from './notifications.routes';
import supportRoutes from './support.routes';
import adminSupportRoutes from './admin.support.routes';
import transactionsRoutes from './transactions.routes';
import reviewsRoutes from './reviews.routes';
import adminReviewsRoutes from './admin.reviews.routes';
import favoritesRoutes from './favorites.routes';
import usersRoutes from './users.routes';
import { authenticate, adminOnly } from '../middleware/auth';

const router = Router();

// Mount routes
router.use('/auth', authRoutes);
router.use('/users', usersRoutes);
router.use('/categories', categoriesRoutes);
router.use('/projects', projectRoutes);
router.use('/products', productRoutes);
router.use('/tags', tagsRoutes);
router.use('/cart', cartRoutes);
router.use('/conversations', conversationsRoutes);
router.use('/notifications', notificationsRoutes);
router.use('/support', supportRoutes);
router.use('/transactions', transactionsRoutes);
router.use('/reviews', reviewsRoutes);
router.use('/favorites', favoritesRoutes);

// Admin routes
router.use('/admin', adminRoutes);
router.use('/admin/projects', authenticate, adminOnly, adminProjectRoutes);
router.use('/admin/products', authenticate, adminOnly, adminProductRoutes);
router.use('/admin/reviews', adminReviewsRoutes);
router.use('/admin/support', adminSupportRoutes);

// Health check endpoint
router.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
  });
});

export default router;
