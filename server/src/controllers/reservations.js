import { prisma } from "../../lib/prisma.js";

// Helper: Check for conflicting reservations
async function hasConflict(seatId, startTime, endTime, excludeId = null) {
    const where = {
        seatId,
        status: { not: 'CANCELLED' },
        OR: [
            {
                startTime: { lt: endTime },
                endTime: { gt: startTime },
            },
        ],
    };

    if (excludeId) {
        where.id = { not: excludeId };
    }

    const conflicting = await prisma.reservation.findFirst({ where });
    return !!conflicting;
}

// Helper: Update seat status based on reservations
async function updateSeatStatus(seatId) {
    const activeReservation = await prisma.reservation.findFirst({
        where: {
            seatId,
            status: { in: ['CONFIRMED', 'PENDING'] },
        },
    });

    await prisma.seat.update({
        where: { id: seatId },
        data: {
            status: activeReservation ? 'RESERVED' : 'AVAILABLE',
        },
    });
}

// Helper: Check if user has valid active subscription
async function checkUserSubscription(userId) {
    const now = new Date();
    
    const subscription = await prisma.subscription.findFirst({
        where: {
            userId,
            status: 'ACTIVE',
            startDate: { lte: now },
            endDate: { gte: now },
        },
    });

    return subscription;
}

// Get reservations
export const getAllReservations = async (req, res) => {
    try {
        const where = {};
        
        // Non-admin users can only see their own reservations
        if (req.user.role !== 'ADMIN') {
            where.userId = req.user.id;
        } else if (req.query.userId) {
            const parsedUserId = parseInt(req.query.userId);
            if (isNaN(parsedUserId)) {
                return res.status(400).json({ error: 'Invalid userId query parameter' });
            }
            where.userId = parsedUserId;
        }

        if (req.query.seatId) {
            const parsedSeatId = parseInt(req.query.seatId);
            if (isNaN(parsedSeatId)) {
                return res.status(400).json({ error: 'Invalid seatId query parameter' });
            }
            where.seatId = parsedSeatId;
        }

        const reservations = await prisma.reservation.findMany({
            where,
            orderBy: { startTime: 'desc' },
            include: {
                seat: {
                    include: { room: true },
                },
            },
        });

        return res.json(reservations);
    } catch (error) {
        console.error('Error fetching reservations:', error);
        return res.status(500).json({ error: 'Failed to fetch reservations' });
    }
};

