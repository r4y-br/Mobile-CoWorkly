import { prisma } from "../../lib/prisma.js";

// Get seats (optionally filter by roomId)
export const getAllSeats = async (req, res) => {
    try {
        const where = {};
        if (req.query.roomId) {
            where.roomId = parseInt(req.query.roomId);
        }

        const seats = await prisma.seat.findMany({
            where,
            orderBy: { number: 'asc' },
        });

        return res.json(seats);
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

// Create seat (Admin only)
export const createSeat = async (req, res) => {
    try {
        const { roomId, number, status } = req.body;

        if (!roomId || number === undefined) {
            return res.status(400).json({ errors: ['roomId and number are required'] });
        }

        const room = await prisma.room.findUnique({ where: { id: parseInt(roomId) } });
        if (!room) {
            return res.status(400).json({ errors: ['roomId is invalid'] });
        }

        const seat = await prisma.seat.create({
            data: {
                roomId: parseInt(roomId),
                number: parseInt(number),
                status: status || 'AVAILABLE',
            },
        });

        return res.status(201).json(seat);
    } catch (error) {
        console.error('Error creating seat:', error);
        return res.status(500).json({ error: 'Failed to create seat' });
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

// Delete seat (Admin only)
export const deleteSeat = async (req, res) => {
    try {
        await prisma.seat.delete({ where: { id: parseInt(req.params.id) } });
        return res.status(204).send();
    } catch (error) {
        console.error('Error deleting seat:', error);
        return res.status(500).json({ error: 'Failed to delete seat' });
    }
};
