import { Router } from 'express';
import { authenticate, authorize } from '../middlewares/auth.js';
import {
    getAllSubscriptions,
    getMySubscriptions,
    getSubscriptionById,
    createSubscription,
    approveSubscription,
    cancelSubscription,
    suspendSubscription,
    deleteSubscription
} from '../controllers/subscriptions.js';

const router = Router();

// User: Get my subscriptions (must come before /:id to avoid conflict)
router.get('/my', authenticate, getMySubscriptions);

// Admin: Get all subscriptions (must come before /:id)
router.get('/', authenticate, authorize('ADMIN'), getAllSubscriptions);

// User: Create subscription request
router.post('/', authenticate, createSubscription);

// User/Admin: Get single subscription
router.get('/:id', authenticate, getSubscriptionById);

// Admin: Approve subscription (must come before /:id/cancel)
router.patch('/:id/approve', authenticate, authorize('ADMIN'), approveSubscription);

// Admin: Suspend subscription
router.patch('/:id/suspend', authenticate, authorize('ADMIN'), suspendSubscription);

// User/Admin: Cancel subscription
router.patch('/:id/cancel', authenticate, cancelSubscription);

// Admin: Delete subscription
router.delete('/:id', authenticate, authorize('ADMIN'), deleteSubscription);

export default router;
