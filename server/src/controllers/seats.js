import { prisma } from "../../lib/prisma.js";

// Get seats (optionally filter by roomId) with reservation status
export const getAllSeats = async (req, res) => {
    try {
        const where = {};
        if (req.query.roomId) {
            where.roomId = parseInt(req.query.roomId);
        }

        const now = new Date();
        
        const seats = await prisma.seat.findMany({
            where,
            orderBy: { number: 'asc' },
            include: {
                reservations: {
                    where: {
                        status: 'CONFIRMED',
                        startTime: { lte: now },
                        endTime: { gte: now }
                    },
                    take: 1
                }
            }
        });

        // Map seats with computed status based on active reservations
        const seatsWithStatus = seats.map(seat => {
            let computedStatus = seat.status;
            
            // If there's an active reservation, mark as RESERVED
            if (seat.reservations && seat.reservations.length > 0) {
                computedStatus = 'RESERVED';
            }
            
            return {
                id: seat.id,
                number: seat.number,
                positionX: seat.positionX,
                positionY: seat.positionY,
                status: computedStatus,
                roomId: seat.roomId
            };
        });

        return res.json(seatsWithStatus);
    } catch (error) {
        console.error('Error fetching seats:', error);
        return res.status(500).json({ error: 'Failed to fetch seats' });
    }
};

// Get single seat
export const getSeatById = async (req, res) => {
    try {
        const seat = await prisma.seat.findUnique({ 
            where: { id: parseInt(req.params.id) } 
        });
        if (!seat) {
            return res.status(404).json({ error: 'Seat not found' });
        }
        return res.json(seat);
    } catch (error) {
        console.error('Error fetching seat:', error);
        return res.status(500).json({ error: 'Failed to fetch seat' });
    }
};

// Update seat (Admin only)
export const updateSeat = async (req, res) => {
    try {
        const { number, status } = req.body;
        const data = {};

        if (number !== undefined) data.number = parseInt(number);
        if (status !== undefined) data.status = status;

        const seat = await prisma.seat.update({
            where: { id: parseInt(req.params.id) },
            data,
        });

        return res.json(seat);
    } catch (error) {
        console.error('Error updating seat:', error);
        return res.status(500).json({ error: 'Failed to update seat' });
    }
};
