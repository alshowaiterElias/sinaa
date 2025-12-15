import { Router } from 'express';
import { authenticate } from '../middleware/auth';
import * as supportController from '../controllers/support.controller';

const router = Router();

// All routes require authentication
router.use(authenticate);

// Get user's tickets
router.get('/tickets', supportController.getMyTickets);

// Get single ticket
router.get('/tickets/:id', supportController.getTicketById);

// Create new ticket
router.post('/tickets', supportController.createTicket);

export default router;
