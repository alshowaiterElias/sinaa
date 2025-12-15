import { Router } from 'express';
import {
    getCart,
    addToCart,
    updateCartItem,
    removeFromCart,
    clearCart,
    getCartCount,
    sendInquiries,
} from '../controllers/cart.controller';
import { authenticate } from '../middleware/auth';

const router = Router();

// All routes require authentication
router.use(authenticate);

// GET /cart - Get user's cart items grouped by project
router.get('/', getCart);

// POST /cart - Add product to cart
router.post('/', addToCart);

// GET /cart/count - Get cart items count
router.get('/count', getCartCount);

// POST /cart/send-inquiries - Send inquiry messages
router.post('/send-inquiries', sendInquiries);

// PUT /cart/:itemId - Update cart item
router.put('/:itemId', updateCartItem);

// DELETE /cart/:itemId - Remove item from cart
router.delete('/:itemId', removeFromCart);

// DELETE /cart - Clear entire cart
router.delete('/', clearCart);

export default router;
