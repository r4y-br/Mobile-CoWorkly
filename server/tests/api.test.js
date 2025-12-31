/**
 * CoWorkly API Integration Tests
 * 
 * Comprehensive test suite for all API endpoints
 * Run with: npm test
 */

import { describe, test, expect, beforeAll } from 'vitest';
import request from 'supertest';
import express from 'express';
import cors from 'cors';

// Import routes
import authRoutes from '../src/routes/auth.js';
import roomsRoutes from '../src/routes/rooms.js';
import seatsRoutes from '../src/routes/seats.js';
import reservationsRoutes from '../src/routes/reservations.js';
import notificationsRoutes from '../src/routes/notifications.js';

// Create test app
const app = express();
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use('/auth', authRoutes);
app.use('/rooms', roomsRoutes);
app.use('/seats', seatsRoutes);
app.use('/reservations', reservationsRoutes);
app.use('/notifications', notificationsRoutes);

app.get('/health', (req, res) => {
    res.status(200).json({ status: 'OK', message: 'Server is running' });
});

app.use((req, res) => {
    res.status(404).json({ message: 'Route not found' });
});

// Test data storage - shared across all tests
const timestamp = Date.now();
const testUser = {
    name: 'Test User',
    email: `testuser_${timestamp}@example.com`,
    password: 'TestPass123!',
    retypedPassword: 'TestPass123!'
};

// Shared state
let authToken = null;
let refreshTokenValue = null;

// ============================================
// HEALTH CHECK TESTS
// ============================================
describe('Health Check', () => {
    test('GET /health - should return OK status', async () => {
        const res = await request(app).get('/health');
        
        expect(res.statusCode).toBe(200);
        expect(res.body).toHaveProperty('status', 'OK');
        expect(res.body).toHaveProperty('message', 'Server is running');
    });
});

