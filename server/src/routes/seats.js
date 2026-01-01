import { Router } from 'express';
import { authenticate, authorize } from '../middlewares/auth.js';
import {
    getAllSeats,
    getSeatById,
    createSeat,
    updateSeat,
    deleteSeat
} from '../controllers/seats.js';

const router = Router();

// Public: Get seats (optionally filter by roomId)
router.get('/', getAllSeats);

// Public: Get single seat
router.get('/:id', getSeatById);

// Admin: Create seat
router.post('/', authenticate, authorize('ADMIN'), createSeat);

// Admin: Update seat
router.patch('/:id', authenticate, authorize('ADMIN'), updateSeat);

// Admin: Delete seat
router.delete('/:id', authenticate, authorize('ADMIN'), deleteSeat);

export default router;
