import { prisma } from "../../lib/prisma.js";

// Get all subscriptions (Admin only)
export const getAllSubscriptions = async (req, res) => {
    try {
        const where = {};
        
        // Filter by status
        if (req.query.status) {
            where.status = req.query.status;
        }
        
        // Filter by user
        if (req.query.userId) {
            where.userId = parseInt(req.query.userId);
        }

        const subscriptions = await prisma.subscription.findMany({
            where,
            orderBy: { createdAt: 'desc' },
            include: {
                user: {
                    select: {
                        id: true,
                        name: true,
                        email: true,
                    },
                },
            },
        });

        return res.json(subscriptions);
    } catch (error) {
        console.error('Error fetching subscriptions:', error);
        return res.status(500).json({ error: 'Failed to fetch subscriptions' });
    }
};

// Get current user's subscriptions
export const getMySubscriptions = async (req, res) => {
    try {
        const subscriptions = await prisma.subscription.findMany({
            where: { userId: req.user.id },
            orderBy: { createdAt: 'desc' },
        });

        return res.json(subscriptions);
    } catch (error) {
        console.error('Error fetching user subscriptions:', error);
        return res.status(500).json({ error: 'Failed to fetch subscriptions' });
    }
};

// Get single subscription
export const getSubscriptionById = async (req, res) => {
    try {
        const subscription = await prisma.subscription.findUnique({
            where: { id: parseInt(req.params.id) },
            include: {
                user: {
                    select: {
                        id: true,
                        name: true,
                        email: true,
                    },
                },
            },
        });

        if (!subscription) {
            return res.status(404).json({ error: 'Subscription not found' });
        }

        // Check authorization
        if (subscription.userId !== req.user.id && req.user.role !== 'ADMIN') {
            return res.status(403).json({ error: 'Forbidden' });
        }

        return res.json(subscription);
    } catch (error) {
        console.error('Error fetching subscription:', error);
        return res.status(500).json({ error: 'Failed to fetch subscription' });
    }
};

// Create subscription request
export const createSubscription = async (req, res) => {
    try {
        const { plan } = req.body;

        if (!plan || !['MONTHLY', 'QUARTERLY', 'SEMI_ANNUAL'].includes(plan)) {
            return res.status(400).json({ 
                errors: ['plan is required and must be MONTHLY, QUARTERLY, or SEMI_ANNUAL'] 
            });
        }

        // Check if user already has an active or pending subscription
        const existingSubscription = await prisma.subscription.findFirst({
            where: {
                userId: req.user.id,
                status: { in: ['ACTIVE', 'PENDING'] },
            },
        });

        if (existingSubscription) {
            return res.status(400).json({ 
                error: 'You already have an active or pending subscription' 
            });
        }

        const subscription = await prisma.subscription.create({
            data: {
                userId: req.user.id,
                plan,
                status: 'PENDING',
            },
            include: {
                user: {
                    select: {
                        id: true,
                        name: true,
                        email: true,
                    },
                },
            },
        });

        // Create notification for user
        await prisma.notification.create({
            data: {
                userId: req.user.id,
                type: 'SUBSCRIPTION_UPDATE',
                title: 'Demande d\'abonnement reçue',
                message: `Votre demande d'abonnement ${plan} est en attente d'approbation.`,
            },
        });

        return res.status(201).json(subscription);
    } catch (error) {
        console.error('Error creating subscription:', error);
        return res.status(500).json({ error: 'Failed to create subscription' });
    }
};