// ============================================
// AUTH TESTS - Registration & Login
// ============================================
describe('Authentication API', () => {
    
    describe('POST /auth/register', () => {
        test('should register a new user successfully', async () => {
            const res = await request(app)
                .post('/auth/register')
                .send(testUser);
            
            expect(res.statusCode).toBe(201);
            expect(res.body).toHaveProperty('message', 'User registered successfully.');
            expect(res.body).toHaveProperty('user');
            expect(res.body).toHaveProperty('accessToken');
            expect(res.body).toHaveProperty('refreshToken');
            expect(res.body).toHaveProperty('token'); // Alias for Flutter
            expect(res.body.user).toHaveProperty('email', testUser.email);
            expect(res.body.user).toHaveProperty('role', 'USER');
            
            // Save for later tests
            authToken = res.body.accessToken;
            refreshTokenValue = res.body.refreshToken;
        });

        test('should fail with missing fields', async () => {
            const res = await request(app)
                .post('/auth/register')
                .send({ email: 'test@test.com' });
            
            expect(res.statusCode).toBe(400);
            expect(res.body).toHaveProperty('message', 'All fields are required.');
        });

        test('should fail with mismatched passwords', async () => {
            const res = await request(app)
                .post('/auth/register')
                .send({
                    name: 'Test',
                    email: 'new@test.com',
                    password: 'Password123!',
                    retypedPassword: 'Different123!'
                });
            
            expect(res.statusCode).toBe(400);
            expect(res.body).toHaveProperty('message', 'Passwords do not match.');
        });

        test('should fail with invalid email format', async () => {
            const res = await request(app)
                .post('/auth/register')
                .send({
                    name: 'Test',
                    email: 'invalid-email',
                    password: 'Password123!',
                    retypedPassword: 'Password123!'
                });
            
            expect(res.statusCode).toBe(400);
            expect(res.body).toHaveProperty('message', 'Invalid email format.');
        });

        test('should fail with weak password', async () => {
            const res = await request(app)
                .post('/auth/register')
                .send({
                    name: 'Test',
                    email: 'valid@test.com',
                    password: '123',
                    retypedPassword: '123'
                });
            
            expect(res.statusCode).toBe(400);
            expect(res.body).toHaveProperty('message', 'Password does not meet complexity requirements.');
        });

        test('should fail with duplicate email', async () => {
            const res = await request(app)
                .post('/auth/register')
                .send(testUser);
            
            expect(res.statusCode).toBe(400);
            expect(res.body).toHaveProperty('message', 'Email is already registered.');
        });
    });

    describe('POST /auth/login', () => {
        test('should sign in successfully', async () => {
            const res = await request(app)
                .post('/auth/login')
                .send({
                    email: testUser.email,
                    password: testUser.password
                });
            
            expect(res.statusCode).toBe(200);
            expect(res.body).toHaveProperty('message', 'Sign-in successful.');
            expect(res.body).toHaveProperty('user');
            expect(res.body).toHaveProperty('accessToken');
            expect(res.body).toHaveProperty('refreshToken');
            expect(res.body).toHaveProperty('token');
            
            // Update tokens
            authToken = res.body.accessToken;
            refreshTokenValue = res.body.refreshToken;
        });

        test('should fail with missing credentials', async () => {
            const res = await request(app)
                .post('/auth/login')
                .send({ email: testUser.email });
            
            expect(res.statusCode).toBe(400);
            expect(res.body).toHaveProperty('message', 'Email and password are required.');
        });

        test('should fail with wrong password', async () => {
            const res = await request(app)
                .post('/auth/login')
                .send({
                    email: testUser.email,
                    password: 'WrongPassword123!'
                });
            
            expect(res.statusCode).toBe(401);
            expect(res.body).toHaveProperty('message', 'Invalid email or password.');
        });

        test('should fail with non-existent email', async () => {
            const res = await request(app)
                .post('/auth/login')
                .send({
                    email: 'nonexistent@test.com',
                    password: 'Password123!'
                });
            
            expect(res.statusCode).toBe(401);
            expect(res.body).toHaveProperty('message', 'Invalid email or password.');
        });
    });

    describe('POST /auth/refresh', () => {
        test('should refresh access token', async () => {
            const res = await request(app)
                .post('/auth/refresh')
                .send({ refreshToken: refreshTokenValue });
            
            expect(res.statusCode).toBe(200);
            expect(res.body).toHaveProperty('accessToken');
            
            // Update auth token
            authToken = res.body.accessToken;
        });

        test('should fail with invalid refresh token', async () => {
            const res = await request(app)
                .post('/auth/refresh')
                .send({ refreshToken: 'invalid-token' });
            
            expect([401, 403]).toContain(res.statusCode);
        });

        test('should fail without refresh token', async () => {
            const res = await request(app)
                .post('/auth/refresh')
                .send({});
            
            expect([400, 401]).toContain(res.statusCode);
        });
    });

    describe('GET /auth/me', () => {
        test('should get user profile', async () => {
            const res = await request(app)
                .get('/auth/me')
                .set('Authorization', `Bearer ${authToken}`);
            
            expect(res.statusCode).toBe(200);
            expect(res.body).toHaveProperty('user');
            expect(res.body.user).toHaveProperty('email', testUser.email);
        });

        test('should fail without auth token', async () => {
            const res = await request(app).get('/auth/me');
            
            expect(res.statusCode).toBe(401);
        });

        test('should fail with invalid token', async () => {
            const res = await request(app)
                .get('/auth/me')
                .set('Authorization', 'Bearer invalid-token');
            
            expect([401, 403]).toContain(res.statusCode);
        });

        test('should fail with malformed authorization header', async () => {
            const res = await request(app)
                .get('/auth/me')
                .set('Authorization', 'NotBearer token');
            
            expect(res.statusCode).toBe(401);
        });
    });

    describe('PUT /auth/profile', () => {
        test('should update user profile', async () => {
            const res = await request(app)
                .put('/auth/profile')
                .set('Authorization', `Bearer ${authToken}`)
                .send({ name: 'Updated Name', phone: '+1234567890' });
            
            expect(res.statusCode).toBe(200);
            expect(res.body).toHaveProperty('user');
            expect(res.body.user).toHaveProperty('name', 'Updated Name');
        });

        test('should fail without authentication', async () => {
            const res = await request(app)
                .put('/auth/profile')
                .send({ name: 'Updated Name' });
            
            expect(res.statusCode).toBe(401);
        });
    });
});

