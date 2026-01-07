import { Router } from 'express';
import { authenticate, authorize } from '../middlewares/auth.js';
import {
    getAllUsers,
    getUserById,
    createUser,
    updateUser,
    deleteUser,
    getUserStats
} from '../controllers/users.js';

const router = Router();

// All routes require admin authentication
router.use(authenticate, authorize('ADMIN'));

// Get user statistics
router.get('/stats', getUserStats);

// Get all users
router.get('/', getAllUsers);

// Get single user
router.get('/:id', getUserById);

// Create user
router.post('/', createUser);

// Update user
router.patch('/:id', updateUser);

// Delete user
router.delete('/:id', deleteUser);

export default router;
