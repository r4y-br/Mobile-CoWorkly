import { prisma } from '../lib/prisma.js';
import bcrypt from 'bcryptjs';

async function main() {
    console.log('🌱 Starting seed...');

    // Create test user: laith@example.com
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash('Laith1818@', salt);

    const user = await prisma.user.upsert({
        where: { email: 'laith@example.com' },
        update: {},
        create: {
            name: 'Laith',
            email: 'laith@example.com',
            password: hashedPassword,
            phone: '+216 12 345 678',
            role: 'USER',
        },
    });
    console.log(`✅ Created user: ${user.email} (ID: ${user.id})`);

    // Create admin user
    const adminPassword = await bcrypt.hash('Admin1818@', salt);
    const admin = await prisma.user.upsert({
        where: { email: 'admin@coworkly.com' },
        update: {},
        create: {
            name: 'Admin',
            email: 'admin@coworkly.com',
            password: adminPassword,
            phone: '+216 99 999 999',
            role: 'ADMIN',
        },
    });
    console.log(`✅ Created admin: ${admin.email} (ID: ${admin.id})`);

    // Create Rooms (Spaces)
    const rooms = await Promise.all([
        prisma.room.upsert({
            where: { id: 1 },
            update: {},
            create: {
                id: 1,
                name: 'Creative Hub',
                description: 'Un espace créatif et inspirant pour les designers et artistes. Lumineux avec vue sur le jardin.',
                capacity: 16,
                isAvailable: true,
            },
        }),
        prisma.room.upsert({
            where: { id: 2 },
            update: {},
            create: {
                id: 2,
                name: 'Tech Space',
                description: 'Espace high-tech équipé pour les développeurs et startups. Connexion fibre ultra-rapide.',
                capacity: 20,
                isAvailable: true,
            },
        }),
        prisma.room.upsert({
            where: { id: 3 },
            update: {},
            create: {
                id: 3,
                name: 'Work Lounge',
                description: 'Espace confortable et détendu pour le travail collaboratif. Canapés et tables basses.',
                capacity: 12,
                isAvailable: true,
            },
        }),
        prisma.room.upsert({
            where: { id: 4 },
            update: {},
            create: {
                id: 4,
                name: 'Meeting Room',
                description: 'Salle de réunion professionnelle avec écran et visioconférence.',
                capacity: 8,
                isAvailable: true,
            },
        }),
    ]);
    console.log(`✅ Created ${rooms.length} rooms`);

    // Create Seats for each room
    const seatsData = [];
    
    // Creative Hub - 16 seats (4x4 grid)
    for (let i = 1; i <= 16; i++) {
        seatsData.push({
            roomId: 1,
            number: i,
            positionX: ((i - 1) % 4) * 0.2 + 0.2,
            positionY: Math.floor((i - 1) / 4) * 0.2 + 0.2,
            status: i <= 12 ? 'AVAILABLE' : (i === 13 ? 'RESERVED' : 'AVAILABLE'),
        });
    }

    // Tech Space - 20 seats (4x5 grid)
    for (let i = 1; i <= 20; i++) {
        seatsData.push({
            roomId: 2,
            number: i,
            positionX: ((i - 1) % 4) * 0.2 + 0.2,
            positionY: Math.floor((i - 1) / 4) * 0.2 + 0.15,
            status: i <= 15 ? 'AVAILABLE' : (i === 16 ? 'OCCUPIED' : 'AVAILABLE'),
        });
    }

    // Work Lounge - 12 seats (3x4 grid)
    for (let i = 1; i <= 12; i++) {
        seatsData.push({
            roomId: 3,
            number: i,
            positionX: ((i - 1) % 3) * 0.25 + 0.2,
            positionY: Math.floor((i - 1) / 3) * 0.2 + 0.2,
            status: 'AVAILABLE',
        });
    }

    // Meeting Room - 8 seats (2x4 grid)
    for (let i = 1; i <= 8; i++) {
        seatsData.push({
            roomId: 4,
            number: i,
            positionX: ((i - 1) % 2) * 0.3 + 0.35,
            positionY: Math.floor((i - 1) / 2) * 0.2 + 0.2,
            status: 'AVAILABLE',
        });
    }

    // Delete existing seats and recreate
    await prisma.seat.deleteMany({});
    await prisma.seat.createMany({ data: seatsData });
    console.log(`✅ Created ${seatsData.length} seats`);

    // Create Notifications for the test user
    const notifications = await Promise.all([
        prisma.notification.create({
            data: {
                userId: user.id,
                type: 'CONFIRMATION_RESERVATION',
                title: 'Réservation confirmée',
                message: 'Votre réservation pour Creative Hub (siège 5) a été confirmée pour demain à 09:00.',
                isRead: false,
            },
        }),
        prisma.notification.create({
            data: {
                userId: user.id,
                type: 'REMINDER_RESERVATION',
                title: 'Rappel de réservation',
                message: 'N\'oubliez pas votre réservation demain à 09:00 dans Tech Space.',
                isRead: false,
            },
        }),
        prisma.notification.create({
            data: {
                userId: user.id,
                type: 'SUBSCRIPTION_UPDATE',
                title: 'Mise à jour abonnement',
                message: 'Votre abonnement mensuel a été renouvelé avec succès.',
                isRead: true,
            },
        }),
        prisma.notification.create({
            data: {
                userId: user.id,
                type: 'CONFIRMATION_RESERVATION',
                title: 'Nouvelle réservation',
                message: 'Bienvenue chez CoWorkly! Votre première réservation est prête.',
                isRead: false,
            },
        }),
    ]);
    console.log(`✅ Created ${notifications.length} notifications for ${user.email}`);

    // Create a sample reservation for the user
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    tomorrow.setHours(9, 0, 0, 0);

    const tomorrowEnd = new Date(tomorrow);
    tomorrowEnd.setHours(17, 0, 0, 0);

    const reservation = await prisma.reservation.create({
        data: {
            userId: user.id,
            seatId: 1, // First seat in Creative Hub
            startTime: tomorrow,
            endTime: tomorrowEnd,
            type: 'DAILY',
            status: 'CONFIRMED',
        },
    });
    console.log(`✅ Created sample reservation (ID: ${reservation.id})`);

    // Create subscriptions
    const now = new Date();
    const activeSubscription = await prisma.subscription.create({
        data: {
            userId: user.id,
            plan: 'MONTHLY',
            status: 'ACTIVE',
            startDate: new Date(now.getTime() - 10 * 24 * 60 * 60 * 1000),
            endDate: new Date(now.getTime() + 20 * 24 * 60 * 60 * 1000),
            approvedBy: admin.id,
            approvedAt: new Date(now.getTime() - 10 * 24 * 60 * 60 * 1000),
        },
    });
    console.log(`✅ Created active subscription for ${user.email}`);

    console.log('\n🎉 Seed completed successfully!');
    console.log('\n📋 Test Credentials:');
    console.log('   User: laith@example.com / Laith1818@');
    console.log('   Admin: admin@coworkly.com / Admin1818@');
}

main()
    .catch((e) => {
        console.error('❌ Seed error:', e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
