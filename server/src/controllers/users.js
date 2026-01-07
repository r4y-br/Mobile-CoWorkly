import { prisma } from "../../lib/prisma.js";

// Get all users (Admin only)
export const getAllUsers = async (req, res) => {
    try {
        const users = await prisma.user.findMany({
            orderBy: { createdAt: 'desc' },
            select: {
                id: true,
                name: true,
                email: true,
                role: true,
                createdAt: true,
                _count: {
                    select: {
                        reservations: true,
                        subscriptions: true,
                    }
                }
            }
        });

        return res.json(users);
    } catch (error) {
        console.error('Error fetching users:', error);
        return res.status(500).json({ error: 'Failed to fetch users' });
    }
};

// Get user by ID (Admin only)
export const getUserById = async (req, res) => {
    try {
        const { id } = req.params;
        const user = await prisma.user.findUnique({
            where: { id: parseInt(id) },
            select: {
                id: true,
                name: true,
                email: true,
                role: true,
                createdAt: true,
                reservations: {
                    orderBy: { createdAt: 'desc' },
                    take: 10,
                    include: {
                        seat: {
                            include: { room: true }
                        }
                    }
                },
                subscriptions: {
                    orderBy: { createdAt: 'desc' },
                    take: 5
                }
            }
        });

        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }

        return res.json(user);
    } catch (error) {
        console.error('Error fetching user:', error);
        return res.status(500).json({ error: 'Failed to fetch user' });
    }
};

// Update user role (Admin only)
export const updateUserRole = async (req, res) => {
    try {
        const { id } = req.params;
        const { role } = req.body;

        if (!['USER', 'ADMIN'].includes(role)) {
            return res.status(400).json({ error: 'Invalid role' });
        }

        const user = await prisma.user.update({
            where: { id: parseInt(id) },
            data: { role },
            select: {
                id: true,
                name: true,
                email: true,
                role: true
            }
        });

        return res.json({ message: 'Role updated successfully', user });
    } catch (error) {
        console.error('Error updating user role:', error);
        return res.status(500).json({ error: 'Failed to update user role' });
    }
};

// Delete user (Admin only)
export const deleteUser = async (req, res) => {
    try {
        const { id } = req.params;
        const userId = parseInt(id);

        // Don't allow deleting self
        if (req.user.id === userId) {
            return res.status(400).json({ error: 'Cannot delete your own account' });
        }

        // Delete related data first
        await prisma.reservation.deleteMany({ where: { userId } });
        await prisma.subscription.deleteMany({ where: { userId } });
        
        await prisma.user.delete({
            where: { id: userId }
        });

        return res.json({ message: 'User deleted successfully' });
    } catch (error) {
        console.error('Error deleting user:', error);
        return res.status(500).json({ error: 'Failed to delete user' });
    }
};

// Cancel reservation (Admin only)
export const cancelReservation = async (req, res) => {
    try {
        const { id } = req.params;
        
        const reservation = await prisma.reservation.update({
            where: { id: parseInt(id) },
            data: { status: 'CANCELLED' },
            include: {
                user: { select: { id: true, name: true, email: true } },
                seat: { include: { room: true } }
            }
        });

        // Update seat status
        await prisma.seat.update({
            where: { id: reservation.seatId },
            data: { status: 'AVAILABLE' }
        });

        return res.json({ message: 'Reservation cancelled', reservation });
    } catch (error) {
        console.error('Error cancelling reservation:', error);
        return res.status(500).json({ error: 'Failed to cancel reservation' });
    }
};
