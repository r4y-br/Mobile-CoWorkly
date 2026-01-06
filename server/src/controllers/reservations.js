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

// Get reservations
export const getAllReservations = async (req, res) => {
    try {
        const where = {};
        
        // Non-admin users can only see their own reservations
        if (req.user.role !== 'ADMIN') {
            where.userId = req.user.id;
        } else if (req.query.userId) {
            where.userId = parseInt(req.query.userId);
        }

        if (req.query.seatId) {
            where.seatId = parseInt(req.query.seatId);
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

// Get all reservations with user info (Admin only)
export const getAllReservationsAdmin = async (req, res) => {
    try {
        const reservations = await prisma.reservation.findMany({
            orderBy: { createdAt: 'desc' },
            take: 50,
            include: {
                user: {
                    select: { id: true, name: true, email: true },
                },
                seat: {
                    include: { room: true },
                },
            },
        });

        return res.json(reservations);
    } catch (error) {
        console.error('Error fetching all reservations:', error);
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

        const seat = await prisma.seat.findUnique({ where: { id: parseInt(seatId) } });
        if (!seat) {
            return res.status(400).json({ errors: ['seatId is invalid'] });
        }

        const conflict = await hasConflict(parseInt(seatId), parsedStartTime, parsedEndTime);
        if (conflict) {
            return res.status(409).json({ error: 'Seat is already reserved for this time range' });
        }

        const reservation = await prisma.reservation.create({
            data: {
                userId: req.user.id,
                seatId: parseInt(seatId),
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
        await prisma.notification.create({
            data: {
                userId: req.user.id,
                type: 'CONFIRMATION_RESERVATION',
                title: 'Réservation confirmée',
                message: `Votre réservation pour ${reservation.seat.room.name} (siège ${reservation.seat.number}) a été confirmée.`,
            },
        });

        await updateSeatStatus(parseInt(seatId));

        return res.status(201).json(reservation);
    } catch (error) {
        console.error('Error creating reservation:', error);
        return res.status(500).json({ error: 'Failed to create reservation' });
    }
};

// Cancel reservation
export const cancelReservation = async (req, res) => {
    try {
        const reservation = await prisma.reservation.findUnique({
            where: { id: parseInt(req.params.id) },
        });

        if (!reservation) {
            return res.status(404).json({ error: 'Reservation not found' });
        }

        // Only owner or admin can cancel
        if (reservation.userId !== req.user.id && req.user.role !== 'ADMIN') {
            return res.status(403).json({ error: 'Forbidden' });
        }

        const updated = await prisma.reservation.update({
            where: { id: parseInt(req.params.id) },
            data: { status: 'CANCELLED' },
            include: {
                seat: { include: { room: true } },
            },
        });

        await updateSeatStatus(reservation.seatId);

        return res.json(updated);
    } catch (error) {
        console.error('Error cancelling reservation:', error);
        return res.status(500).json({ error: 'Failed to cancel reservation' });
    }
};

// Delete reservation (Admin only)
export const deleteReservation = async (req, res) => {
    try {
        const reservation = await prisma.reservation.findUnique({
            where: { id: parseInt(req.params.id) },
        });

        if (!reservation) {
            return res.status(404).json({ error: 'Reservation not found' });
        }

        await prisma.reservation.delete({ where: { id: parseInt(req.params.id) } });
        await updateSeatStatus(reservation.seatId);

        return res.status(204).send();
    } catch (error) {
        console.error('Error deleting reservation:', error);
        return res.status(500).json({ error: 'Failed to delete reservation' });
    }
};
