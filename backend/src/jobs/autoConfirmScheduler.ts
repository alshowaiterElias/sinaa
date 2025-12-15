import { Op } from 'sequelize';
import { Transaction, Notification, Conversation, User } from '../models';
import Project from '../models/Project';

// Auto-confirm interval in milliseconds (1 hour)
const AUTO_CONFIRM_INTERVAL = 60 * 60 * 1000;

// Helper to get user IDs from conversation
async function getConversationParties(conversationId: number): Promise<{ customerId: number; sellerId: number | null }> {
    const conversation = await Conversation.findByPk(conversationId);
    if (!conversation) return { customerId: 0, sellerId: null };

    const project = await Project.findByPk(conversation.projectId);
    return {
        customerId: conversation.customerId,
        sellerId: project?.ownerId ?? null,
    };
}

/**
 * Process pending transactions that have passed their auto-confirm date
 */
export async function processAutoConfirmTransactions(): Promise<void> {
    try {
        console.log('[AutoConfirm] Starting auto-confirm check...');

        const now = new Date();

        // Find all pending transactions that should be auto-confirmed
        const pendingTransactions = await Transaction.findAll({
            where: {
                status: 'pending',
                autoConfirmAt: {
                    [Op.lte]: now,
                },
            },
        });

        console.log(`[AutoConfirm] Found ${pendingTransactions.length} transactions to auto-confirm`);

        for (const transaction of pendingTransactions) {
            try {
                // Auto-confirm the transaction
                transaction.status = 'confirmed';
                transaction.customerConfirmed = true;
                transaction.sellerConfirmed = true;
                transaction.customerConfirmedAt = now;
                transaction.sellerConfirmedAt = now;
                await transaction.save();

                // Notify both parties
                const parties = await getConversationParties(transaction.conversationId);

                const notificationTitle = 'Transaction Auto-Confirmed';
                const notificationTitleAr = 'تأكيد تلقائي للتقييم';

                // Notify customer
                if (parties.customerId) {
                    await Notification.create({
                        userId: parties.customerId,
                        type: 'transaction_auto_confirmed',
                        title: notificationTitle,
                        titleAr: notificationTitleAr,
                        data: { transactionId: transaction.id },
                    });
                }

                // Notify seller
                if (parties.sellerId) {
                    await Notification.create({
                        userId: parties.sellerId,
                        type: 'transaction_auto_confirmed',
                        title: notificationTitle,
                        titleAr: notificationTitleAr,
                        data: { transactionId: transaction.id },
                    });
                }

                console.log(`[AutoConfirm] Auto-confirmed transaction ${transaction.id}`);
            } catch (error) {
                console.error(`[AutoConfirm] Error processing transaction ${transaction.id}:`, error);
            }
        }

        console.log('[AutoConfirm] Auto-confirm check completed');
    } catch (error) {
        console.error('[AutoConfirm] Error in auto-confirm scheduler:', error);
    }
}

/**
 * Start the auto-confirm scheduler
 */
export function startAutoConfirmScheduler(): void {
    console.log('[AutoConfirm] Starting auto-confirm scheduler...');

    // Run immediately on startup
    processAutoConfirmTransactions();

    // Then run every hour
    setInterval(processAutoConfirmTransactions, AUTO_CONFIRM_INTERVAL);

    console.log('[AutoConfirm] Scheduler started. Running every hour.');
}

export default {
    processAutoConfirmTransactions,
    startAutoConfirmScheduler,
};
