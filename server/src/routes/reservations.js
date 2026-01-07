import { Router } from 'express';
import { authenticate, authorize } from '../middlewares/auth.js';
import {
    getAllReservations,
    getAllReservationsAdmin,
    createReservation,
    cancelReservation,
    deleteReservation
} from '../controllers/reservations.js';

const router = Router();

// Get reservations (users see their own, admins can see all)
router.get('/', authenticate, getAllReservations);

// Get all reservations with user info (Admin only)
router.get('/all', authenticate, authorize('ADMIN'), getAllReservationsAdmin);

// Create reservation
router.post('/', authenticate, createReservation);

// Cancel reservation (owner or admin)
router.patch('/:id/cancel', authenticate, cancelReservation);

// Delete reservation (Admin only)
router.delete('/:id', authenticate, authorize('ADMIN'), deleteReservation);

export default router;
