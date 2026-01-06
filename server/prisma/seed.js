import { prisma } from '../lib/prisma.js';
import bcrypt from 'bcryptjs';
import { 
    SubscriptionPlan, 
    SubscriptionStatus, 
    ReservationStatus, 
    ReservationType, 
    SeatStatus 
} from '@prisma/client';

async function main() {
    console.log('🌱 Starting seed...');

    // 1. Nettoyage (Optionnel mais recommandé pour éviter les doublons de réservations)
    await prisma.reservation.deleteMany({});
    await prisma.subscription.deleteMany({});
    await prisma.notification.deleteMany({});
    await prisma.seat.deleteMany({});

    // 2. Création des utilisateurs
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
    console.log(`✅ Created user: ${user.email}`);

    // Admin
    await prisma.user.upsert({
        where: { email: 'admin@coworkly.com' },
        update: {},
        create: {
            name: 'Admin',
            email: 'admin@coworkly.com',
            password: await bcrypt.hash('Admin1818@', salt),
            phone: '+216 99 999 999',
            role: 'ADMIN',
        },
    });

    // 3. Création des Salles
    const room1 = await prisma.room.upsert({
        where: { id: 1 },
        update: {},
        create: {
            id: 1,
            name: 'Creative Hub',
            description: 'Espace créatif et inspirant.',
            capacity: 16,
            isAvailable: true,
        },
    });

    // 4. Création des Sièges
    const seatsData = [];
    for (let i = 1; i <= 16; i++) {
        seatsData.push({
            roomId: 1,
            number: i,
            positionX: ((i - 1) % 4) * 0.2 + 0.2,
            positionY: Math.floor((i - 1) / 4) * 0.2 + 0.2,
            status: SeatStatus.AVAILABLE,
        });
    }
    await prisma.seat.createMany({ data: seatsData });
    
    // On récupère UN siège pour les réservations de test
    const firstSeat = await prisma.seat.findFirst({ where: { roomId: 1 } });
    console.log(`✅ Created seats and selected seat #${firstSeat.number} for tests`);

    // 5. Création de l'Abonnement Actif
    const now = new Date();
    const nextMonth = new Date();
    nextMonth.setMonth(now.getMonth() + 1);

    await prisma.subscription.create({
        data: {
            userId: user.id,
            plan: SubscriptionPlan.MONTHLY,
            status: SubscriptionStatus.ACTIVE,
            startDate: now,
            endDate: nextMonth,
        },
    });
    console.log(`✅ Subscription MONTHLY created for Laith`);

    // 6. Création des 10 heures de réservations passées (pour le graphique du Front)
    for (let i = 0; i < 5; i++) {
        const startTime = new Date();
        startTime.setDate(now.getDate() - i);
        startTime.setHours(10, 0, 0);

        const endTime = new Date(startTime);
        endTime.setHours(12, 0, 0); // 2 heures par session

        await prisma.reservation.create({
            data: {
                userId: user.id,
                seatId: firstSeat.id, // Correction ici : on utilise l'ID récupéré
                startTime: startTime,
                endTime: endTime,
                type: ReservationType.HOURLY,
                status: ReservationStatus.CONFIRMED,
            },
        });
    }

    // 7. Notifications
    await prisma.notification.create({
        data: {
            userId: user.id,
            type: 'CONFIRMATION_RESERVATION',
            title: 'Bienvenue !',
            message: 'Votre abonnement Pro est maintenant actif.',
            isRead: false,
        },
    });

    console.log('\n🎉 Seed completed successfully!');
}

main()
    .catch((e) => {
        console.error('❌ Seed error:', e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });