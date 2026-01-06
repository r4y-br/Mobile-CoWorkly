import { Router } from 'express';
import { authenticate, authorize } from '../middlewares/auth.js';
import { getDashboardStats, getWeeklyStats } from '../controllers/stats.js';

const router = Router();

// All stats routes require authentication and admin role
router.use(authenticate);
router.use(authorize('ADMIN'));

// Get full dashboard stats
router.get('/dashboard', getDashboardStats);

// Get weekly visitor stats
router.get('/weekly', getWeeklyStats);

export default router;
