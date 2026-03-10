import { prisma } from "../../lib/prisma.js";

// Get notifications for current user
export const getAllNotifications = async (req, res) => {
    try {
        const where = {
            userId: req.user.id,
        };

        if (req.query.unreadOnly === 'true') {
            where.isRead = false;
        }

        const notifications = await prisma.notification.findMany({
            where,
            orderBy: { createdAt: 'desc' },
        });

        return res.json(notifications);
    } catch (error) {
        console.error('Error fetching notifications:', error);
        return res.status(500).json({ error: 'Failed to fetch notifications' });
    }
};

// Mark notification as read
export const markAsRead = async (req, res) => {
    try {
        const id = parseInt(req.params.id);
        if (isNaN(id)) {
            return res.status(400).json({ error: 'Invalid notification ID' });
        }

        const notification = await prisma.notification.findUnique({
            where: { id },
        });

        if (!notification || notification.userId !== req.user.id) {
            return res.status(404).json({ error: 'Notification not found' });
        }

        const updated = await prisma.notification.update({
            where: { id },
            data: { isRead: true },
        });

        return res.json(updated);
    } catch (error) {
        console.error('Error marking notification as read:', error);
        return res.status(500).json({ error: 'Failed to update notification' });
    }
};

// Mark all notifications as read
export const markAllAsRead = async (req, res) => {
    try {
        await prisma.notification.updateMany({
            where: { userId: req.user.id, isRead: false },
            data: { isRead: true },
        });

        return res.status(204).send();
    } catch (error) {
        console.error('Error marking all notifications as read:', error);
        return res.status(500).json({ error: 'Failed to update notifications' });
    }
};

// Delete notification
export const deleteNotification = async (req, res) => {
    try {
        const id = parseInt(req.params.id);
        if (isNaN(id)) {
            return res.status(400).json({ error: 'Invalid notification ID' });
        }

        const notification = await prisma.notification.findUnique({
            where: { id },
        });

        if (!notification || notification.userId !== req.user.id) {
            return res.status(404).json({ error: 'Notification not found' });
        }

        await prisma.notification.delete({ where: { id } });
        return res.status(204).send();
    } catch (error) {
        console.error('Error deleting notification:', error);
        return res.status(500).json({ error: 'Failed to delete notification' });
    }
};

// Delete all notifications for current user
export const deleteAllNotifications = async (req, res) => {
    try {
        await prisma.notification.deleteMany({ where: { userId: req.user.id } });
        return res.status(204).send();
    } catch (error) {
        console.error('Error deleting notifications:', error);
        return res.status(500).json({ error: 'Failed to delete notifications' });
    }
};
