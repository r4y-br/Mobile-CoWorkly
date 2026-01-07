import { Router } from 'express';
import { authenticate, authorize } from '../middlewares/auth.js';
import {
    getAllSeats,
    getSeatById,
    updateSeat,
} from '../controllers/seats.js';

const router = Router();

// Public: Get seats (optionally filter by roomId)
router.get('/', getAllSeats);

// Public: Get single seat
router.get('/:id', getSeatById);

// Admin: Update seat status (e.g., MAINTENANCE)
router.patch('/:id', authenticate, authorize('ADMIN'), updateSeat);

export default router;