// Approve subscription (Admin only)
export const approveSubscription = async (req, res) => {
    try {
        const subscription = await prisma.subscription.findUnique({
            where: { id: parseInt(req.params.id) },
            include: { user: true },
        });

        if (!subscription) {
            return res.status(404).json({ error: 'Subscription not found' });
        }

        if (subscription.status !== 'PENDING') {
            return res.status(400).json({ 
                error: 'Only PENDING subscriptions can be approved' 
            });
        }

        const now = new Date();
        let endDate = new Date(now);

        // Calculate end date based on plan
        switch (subscription.plan) {
            case 'MONTHLY':
                endDate.setMonth(endDate.getMonth() + 1);
                break;
            case 'QUARTERLY':
                endDate.setMonth(endDate.getMonth() + 3);
                break;
            case 'SEMI_ANNUAL':
                endDate.setMonth(endDate.getMonth() + 6);
                break;
        }

        const updated = await prisma.subscription.update({
            where: { id: parseInt(req.params.id) },
            data: {
                status: 'ACTIVE',
                startDate: now,
                endDate,
                approvedBy: req.user.id,
                approvedAt: now,
            },
            include: {
                user: {
                    select: {
                        id: true,
                        name: true,
                        email: true,
                    },
                },
            },
        });

        // Create notification for user
        await prisma.notification.create({
            data: {
                userId: subscription.userId,
                type: 'SUBSCRIPTION_UPDATE',
                title: 'Abonnement approuvé',
                message: `Votre abonnement ${subscription.plan} a été approuvé et est maintenant actif jusqu'au ${endDate.toLocaleDateString('fr-FR')}.`,
            },
        });

        return res.json(updated);
    } catch (error) {
        console.error('Error approving subscription:', error);
        return res.status(500).json({ error: 'Failed to approve subscription' });
    }
};

// Cancel subscription
export const cancelSubscription = async (req, res) => {
    try {
        const subscription = await prisma.subscription.findUnique({
            where: { id: parseInt(req.params.id) },
        });

        if (!subscription) {
            return res.status(404).json({ error: 'Subscription not found' });
        }

        // Check authorization
        if (subscription.userId !== req.user.id && req.user.role !== 'ADMIN') {
            return res.status(403).json({ error: 'Forbidden' });
        }

        const updated = await prisma.subscription.update({
            where: { id: parseInt(req.params.id) },
            data: { status: 'CANCELLED' },
            include: {
                user: {
                    select: {
                        id: true,
                        name: true,
                        email: true,
                    },
                },
            },
        });

        // Create notification for user
        await prisma.notification.create({
            data: {
                userId: subscription.userId,
                type: 'SUBSCRIPTION_UPDATE',
                title: 'Abonnement annulé',
                message: 'Votre abonnement a été annulé.',
            },
        });

        return res.json(updated);
    } catch (error) {
        console.error('Error cancelling subscription:', error);
        return res.status(500).json({ error: 'Failed to cancel subscription' });
    }
};

// Suspend subscription (Admin only)
export const suspendSubscription = async (req, res) => {
    try {
        const subscription = await prisma.subscription.findUnique({
            where: { id: parseInt(req.params.id) },
        });

        if (!subscription) {
            return res.status(404).json({ error: 'Subscription not found' });
        }

        const updated = await prisma.subscription.update({
            where: { id: parseInt(req.params.id) },
            data: { status: 'SUSPENDED' },
            include: {
                user: {
                    select: {
                        id: true,
                        name: true,
                        email: true,
                    },
                },
            },
        });

        // Create notification for user
        await prisma.notification.create({
            data: {
                userId: subscription.userId,
                type: 'SUBSCRIPTION_UPDATE',
                title: 'Abonnement suspendu',
                message: 'Votre abonnement a été suspendu. Veuillez contacter l\'administration.',
            },
        });

        return res.json(updated);
    } catch (error) {
        console.error('Error suspending subscription:', error);
        return res.status(500).json({ error: 'Failed to suspend subscription' });
    }
};

// Delete subscription (Admin only)
export const deleteSubscription = async (req, res) => {
    try {
        await prisma.subscription.delete({
            where: { id: parseInt(req.params.id) },
        });
        return res.status(204).send();
    } catch (error) {
        console.error('Error deleting subscription:', error);
        return res.status(500).json({ error: 'Failed to delete subscription' });
    }
};
