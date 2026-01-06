import express from 'express';
import { getMySubscription, subscribe, approveSubscription, getAllSubscriptions } from '../controllers/subscriptionController.js';
import { authenticate, authorize } from '../middlewares/auth.js';

const router = express.Router();

// Route pour récupérer les infos de l'utilisateur connecté
router.get('/me', authenticate, getMySubscription);

// Route pour demander un nouvel abonnement
router.post('/subscribe', authenticate, subscribe);

// Admin routes
router.get('/all', authenticate, authorize('ADMIN'), getAllSubscriptions);
router.patch('/:subscriptionId/approve', authenticate, authorize('ADMIN'), approveSubscription);

export default router;