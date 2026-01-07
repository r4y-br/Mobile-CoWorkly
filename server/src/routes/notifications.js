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

// Mark all notifications as read (must come before /:id)
router.patch('/read-all', markAllAsRead);

// Mark single notification as read
router.patch('/:id/read', markAsRead);

// Delete all notifications (root path)
router.delete('/', deleteAllNotifications);

// Delete single notification
router.delete('/:id', deleteNotification);

export default router;