// ============================================
// ROOMS TESTS
// ============================================
describe('Rooms API', () => {
    
    describe('GET /rooms', () => {
        test('should get all rooms (public endpoint)', async () => {
            const res = await request(app).get('/rooms');
            
            expect(res.statusCode).toBe(200);
            expect(Array.isArray(res.body)).toBe(true);
        });

        test('should include room statistics', async () => {
            const res = await request(app).get('/rooms');
            
            expect(res.statusCode).toBe(200);
            if (res.body.length > 0) {
                const room = res.body[0];
                expect(room).toHaveProperty('id');
                expect(room).toHaveProperty('name');
                expect(room).toHaveProperty('capacity');
                expect(room).toHaveProperty('totalSeats');
                expect(room).toHaveProperty('availableSeats');
            }
        });
    });

    describe('POST /rooms (Admin only)', () => {
        test('should fail without authentication', async () => {
            const res = await request(app)
                .post('/rooms')
                .send({ name: 'Test Room', capacity: 10 });
            
            expect(res.statusCode).toBe(401);
        });

        test('should fail for non-admin user', async () => {
            const res = await request(app)
                .post('/rooms')
                .set('Authorization', `Bearer ${authToken}`)
                .send({ name: 'Test Room', capacity: 10 });
            
            expect(res.statusCode).toBe(403);
        });
    });

    describe('GET /rooms/:id', () => {
        test('should return 404 for non-existent room', async () => {
            const res = await request(app).get('/rooms/99999');
            
            expect(res.statusCode).toBe(404);
            expect(res.body).toHaveProperty('error', 'Room not found');
        });

        test('should return room details for existing room', async () => {
            const listRes = await request(app).get('/rooms');
            
            if (listRes.body.length > 0) {
                const roomId = listRes.body[0].id;
                const res = await request(app).get(`/rooms/${roomId}`);
                
                expect(res.statusCode).toBe(200);
                expect(res.body).toHaveProperty('id', roomId);
                expect(res.body).toHaveProperty('name');
            }
        });
    });

    describe('PATCH /rooms/:id (Admin only)', () => {
        test('should fail without authentication', async () => {
            const res = await request(app)
                .patch('/rooms/1')
                .send({ name: 'Updated Room' });
            
            expect(res.statusCode).toBe(401);
        });

        test('should fail for non-admin user', async () => {
            const res = await request(app)
                .patch('/rooms/1')
                .set('Authorization', `Bearer ${authToken}`)
                .send({ name: 'Updated Room' });
            
            expect(res.statusCode).toBe(403);
        });
    });

    describe('DELETE /rooms/:id (Admin only)', () => {
        test('should fail without authentication', async () => {
            const res = await request(app).delete('/rooms/1');
            
            expect(res.statusCode).toBe(401);
        });

        test('should fail for non-admin user', async () => {
            const res = await request(app)
                .delete('/rooms/1')
                .set('Authorization', `Bearer ${authToken}`);
            
            expect(res.statusCode).toBe(403);
        });
    });
});

// ============================================
// SEATS TESTS
// ============================================
describe('Seats API', () => {
    
    describe('GET /seats', () => {
        test('should get all seats (public endpoint)', async () => {
            const res = await request(app).get('/seats');
            
            expect(res.statusCode).toBe(200);
            expect(Array.isArray(res.body)).toBe(true);
        });

        test('should filter seats by roomId', async () => {
            const res = await request(app).get('/seats?roomId=1');
            
            expect(res.statusCode).toBe(200);
            expect(Array.isArray(res.body)).toBe(true);
            res.body.forEach(seat => {
                expect(seat.roomId).toBe(1);
            });
        });

        test('should return seat details', async () => {
            const res = await request(app).get('/seats');
            
            expect(res.statusCode).toBe(200);
            if (res.body.length > 0) {
                const seat = res.body[0];
                expect(seat).toHaveProperty('id');
                expect(seat).toHaveProperty('number');
                expect(seat).toHaveProperty('status');
                expect(seat).toHaveProperty('roomId');
            }
        });
    });

    describe('POST /seats (Admin only)', () => {
        test('should fail without authentication', async () => {
            const res = await request(app)
                .post('/seats')
                .send({ roomId: 1, number: 1 });
            
            expect(res.statusCode).toBe(401);
        });

        test('should fail for non-admin user', async () => {
            const res = await request(app)
                .post('/seats')
                .set('Authorization', `Bearer ${authToken}`)
                .send({ roomId: 1, number: 1 });
            
            expect(res.statusCode).toBe(403);
        });
    });

    describe('GET /seats/:id', () => {
        test('should return 404 for non-existent seat', async () => {
            const res = await request(app).get('/seats/99999');
            
            expect(res.statusCode).toBe(404);
            expect(res.body).toHaveProperty('error', 'Seat not found');
        });

        test('should return seat details for existing seat', async () => {
            const listRes = await request(app).get('/seats');
            
            if (listRes.body.length > 0) {
                const seatId = listRes.body[0].id;
                const res = await request(app).get(`/seats/${seatId}`);
                
                expect(res.statusCode).toBe(200);
                expect(res.body).toHaveProperty('id', seatId);
            }
        });
    });

    describe('PATCH /seats/:id (Admin only)', () => {
        test('should fail without authentication', async () => {
            const res = await request(app)
                .patch('/seats/1')
                .send({ status: 'AVAILABLE' });
            
            expect(res.statusCode).toBe(401);
        });
    });

    describe('DELETE /seats/:id (Admin only)', () => {
        test('should fail without authentication', async () => {
            const res = await request(app).delete('/seats/1');
            
            expect(res.statusCode).toBe(401);
        });
    });
});

