import { Router } from 'express';
import { authenticate, adminOnly } from '../middleware/auth';
import * as adminSupportController from '../controllers/admin.support.controller';

const router = Router();

// All routes require authentication and admin role
router.use(authenticate, adminOnly);

// Get all tickets
router.get('/tickets', adminSupportController.getAllTickets);

// Get single ticket
router.get('/tickets/:id', adminSupportController.getTicketById);

// Update ticket status
router.put('/tickets/:id/status', adminSupportController.updateTicketStatus);

// Assign ticket to admin
router.put('/tickets/:id/assign', adminSupportController.assignTicket);

// Resolve ticket
router.put('/tickets/:id/resolve', adminSupportController.resolveTicket);

export default router;
