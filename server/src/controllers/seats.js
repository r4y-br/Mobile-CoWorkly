import { prisma } from "../../lib/prisma.js";

// Get seats (optionally filter by roomId)
export const getAllSeats = async (req, res) => {
    try {
        const where = {};
        if (req.query.roomId) {
            const parsedRoomId = parseInt(req.query.roomId);
            if (isNaN(parsedRoomId)) {
                return res.status(400).json({ error: 'Invalid roomId query parameter' });
            }
            where.roomId = parsedRoomId;
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
        const id = parseInt(req.params.id);
        if (isNaN(id)) {
            return res.status(400).json({ error: 'Invalid seat ID' });
        }

        const seat = await prisma.seat.findUnique({ 
            where: { id } 
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
        const { roomId, number, status, positionX, positionY } = req.body;

        if (!roomId || number === undefined) {
            return res.status(400).json({ errors: ['roomId and number are required'] });
        }

        const parsedRoomId = parseInt(roomId);
        const parsedNumber = parseInt(number);
        if (isNaN(parsedRoomId) || isNaN(parsedNumber)) {
            return res.status(400).json({ errors: ['roomId and number must be integers'] });
        }

        const room = await prisma.room.findUnique({ where: { id: parsedRoomId } });
        if (!room) {
            return res.status(400).json({ error: 'Room not found' });
        }

        const parsedPosX = positionX != null ? parseFloat(positionX) : null;
        const parsedPosY = positionY != null ? parseFloat(positionY) : null;
        if ((parsedPosX !== null && isNaN(parsedPosX)) || (parsedPosY !== null && isNaN(parsedPosY))) {
            return res.status(400).json({ errors: ['positionX and positionY must be valid numbers'] });
        }

        const seat = await prisma.seat.create({
            data: {
                roomId: parsedRoomId,
                number: parsedNumber,
                status: status || 'AVAILABLE',
                positionX: parsedPosX,
                positionY: parsedPosY,
            },
        });

        return res.status(201).json(seat);
    } catch (error) {
        if (error.code === 'P2002') {
            return res.status(409).json({ error: 'A seat with this number already exists in this room' });
        }
        console.error('Error creating seat:', error);
        return res.status(500).json({ error: 'Failed to create seat' });
    }
};

// Update seat (Admin only)
export const updateSeat = async (req, res) => {
    try {
        const id = parseInt(req.params.id);
        if (isNaN(id)) {
            return res.status(400).json({ error: 'Invalid seat ID' });
        }

        const { number, status } = req.body;
        const data = {};

        if (number !== undefined) {
            const parsedNumber = parseInt(number);
            if (isNaN(parsedNumber)) {
                return res.status(400).json({ error: 'number must be a valid integer' });
            }
            data.number = parsedNumber;
        }
        if (status !== undefined) data.status = status;

        const seat = await prisma.seat.update({
            where: { id },
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
        const id = parseInt(req.params.id);
        if (isNaN(id)) {
            return res.status(400).json({ error: 'Invalid seat ID' });
        }

        const seat = await prisma.seat.findUnique({ where: { id } });
        if (!seat) {
            return res.status(404).json({ error: 'Seat not found' });
        }

        await prisma.seat.delete({ where: { id } });
        return res.status(204).send();
    } catch (error) {
        console.error('Error deleting seat:', error);
        return res.status(500).json({ error: 'Failed to delete seat' });
    }
};
