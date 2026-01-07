import express from 'express';
import { 
    getAllUsers, 
    getUserById, 
    updateUserRole, 
    deleteUser,
    cancelReservation 
} from '../controllers/users.js';
import { requireAuth, requireAdmin } from '../middlewares/auth.js';

const router = express.Router();

// All routes require admin
router.use(requireAuth, requireAdmin);

// User management
router.get('/', getAllUsers);
router.get('/:id', getUserById);
router.patch('/:id/role', updateUserRole);
router.delete('/:id', deleteUser);

// Reservation management
router.patch('/reservations/:id/cancel', cancelReservation);

export default router;
