import { Router } from 'express';
import { authenticate } from '../middleware/auth';
import {
    initiateTransaction,
    getTransactions,
    getTransactionById,
    acceptOrder,
    markDeliverable,
    receiveOrder,
    openDispute,
    cancelTransaction,
} from '../controllers/transactions.controller';

const router = Router();

// All routes require authentication
router.use(authenticate);

// Transaction routes
router.post('/', initiateTransaction);
router.get('/', getTransactions);
router.get('/:id', getTransactionById);
router.put('/:id/accept', acceptOrder);
router.put('/:id/deliverable', markDeliverable);
router.put('/:id/receive', receiveOrder);
router.put('/:id/cancel', cancelTransaction);
router.post('/:id/dispute', openDispute);

export default router;