// ============================================
// RESERVATIONS TESTS
// ============================================
describe('Reservations API', () => {
    
    describe('GET /reservations', () => {
        test('should require authentication', async () => {
            const res = await request(app).get('/reservations');
            
            expect(res.statusCode).toBe(401);
        });

        test('should get user reservations', async () => {
            const res = await request(app)
                .get('/reservations')
                .set('Authorization', `Bearer ${authToken}`);
            
            expect(res.statusCode).toBe(200);
            expect(Array.isArray(res.body)).toBe(true);
        });
    });

    describe('POST /reservations', () => {
        test('should require authentication', async () => {
            const res = await request(app)
                .post('/reservations')
                .send({ seatId: 1, startTime: new Date(), endTime: new Date() });
            
            expect(res.statusCode).toBe(401);
        });

        test('should fail with missing seatId', async () => {
            const res = await request(app)
                .post('/reservations')
                .set('Authorization', `Bearer ${authToken}`)
                .send({
                    startTime: new Date().toISOString(),
                    endTime: new Date(Date.now() + 3600000).toISOString()
                });
            
            expect(res.statusCode).toBe(400);
            expect(res.body).toHaveProperty('errors');
            expect(res.body.errors).toContain('seatId is required');
        });

        test('should fail with invalid seatId', async () => {
            const startTime = new Date(Date.now() + 86400000);
            const endTime = new Date(startTime.getTime() + 3600000);
            
            const res = await request(app)
                .post('/reservations')
                .set('Authorization', `Bearer ${authToken}`)
                .send({
                    seatId: 99999,
                    startTime: startTime.toISOString(),
                    endTime: endTime.toISOString()
                });
            
            expect(res.statusCode).toBe(400);
            expect(res.body).toHaveProperty('errors');
            expect(res.body.errors).toContain('seatId is invalid');
        });

        test('should fail when endTime is before startTime', async () => {
            const seatsRes = await request(app).get('/seats');
            if (seatsRes.body.length === 0) {
                return;
            }
            
            const seatId = seatsRes.body[0].id;
            const startTime = new Date(Date.now() + 86400000);
            const endTime = new Date(startTime.getTime() - 3600000);
            
            const res = await request(app)
                .post('/reservations')
                .set('Authorization', `Bearer ${authToken}`)
                .send({
                    seatId,
                    startTime: startTime.toISOString(),
                    endTime: endTime.toISOString()
                });
            
            expect(res.statusCode).toBe(400);
            expect(res.body).toHaveProperty('errors');
            expect(res.body.errors).toContain('endTime must be after startTime');
        });

        test('should create reservation with valid data', async () => {
            const seatsRes = await request(app).get('/seats');
            if (seatsRes.body.length === 0) {
                return;
            }
            
            const seatId = seatsRes.body[0].id;
            const startTime = new Date(Date.now() + 86400000 * 30);
            const endTime = new Date(startTime.getTime() + 3600000);
            
            const res = await request(app)
                .post('/reservations')
                .set('Authorization', `Bearer ${authToken}`)
                .send({
                    seatId,
                    startTime: startTime.toISOString(),
                    endTime: endTime.toISOString(),
                    type: 'HOURLY'
                });
            
            expect([201, 409]).toContain(res.statusCode);
            
            if (res.statusCode === 201) {
                expect(res.body).toHaveProperty('id');
                expect(res.body).toHaveProperty('seatId', seatId);
                expect(res.body).toHaveProperty('status', 'CONFIRMED');
            }
        });

        test('should accept date + time format from Flutter app', async () => {
            const seatsRes = await request(app).get('/seats');
            if (seatsRes.body.length === 0) {
                return;
            }
            
            const seatId = seatsRes.body[0].id;
            
            const res = await request(app)
                .post('/reservations')
                .set('Authorization', `Bearer ${authToken}`)
                .send({
                    seatId,
                    date: '2026-06-15',
                    startTime: '09:00',
                    endTime: '10:00',
                    type: 'HOURLY'
                });
            
            expect([201, 409]).toContain(res.statusCode);
        });
    });

    describe('PATCH /reservations/:id/cancel', () => {
        test('should require authentication', async () => {
            const res = await request(app).patch('/reservations/1/cancel');
            
            expect(res.statusCode).toBe(401);
        });
    });
});

