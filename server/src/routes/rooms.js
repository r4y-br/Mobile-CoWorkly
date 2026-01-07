import { Router } from 'express';
import { authenticate, authorize } from '../middlewares/auth.js';
import {
    getAllRooms,
    getRoomById,
    updateRoom,
} from '../controllers/rooms.js';

const router = Router();

// Public: Get all rooms
router.get('/', getAllRooms);

// Public: Get single room
router.get('/:id', getRoomById);

// Admin: Update room (e.g., availability)
router.patch('/:id', authenticate, authorize('ADMIN'), updateRoom);

export default router;
