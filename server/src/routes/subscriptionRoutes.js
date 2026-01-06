import express from 'express';
import { getMySubscription, subscribe } from '../controllers/subscriptionController.js';
import { authenticate } from '../middlewares/auth.js'; // Ton middleware actuel

const router = express.Router();

// Route pour récupérer les infos de l'utilisateur connecté
router.get('/me', authenticate, getMySubscription);

// Route pour demander un nouvel abonnement
router.post('/subscribe', authenticate, subscribe);

export default router;