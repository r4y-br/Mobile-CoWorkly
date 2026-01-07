import { prisma } from "../../lib/prisma.js";

// Get all rooms
export const getAllRooms = async (req, res) => {
    try {
        const rooms = await prisma.room.findMany({
            orderBy: { name: 'asc' },
            include: {
                seats: { select: { status: true } },
            },
        });

        const payload = rooms.map((room) => {
            const totalSeats = room.seats.length;
            const availableSeats = room.seats.filter((seat) => seat.status === 'AVAILABLE').length;
            return {
                id: room.id,
                name: room.name,
                description: room.description,
                capacity: room.capacity,
                isAvailable: room.isAvailable,
                totalSeats,
                availableSeats,
            };
        });

        return res.json(payload);
    } catch (error) {
        console.error('Error fetching rooms:', error);
        return res.status(500).json({ error: 'Failed to fetch rooms' });
    }
};

// Get single room by ID
export const getRoomById = async (req, res) => {
    try {
        const room = await prisma.room.findUnique({
            where: { id: parseInt(req.params.id) },
            include: { seats: { select: { status: true } } },
        });

        if (!room) {
            return res.status(404).json({ error: 'Room not found' });
        }

        const totalSeats = room.seats.length;
        const availableSeats = room.seats.filter((seat) => seat.status === 'AVAILABLE').length;

        return res.json({
            id: room.id,
            name: room.name,
            description: room.description,
            capacity: room.capacity,
            isAvailable: room.isAvailable,
            totalSeats,
            availableSeats,
        });
    } catch (error) {
        console.error('Error fetching room:', error);
        return res.status(500).json({ error: 'Failed to fetch room' });
    }
};

// Update room (Admin only)
export const updateRoom = async (req, res) => {
    try {
        const { name, description, capacity, isAvailable } = req.body;
        const data = {};

        if (name !== undefined) data.name = name;
        if (description !== undefined) data.description = description;
        if (capacity !== undefined) data.capacity = parseInt(capacity);
        if (isAvailable !== undefined) data.isAvailable = isAvailable;

        const room = await prisma.room.update({
            where: { id: parseInt(req.params.id) },
            data,
        });

        return res.json(room);
    } catch (error) {
        console.error('Error updating room:', error);
        return res.status(500).json({ error: 'Failed to update room' });
    }
};
