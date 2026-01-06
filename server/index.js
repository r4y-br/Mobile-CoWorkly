import express from 'express';
import dotenv from 'dotenv';
import cors from 'cors';
import authRoutes from './src/routes/auth.js';
import roomsRoutes from './src/routes/rooms.js';
import seatsRoutes from './src/routes/seats.js';
import reservationsRoutes from './src/routes/reservations.js';
import notificationsRoutes from './src/routes/notifications.js';
import subscriptionRoutes from './src/routes/subscriptionRoutes.js';
dotenv.config();

const app = express();
const PORT = process.env.PORT || 4000; // Utilise le port du .env, sinon 4000 par défaut

app.listen(PORT, () => {
    console.log(`Server is running on port ::${PORT}`);
});

// middlewares
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// routes
app.use('/auth', authRoutes);
app.use('/rooms', roomsRoutes);
app.use('/seats', seatsRoutes);
app.use('/reservations', reservationsRoutes);
app.use('/notifications', notificationsRoutes);
app.use('/subscriptions', subscriptionRoutes);
// just a health check endpoint
app.get('/health', (req, res) => {
    res.status(200).json({ status: 'OK', message: 'Server is running' });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({ message: 'Route not found' });
});

// error handler
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ message: 'Something went wrong!' });
});

