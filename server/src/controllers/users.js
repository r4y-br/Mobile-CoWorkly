import { prisma } from "../../lib/prisma.js";
import bcrypt from 'bcryptjs';

// Get all users (Admin only)
export const getAllUsers = async (req, res) => {
    try {
        const where = {};
        
        // Filter by role
        if (req.query.role) {
            where.role = req.query.role;
        }

        const users = await prisma.user.findMany({
            where,
            orderBy: { createdAt: 'desc' },
            select: {
                id: true,
                name: true,
                email: true,
                phone: true,
                role: true,
                createdAt: true,
                updatedAt: true,
                _count: {
                    select: {
                        reservations: true,
                        subscriptions: true,
                    },
                },
            },
        });

        return res.json(users);
    } catch (error) {
        console.error('Error fetching users:', error);
        return res.status(500).json({ error: 'Failed to fetch users' });
    }
};

// Get single user (Admin only)
export const getUserById = async (req, res) => {
    try {
        const user = await prisma.user.findUnique({
            where: { id: parseInt(req.params.id) },
            select: {
                id: true,
                name: true,
                email: true,
                phone: true,
                role: true,
                createdAt: true,
                updatedAt: true,
                reservations: {
                    orderBy: { createdAt: 'desc' },
                    take: 10,
                    include: {
                        seat: {
                            include: { room: true },
                        },
                    },
                },
                subscriptions: {
                    orderBy: { createdAt: 'desc' },
                },
                _count: {
                    select: {
                        reservations: true,
                        subscriptions: true,
                        notifications: true,
                    },
                },
            },
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

// Create user (Admin only)
export const createUser = async (req, res) => {
    try {
        const { name, email, password, phone, role } = req.body;

        if (!name || !email || !password) {
            return res.status(400).json({ 
                errors: ['name, email, and password are required'] 
            });
        }

        const existingUser = await prisma.user.findUnique({ where: { email } });
        if (existingUser) {
            return res.status(400).json({ error: 'Email is already registered' });
        }

        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        const user = await prisma.user.create({
            data: {
                name,
                email,
                password: hashedPassword,
                phone,
                role: role || 'USER',
            },
            select: {
                id: true,
                name: true,
                email: true,
                phone: true,
                role: true,
                createdAt: true,
            },
        });

        return res.status(201).json(user);
    } catch (error) {
        console.error('Error creating user:', error);
        return res.status(500).json({ error: 'Failed to create user' });
    }
};

// Update user (Admin only)
export const updateUser = async (req, res) => {
    try {
        const { name, email, phone, role, password } = req.body;
        const data = {};

        if (name !== undefined) data.name = name;
        if (email !== undefined) {
            // Check if email is already taken by another user
            const existingUser = await prisma.user.findUnique({ 
                where: { email } 
            });
            if (existingUser && existingUser.id !== parseInt(req.params.id)) {
                return res.status(400).json({ error: 'Email is already taken' });
            }
            data.email = email;
        }
        if (phone !== undefined) data.phone = phone;
        if (role !== undefined) data.role = role;
        
        if (password !== undefined && password !== '') {
            const salt = await bcrypt.genSalt(10);
            data.password = await bcrypt.hash(password, salt);
        }

        const user = await prisma.user.update({
            where: { id: parseInt(req.params.id) },
            data,
            select: {
                id: true,
                name: true,
                email: true,
                phone: true,
                role: true,
                createdAt: true,
                updatedAt: true,
            },
        });

        return res.json(user);
    } catch (error) {
        console.error('Error updating user:', error);
        return res.status(500).json({ error: 'Failed to update user' });
    }
};

// Delete user (Admin only)
export const deleteUser = async (req, res) => {
    try {
        const userId = parseInt(req.params.id);

        // Prevent admin from deleting themselves
        if (userId === req.user.id) {
            return res.status(400).json({ error: 'Cannot delete your own account' });
        }

        await prisma.user.delete({
            where: { id: userId },
        });

        return res.status(204).send();
    } catch (error) {
        console.error('Error deleting user:', error);
        return res.status(500).json({ error: 'Failed to delete user' });
    }
};

// Get user statistics (Admin only)
export const getUserStats = async (req, res) => {
    try {
        const totalUsers = await prisma.user.count();
        const adminUsers = await prisma.user.count({ where: { role: 'ADMIN' } });
        const regularUsers = await prisma.user.count({ where: { role: 'USER' } });

        const activeSubscriptions = await prisma.subscription.count({
            where: { status: 'ACTIVE' },
        });

        const totalReservations = await prisma.reservation.count();
        const pendingReservations = await prisma.reservation.count({
            where: { status: 'PENDING' },
        });
        const confirmedReservations = await prisma.reservation.count({
            where: { status: 'CONFIRMED' },
        });

        return res.json({
            users: {
                total: totalUsers,
                admins: adminUsers,
                regular: regularUsers,
            },
            subscriptions: {
                active: activeSubscriptions,
            },
            reservations: {
                total: totalReservations,
                pending: pendingReservations,
                confirmed: confirmedReservations,
            },
        });
    } catch (error) {
        console.error('Error fetching user stats:', error);
        return res.status(500).json({ error: 'Failed to fetch statistics' });
    }
};
