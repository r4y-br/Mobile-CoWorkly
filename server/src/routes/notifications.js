import { Router } from 'express';
import { authenticate } from '../middlewares/auth.js';
import {
    getAllNotifications,
    markAsRead,
    markAllAsRead,
    deleteNotification,
    deleteAllNotifications
} from '../controllers/notifications.js';

const router = Router();

// All routes require authentication
router.use(authenticate);

// Get notifications
router.get('/', getAllNotifications);

// Mark single notification as read
router.patch('/:id/read', markAsRead);

// Mark all notifications as read
router.patch('/read-all', markAllAsRead);

// Delete single notification
router.delete('/:id', deleteNotification);

// Delete all notifications
router.delete('/', deleteAllNotifications);

export default router;
