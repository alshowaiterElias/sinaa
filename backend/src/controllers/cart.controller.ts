import { Request, Response, NextFunction } from 'express';
import { Op } from 'sequelize';
import sequelize from '../config/database';
import { ERROR_CODES } from '../config/constants';
import CartItem from '../models/CartItem';
import Product from '../models/Product';
import ProductVariant from '../models/ProductVariant';
import Project from '../models/Project';
import Conversation from '../models/Conversation';
import Message from '../models/Message';
import { sendSuccess, sendError } from '../utils/helpers';

/**
 * Get user's cart items grouped by project
 */
export const getCart = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = req.user!.id;

        const cartItems = await CartItem.findAll({
            where: { userId },
            include: [
                {
                    model: Product,
                    as: 'product',
                    include: [
                        {
                            model: Project,
                            as: 'project',
                            attributes: ['id', 'name', 'nameAr', 'logoUrl', 'city'],
                        },
                    ],
                },
                {
                    model: ProductVariant,
                    as: 'variant',
                },
            ],
            order: [['createdAt', 'DESC']],
        });

        // Group by project
        const groupedByProject: Record<number, {
            project: any;
            items: typeof cartItems;
        }> = {};

        for (const item of cartItems) {
            const projectId = item.product?.project?.id;
            if (projectId) {
                if (!groupedByProject[projectId]) {
                    groupedByProject[projectId] = {
                        project: item.product!.project,
                        items: [],
                    };
                }
                groupedByProject[projectId].items.push(item);
            }
        }

        const grouped = Object.values(groupedByProject);

        return sendSuccess(res, {
            groups: grouped,
            totalItems: cartItems.length,
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Add product to cart (upsert)
 */
export const addToCart = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = req.user!.id;
        const { productId, variantId, quantity = 1, note } = req.body;

        if (!productId) {
            return sendError(res, ERROR_CODES.VALIDATION_ERROR, 'Product ID is required', 400);
        }

        // Check if product exists and is approved
        const product = await Product.findByPk(productId);
        if (!product) {
            return sendError(res, ERROR_CODES.NOT_FOUND, 'Product not found', 404);
        }
        if (product.status !== 'approved') {
            return sendError(res, ERROR_CODES.VALIDATION_ERROR, 'Product is not available', 400);
        }

        // Check if variant exists if provided
        if (variantId) {
            const variant = await ProductVariant.findOne({
                where: { id: variantId, productId },
            });
            if (!variant) {
                return sendError(res, ERROR_CODES.NOT_FOUND, 'Variant not found', 404);
            }
        }

        // Upsert cart item
        const [cartItem, created] = await CartItem.findOrCreate({
            where: {
                userId,
                productId,
                variantId: variantId || null,
            },
            defaults: {
                userId,
                productId,
                variantId: variantId || null,
                quantity,
                note,
            },
        });

        if (!created) {
            // Update existing item
            cartItem.quantity = quantity;
            if (note !== undefined) cartItem.note = note;
            await cartItem.save();
        }

        // Reload with associations
        await cartItem.reload({
            include: [
                { model: Product, as: 'product' },
                { model: ProductVariant, as: 'variant' },
            ],
        });

        return sendSuccess(res, cartItem, created ? 'Added to cart' : 'Cart updated');
    } catch (error) {
        next(error);
    }
};

/**
 * Update cart item
 */
export const updateCartItem = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = req.user!.id;
        const { itemId } = req.params;
        const { quantity, note } = req.body;

        const cartItem = await CartItem.findOne({
            where: { id: itemId, userId },
        });

        if (!cartItem) {
            return sendError(res, ERROR_CODES.NOT_FOUND, 'Cart item not found', 404);
        }

        if (quantity !== undefined) {
            if (quantity < 1) {
                return sendError(res, ERROR_CODES.VALIDATION_ERROR, 'Quantity must be at least 1', 400);
            }
            cartItem.quantity = quantity;
        }

        if (note !== undefined) {
            cartItem.note = note;
        }

        await cartItem.save();

        return sendSuccess(res, cartItem);
    } catch (error) {
        next(error);
    }
};

/**
 * Remove item from cart
 */
export const removeFromCart = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = req.user!.id;
        const { itemId } = req.params;

        const deleted = await CartItem.destroy({
            where: { id: itemId, userId },
        });

        if (!deleted) {
            return sendError(res, ERROR_CODES.NOT_FOUND, 'Cart item not found', 404);
        }

        return sendSuccess(res, { message: 'Item removed from cart' });
    } catch (error) {
        next(error);
    }
};

