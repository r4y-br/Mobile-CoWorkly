import { prisma } from '../../lib/prisma.js';

// Helper pour calculer les heures totales selon le plan
const GET_TOTAL_HOURS = (plan) => {
    const quotas = {
        'MONTHLY': 40,
        'QUARTERLY': 120,
        'SEMI_ANNUAL': 250
    };
    return quotas[plan] || 0;
};

export const getMySubscription = async (req, res) => {
    try {
        const userId = req.user.id;

        // 1. Récupérer l'abonnement actif
        const subscription = await prisma.subscription.findFirst({
            where: { userId, status: 'ACTIVE' },
            orderBy: { createdAt: 'desc' }
        });

        if (!subscription) {
            return res.json({ plan: 'NONE', status: 'INACTIVE', usedHours: 0, totalHours: 0, remainingHours: 0 });
        }

        // 2. Récupérer toutes les réservations CONFIRMED liées à cet utilisateur
        // Idéalement, on filtre par date (entre subscription.startDate et endDate)
        const reservations = await prisma.reservation.findMany({
            where: {
                userId,
                status: 'CONFIRMED',
                startTime: { gte: subscription.startDate },
                endTime: { lte: subscription.endDate }
            }
        });

        // 3. Calculer le cumul des heures
        let totalMinutes = 0;
        reservations.forEach(resv => {
            const diffMs = new Date(resv.endTime) - new Date(resv.startTime);
            totalMinutes += diffMs / (1000 * 60);
        });

        const usedHours = Math.ceil(totalMinutes / 60);
        const totalQuota = GET_TOTAL_HOURS(subscription.plan);
        const remainingHours = Math.max(0, totalQuota - usedHours);

        return res.json({
            plan: subscription.plan,
            status: subscription.status,
            usedHours,
            totalHours: totalQuota,
            remainingHours,
            endDate: subscription.endDate
        });

    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Erreur de calcul d'abonnement" });
    }
};

// Nouvelle méthode pour créer une demande d'abonnement
export const subscribe = async (req, res) => {
    try {
        const { plan } = req.body; // 'MONTHLY', etc.
        const userId = req.user.id;

        // Vérifier s'il y a déjà un abonnement en cours ou en attente
        const existing = await prisma.subscription.findFirst({
            where: { userId, status: { in: ['ACTIVE', 'PENDING'] } }
        });

        if (existing) {
            return res.status(400).json({ message: "Vous avez déjà un abonnement actif ou en attente." });
        }

        const newSubscription = await prisma.subscription.create({
            data: {
                userId,
                plan,
                status: 'PENDING', // L'admin devra valider
                // Par défaut, on peut mettre des dates temporaires ou nulles
            }
        });

        res.status(201).json(newSubscription);
    } catch (error) {
        res.status(500).json({ message: "Erreur lors de la souscription" });
    }
};

// Approuver un abonnement (Admin only)
export const approveSubscription = async (req, res) => {
    try {
        const { subscriptionId } = req.params;

        const subscription = await prisma.subscription.findUnique({
            where: { id: parseInt(subscriptionId) }
        });

        if (!subscription) {
            return res.status(404).json({ message: "Abonnement non trouvé" });
        }

        if (subscription.status !== 'PENDING') {
            return res.status(400).json({ message: "L'abonnement n'est pas en attente" });
        }

        // Calculate end date based on plan
        const now = new Date();
        let endDate;
        switch (subscription.plan) {
            case 'MONTHLY':
                endDate = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);
                break;
            case 'QUARTERLY':
                endDate = new Date(now.getTime() + 90 * 24 * 60 * 60 * 1000);
                break;
            case 'SEMI_ANNUAL':
                endDate = new Date(now.getTime() + 180 * 24 * 60 * 60 * 1000);
                break;
            default:
                endDate = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);
        }

        const updated = await prisma.subscription.update({
            where: { id: parseInt(subscriptionId) },
            data: {
                status: 'ACTIVE',
                startDate: now,
                endDate: endDate,
                approvedBy: req.user.id,
                approvedAt: now,
            }
        });

        res.json(updated);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Erreur lors de l'approbation" });
    }
};

// Get all subscriptions (Admin only)
export const getAllSubscriptions = async (req, res) => {
    try {
        const subscriptions = await prisma.subscription.findMany({
            orderBy: { createdAt: 'desc' },
            include: {
                user: {
                    select: { id: true, name: true, email: true }
                }
            }
        });
        res.json(subscriptions);
    } catch (error) {
        res.status(500).json({ message: "Erreur lors de la récupération des abonnements" });
    }
};

// Suspend subscription (Admin only)
export const suspendSubscription = async (req, res) => {
    try {
        const { subscriptionId } = req.params;

        const subscription = await prisma.subscription.findUnique({
            where: { id: parseInt(subscriptionId) }
        });

        if (!subscription) {
            return res.status(404).json({ message: "Abonnement non trouvé" });
        }

        const updated = await prisma.subscription.update({
            where: { id: parseInt(subscriptionId) },
            data: { status: 'SUSPENDED' }
        });

        res.json(updated);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Erreur lors de la suspension" });
    }
};

// Cancel subscription (user can cancel own, admin can cancel any)
export const cancelSubscription = async (req, res) => {
    try {
        const { subscriptionId } = req.params;
        const userId = req.user.id;
        const isAdmin = req.user.role === 'ADMIN';

        const subscription = await prisma.subscription.findUnique({
            where: { id: parseInt(subscriptionId) }
        });

        if (!subscription) {
            return res.status(404).json({ message: "Abonnement non trouvé" });
        }

        // Check if user owns the subscription or is admin
        if (subscription.userId !== userId && !isAdmin) {
            return res.status(403).json({ message: "Non autorisé" });
        }

        const updated = await prisma.subscription.update({
            where: { id: parseInt(subscriptionId) },
            data: { status: 'CANCELLED' }
        });

        res.json(updated);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Erreur lors de l'annulation" });
    }
};

// Delete subscription (Admin only)
export const deleteSubscription = async (req, res) => {
    try {
        const { subscriptionId } = req.params;

        await prisma.subscription.delete({
            where: { id: parseInt(subscriptionId) }
        });

        res.status(204).send();
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Erreur lors de la suppression" });
    }
};