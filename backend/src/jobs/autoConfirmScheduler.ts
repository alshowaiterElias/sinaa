// Auto-confirm logic has been removed as per the new Order flow strategy.
// This file is kept to prevent breaking existing imports in app.ts or index.ts.

export async function processAutoConfirmTransactions(): Promise<void> {
    // No-op
}

export function startAutoConfirmScheduler(): void {
    console.log('[AutoConfirm] Scheduler is disabled in the new Order flow.');
}

export default {
    processAutoConfirmTransactions,
    startAutoConfirmScheduler,
};