/**
 * Clear entire cart
 */
export const clearCart = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = req.user!.id;

        await CartItem.destroy({
            where: { userId },
        });

        return sendSuccess(res, { message: 'Cart cleared' });
    } catch (error) {
        next(error);
    }
};

/**
 * Get cart items count
 */
export const getCartCount = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = req.user!.id;

        const count = await CartItem.count({
            where: { userId },
        });

        return sendSuccess(res, { count });
    } catch (error) {
        next(error);
    }
};

/**
 * Send inquiries to all projects in cart
 */
export const sendInquiries = async (req: Request, res: Response, next: NextFunction) => {
    const transaction = await sequelize.transaction();

    try {
        const userId = req.user!.id;
        const { generalNote } = req.body; // Optional general note for all inquiries

        // Get cart items with product and project info
        const cartItems = await CartItem.findAll({
            where: { userId },
            include: [
                {
                    model: Product,
                    as: 'product',
                    include: [
                        {
                            model: Project,
                            as: 'project',
                        },
                    ],
                },
                {
                    model: ProductVariant,
                    as: 'variant',
                },
            ],
            transaction,
        });

        if (cartItems.length === 0) {
            await transaction.rollback();
            return sendError(res, ERROR_CODES.VALIDATION_ERROR, 'Cart is empty', 400);
        }

        // Group by project
        const groupedByProject: Record<number, {
            projectId: number;
            items: typeof cartItems;
        }> = {};

        for (const item of cartItems) {
            const projectId = item.product?.project?.id;
            if (projectId) {
                if (!groupedByProject[projectId]) {
                    groupedByProject[projectId] = {
                        projectId,
                        items: [],
                    };
                }
                groupedByProject[projectId].items.push(item);
            }
        }

        const conversationIds: number[] = [];

        // Process each project group
        for (const projectId of Object.keys(groupedByProject).map(Number)) {
            const group = groupedByProject[projectId];

            // Find or create conversation
            const [conversation] = await Conversation.findOrCreate({
                where: {
                    customerId: userId,
                    projectId,
                },
                defaults: {
                    customerId: userId,
                    projectId,
                },
                transaction,
            });

            // Generate inquiry message
            const messageContent = generateInquiryMessage(group.items, generalNote);

            // Create message
            await Message.create(
                {
                    conversationId: conversation.id,
                    senderId: userId,
                    content: messageContent,
                    messageType: 'inquiry',
                },
                { transaction }
            );

            // Update conversation last message time
            conversation.lastMessageAt = new Date();
            await conversation.save({ transaction });

            conversationIds.push(conversation.id);
        }

        // Clear cart
        await CartItem.destroy({
            where: { userId },
            transaction,
        });

        await transaction.commit();

        return sendSuccess(res, {
            message: 'Inquiries sent successfully',
            conversationIds,
            projectCount: conversationIds.length,
        });
    } catch (error) {
        await transaction.rollback();
        next(error);
    }
};

/**
 * Generate formatted inquiry message
 */
function generateInquiryMessage(items: CartItem[], generalNote?: string): string {
    const lines: string[] = [];

    // Arabic header
    lines.push('📋 استفسار عن منتجات');
    lines.push('Product Inquiry');
    lines.push('─'.repeat(30));
    lines.push('');

    for (const item of items) {
        const product = item.product!;
        const variant = item.variant;

        lines.push(`• ${product.nameAr} / ${product.name}`);
        if (variant) {
            lines.push(`  النوع/Variant: ${variant.nameAr} / ${variant.name}`);
        }
        lines.push(`  الكمية/Qty: ${item.quantity}`);
        if (item.note) {
            lines.push(`  ملاحظة/Note: ${item.note}`);
        }
        lines.push('');
    }

    if (generalNote) {
        lines.push('─'.repeat(30));
        lines.push(`ملاحظة عامة / General Note:`);
        lines.push(generalNote);
    }

    lines.push('');
    lines.push('─'.repeat(30));
    lines.push('تم إرسال هذا الاستفسار تلقائياً من سلة الاستفسارات');
    lines.push('This inquiry was sent automatically from the inquiry cart');

    return lines.join('\n');
}
