import { Router } from 'express';
import { authenticate, authorize } from '../middlewares/auth.js';
import {
    getAllRooms,
    getRoomById,
    createRoom,
    updateRoom,
    deleteRoom
} from '../controllers/rooms.js';

const router = Router();

// Public: Get all rooms
router.get('/', getAllRooms);

// Public: Get single room
router.get('/:id', getRoomById);

// Admin: Create room
router.post('/', authenticate, authorize('ADMIN'), createRoom);

// Admin: Update room
router.patch('/:id', authenticate, authorize('ADMIN'), updateRoom);

// Admin: Delete room
router.delete('/:id', authenticate, authorize('ADMIN'), deleteRoom);

export default router;
