import { prisma } from "../../lib/prisma.js";

// Get dashboard stats for admin
export const getDashboardStats = async (req, res) => {
    try {
        // Get counts
        const [
            totalUsers,
            totalRooms,
            totalSeats,
            totalReservations,
            activeReservations,
            pendingReservations,
        ] = await Promise.all([
            prisma.user.count(),
            prisma.room.count(),
            prisma.seat.count(),
            prisma.reservation.count(),
            prisma.reservation.count({ where: { status: 'CONFIRMED' } }),
            prisma.reservation.count({ where: { status: 'PENDING' } }),
        ]);

        // Get available seats
        const availableSeats = await prisma.seat.count({
            where: { status: 'AVAILABLE' },
        });

        // Get reservations by day of week (last 7 days)
        const today = new Date();
        const weekAgo = new Date(today);
        weekAgo.setDate(today.getDate() - 7);

        const recentReservations = await prisma.reservation.findMany({
            where: {
                createdAt: { gte: weekAgo },
            },
            select: {
                createdAt: true,
            },
        });

        // Group by day
        const dayNames = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];
        const reservationsByDay = {};
        dayNames.forEach(day => reservationsByDay[day] = 0);
        
        recentReservations.forEach(r => {
            const day = dayNames[r.createdAt.getDay()];
            reservationsByDay[day]++;
        });

        // Get rooms with stats
        const rooms = await prisma.room.findMany({
            include: {
                seats: {
                    select: { status: true },
                },
                _count: {
                    select: {
                        seats: true,
                    },
                },
            },
        });

        const roomsWithStats = rooms.map(room => ({
            id: room.id,
            name: room.name,
            totalSeats: room.seats.length,
            availableSeats: room.seats.filter(s => s.status === 'AVAILABLE').length,
            occupiedSeats: room.seats.filter(s => s.status === 'OCCUPIED' || s.status === 'RESERVED').length,
        }));

        // Get recent reservations for list
        const recentBookings = await prisma.reservation.findMany({
            take: 10,
            orderBy: { createdAt: 'desc' },
            include: {
                user: {
                    select: { id: true, name: true, email: true },
                },
                seat: {
                    include: { room: true },
                },
            },
        });

        return res.json({
            stats: {
                totalUsers,
                totalRooms,
                totalSeats,
                availableSeats,
                totalReservations,
                activeReservations,
                pendingReservations,
            },
            reservationsByDay,
            rooms: roomsWithStats,
            recentBookings: recentBookings.map(b => ({
                id: b.id,
                userName: b.user.name,
                userEmail: b.user.email,
                roomName: b.seat.room.name,
                seatNumber: b.seat.number,
                startTime: b.startTime,
                endTime: b.endTime,
                status: b.status,
                type: b.type,
                createdAt: b.createdAt,
            })),
        });
    } catch (error) {
        console.error('Error fetching dashboard stats:', error);
        return res.status(500).json({ error: 'Failed to fetch dashboard stats' });
    }
};

// Get weekly visitors stats
export const getWeeklyStats = async (req, res) => {
    try {
        const today = new Date();
        const weekAgo = new Date(today);
        weekAgo.setDate(today.getDate() - 7);

        const reservations = await prisma.reservation.findMany({
            where: {
                startTime: { gte: weekAgo },
                status: { in: ['CONFIRMED', 'PENDING'] },
            },
            select: {
                startTime: true,
            },
        });

        const dayNames = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];
        const visitsByDay = {};
        dayNames.forEach(day => visitsByDay[day] = 0);

        reservations.forEach(r => {
            const day = dayNames[r.startTime.getDay()];
            visitsByDay[day]++;
        });

        return res.json({
            weeklyStats: Object.entries(visitsByDay).map(([day, count]) => ({
                day,
                count,
            })),
        });
    } catch (error) {
        console.error('Error fetching weekly stats:', error);
        return res.status(500).json({ error: 'Failed to fetch weekly stats' });
    }
};