// ============================================
// NOTIFICATIONS TESTS
// ============================================
describe('Notifications API', () => {
    
    describe('GET /notifications', () => {
        test('should require authentication', async () => {
            const res = await request(app).get('/notifications');
            
            expect(res.statusCode).toBe(401);
        });

        test('should get user notifications', async () => {
            const res = await request(app)
                .get('/notifications')
                .set('Authorization', `Bearer ${authToken}`);
            
            expect(res.statusCode).toBe(200);
            expect(Array.isArray(res.body)).toBe(true);
        });

        test('should filter unread notifications', async () => {
            const res = await request(app)
                .get('/notifications?unreadOnly=true')
                .set('Authorization', `Bearer ${authToken}`);
            
            expect(res.statusCode).toBe(200);
            expect(Array.isArray(res.body)).toBe(true);
        });

        test('should return mapped notification format', async () => {
            const res = await request(app)
                .get('/notifications')
                .set('Authorization', `Bearer ${authToken}`);
            
            expect(res.statusCode).toBe(200);
            if (res.body.length > 0) {
                const notification = res.body[0];
                expect(notification).toHaveProperty('id');
                expect(notification).toHaveProperty('type');
                expect(notification).toHaveProperty('content');
                expect(notification).toHaveProperty('sentAt');
            }
        });
    });

    describe('PATCH /notifications/read-all', () => {
        test('should require authentication', async () => {
            const res = await request(app).patch('/notifications/read-all');
            
            expect(res.statusCode).toBe(401);
        });

        test('should mark all as read', async () => {
            const res = await request(app)
                .patch('/notifications/read-all')
                .set('Authorization', `Bearer ${authToken}`);
            
            expect(res.statusCode).toBe(204);
        });
    });

    describe('PATCH /notifications/:id/read', () => {
        test('should require authentication', async () => {
            const res = await request(app).patch('/notifications/1/read');
            
            expect(res.statusCode).toBe(401);
        });

        test('should return 404 for non-existent notification', async () => {
            const res = await request(app)
                .patch('/notifications/99999/read')
                .set('Authorization', `Bearer ${authToken}`);
            
            expect(res.statusCode).toBe(404);
            expect(res.body).toHaveProperty('error', 'Notification not found');
        });
    });

    describe('DELETE /notifications/:id', () => {
        test('should require authentication', async () => {
            const res = await request(app).delete('/notifications/1');
            
            expect(res.statusCode).toBe(401);
        });

        test('should return 404 for non-existent notification', async () => {
            const res = await request(app)
                .delete('/notifications/99999')
                .set('Authorization', `Bearer ${authToken}`);
            
            expect(res.statusCode).toBe(404);
            expect(res.body).toHaveProperty('error', 'Notification not found');
        });
    });

    describe('DELETE /notifications', () => {
        test('should require authentication', async () => {
            const res = await request(app).delete('/notifications');
            
            expect(res.statusCode).toBe(401);
        });

        test('should delete all notifications', async () => {
            const res = await request(app)
                .delete('/notifications')
                .set('Authorization', `Bearer ${authToken}`);
            
            expect(res.statusCode).toBe(204);
        });
    });
});

// ============================================
// LOGOUT TEST (at the end to preserve session)
// ============================================
describe('Logout', () => {
    test('POST /auth/logout - should require authentication', async () => {
        const res = await request(app).post('/auth/logout');
        
        expect(res.statusCode).toBe(401);
    });

    test('POST /auth/logout - should logout successfully', async () => {
        const res = await request(app)
            .post('/auth/logout')
            .set('Authorization', `Bearer ${authToken}`);
        
        expect(res.statusCode).toBe(200);
        expect(res.body).toHaveProperty('message', 'Logged out successfully.');
    });
});

// ============================================
// ERROR HANDLING
// ============================================
describe('Error Handling', () => {
    test('should return 404 for unknown routes', async () => {
        const res = await request(app).get('/unknown-route');
        
        expect(res.statusCode).toBe(404);
    });

    test('should return 404 for unknown nested routes', async () => {
        const res = await request(app).get('/auth/unknown');
        
        expect(res.statusCode).toBe(404);
    });
});
