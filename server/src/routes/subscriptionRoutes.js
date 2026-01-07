import express from 'express';
import { getMySubscription, subscribe, approveSubscription, getAllSubscriptions, suspendSubscription, cancelSubscription, deleteSubscription, createSubscriptionForUser } from '../controllers/subscriptionController.js';
import { authenticate, authorize } from '../middlewares/auth.js';

const router = express.Router();

// Route pour récupérer les infos de l'utilisateur connecté
router.get('/me', authenticate, getMySubscription);

// Route pour demander un nouvel abonnement
router.post('/subscribe', authenticate, subscribe);

// User: cancel own subscription
router.patch('/:subscriptionId/cancel', authenticate, cancelSubscription);

// Admin routes
router.get('/all', authenticate, authorize('ADMIN'), getAllSubscriptions);
router.post('/create', authenticate, authorize('ADMIN'), createSubscriptionForUser);
router.patch('/:subscriptionId/approve', authenticate, authorize('ADMIN'), approveSubscription);
router.patch('/:subscriptionId/suspend', authenticate, authorize('ADMIN'), suspendSubscription);
router.delete('/:subscriptionId', authenticate, authorize('ADMIN'), deleteSubscription);

export default router;