// Create reservation
export const createReservation = async (req, res) => {
    try {
        const { seatId, startTime, endTime, type, date } = req.body;

        if (!seatId) {
            return res.status(400).json({ errors: ['seatId is required'] });
        }

        // Check if user has an active subscription
        const subscription = await checkUserSubscription(req.user.id);
        if (!subscription) {
            return res.status(403).json({ 
                error: 'Vous devez avoir un abonnement actif pour effectuer une réservation. Souscrivez à un abonnement depuis la page Abonnements.' 
            });
        }

        // Handle both formats: direct DateTime or date + time strings
        let parsedStartTime, parsedEndTime;
        
        if (date && startTime && endTime) {
            // Format from Flutter app: date as YYYY-MM-DD, startTime/endTime as HH:mm
            parsedStartTime = new Date(`${date}T${startTime}:00`);
            parsedEndTime = new Date(`${date}T${endTime}:00`);
        } else if (startTime && endTime) {
            // Direct DateTime format
            parsedStartTime = new Date(startTime);
            parsedEndTime = new Date(endTime);
        } else {
            return res.status(400).json({ errors: ['startTime and endTime are required'] });
        }

        if (isNaN(parsedStartTime.getTime()) || isNaN(parsedEndTime.getTime())) {
            return res.status(400).json({ errors: ['Invalid date/time format'] });
        }

        if (parsedStartTime >= parsedEndTime) {
            return res.status(400).json({ errors: ['endTime must be after startTime'] });
        }

        // Block past-date reservations
        if (parsedStartTime <= new Date()) {
            return res.status(400).json({ errors: ['Cannot create a reservation in the past'] });
        }

        // Validate reservation is within subscription period
        if (parsedStartTime < subscription.startDate || parsedEndTime > subscription.endDate) {
            const endDateFormatted = subscription.endDate.toLocaleDateString('fr-FR');
            return res.status(403).json({ 
                error: `Votre réservation doit être dans la période de votre abonnement (jusqu'au ${endDateFormatted}).` 
            });
        }

        const parsedSeatId = parseInt(seatId);
        const seat = await prisma.seat.findUnique({ where: { id: parsedSeatId } });
        if (!seat) {
            return res.status(400).json({ errors: ['seatId is invalid'] });
        }

        // Block booking seats under maintenance
        if (seat.status === 'MAINTENANCE') {
            return res.status(400).json({ error: 'This seat is currently under maintenance and cannot be reserved' });
        }

        const conflict = await hasConflict(parsedSeatId, parsedStartTime, parsedEndTime);
        if (conflict) {
            return res.status(409).json({ error: 'Seat is already reserved for this time range' });
        }

        // Use transaction to atomically create reservation and update seat status
        const reservation = await prisma.$transaction(async (tx) => {
            const newReservation = await tx.reservation.create({
                data: {
                    userId: req.user.id,
                    seatId: parsedSeatId,
                    startTime: parsedStartTime,
                    endTime: parsedEndTime,
                    type: type || 'HOURLY',
                    status: 'CONFIRMED',
                },
                include: {
                    seat: { include: { room: true } },
                },
            });

            // Create notification for the user
            await tx.notification.create({
                data: {
                    userId: req.user.id,
                    type: 'CONFIRMATION_RESERVATION',
                    title: 'Réservation confirmée',
                    message: `Votre réservation pour ${newReservation.seat.room.name} (siège ${newReservation.seat.number}) a été confirmée.`,
                },
            });

            // Update seat status within the same transaction
            const activeReservation = await tx.reservation.findFirst({
                where: {
                    seatId: parsedSeatId,
                    status: { in: ['CONFIRMED', 'PENDING'] },
                },
            });
            await tx.seat.update({
                where: { id: parsedSeatId },
                data: { status: activeReservation ? 'RESERVED' : 'AVAILABLE' },
            });

            return newReservation;
        });

        return res.status(201).json(reservation);
    } catch (error) {
        console.error('Error creating reservation:', error);
        return res.status(500).json({ error: 'Failed to create reservation' });
    }
};

// Cancel reservation
export const cancelReservation = async (req, res) => {
    try {
        const id = parseInt(req.params.id);
        if (isNaN(id)) {
            return res.status(400).json({ error: 'Invalid reservation ID' });
        }

        const reservation = await prisma.reservation.findUnique({
            where: { id },
        });

        if (!reservation) {
            return res.status(404).json({ error: 'Reservation not found' });
        }

        // Only owner or admin can cancel
        if (reservation.userId !== req.user.id && req.user.role !== 'ADMIN') {
            return res.status(403).json({ error: 'Forbidden' });
        }

        // Prevent double-cancel
        if (reservation.status === 'CANCELLED') {
            return res.status(400).json({ error: 'Reservation is already cancelled' });
        }

        // Use transaction to atomically cancel reservation and update seat status
        const updated = await prisma.$transaction(async (tx) => {
            const cancelled = await tx.reservation.update({
                where: { id },
                data: { status: 'CANCELLED' },
                include: {
                    seat: { include: { room: true } },
                },
            });

            const activeReservation = await tx.reservation.findFirst({
                where: {
                    seatId: reservation.seatId,
                    status: { in: ['CONFIRMED', 'PENDING'] },
                },
            });
            await tx.seat.update({
                where: { id: reservation.seatId },
                data: { status: activeReservation ? 'RESERVED' : 'AVAILABLE' },
            });

            return cancelled;
        });

        return res.json(updated);
    } catch (error) {
        console.error('Error cancelling reservation:', error);
        return res.status(500).json({ error: 'Failed to cancel reservation' });
    }
};

// Delete reservation (Admin only)
export const deleteReservation = async (req, res) => {
    try {
        const id = parseInt(req.params.id);
        if (isNaN(id)) {
            return res.status(400).json({ error: 'Invalid reservation ID' });
        }

        const reservation = await prisma.reservation.findUnique({
            where: { id },
        });

        if (!reservation) {
            return res.status(404).json({ error: 'Reservation not found' });
        }

        await prisma.reservation.delete({ where: { id } });
        await updateSeatStatus(reservation.seatId);

        return res.status(204).send();
    } catch (error) {
        console.error('Error deleting reservation:', error);
        return res.status(500).json({ error: 'Failed to delete reservation' });
    }
};
