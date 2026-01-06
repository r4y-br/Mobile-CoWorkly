# CoWorkly API Documentation

## Base URL
```
http://localhost:4000
```

## Authentication

All protected endpoints require a JWT token in the Authorization header:
```
Authorization: Bearer <your_jwt_token>
```

---

## Authentication Endpoints

### Register User
**POST** `/auth/register`

Register a new user account.

**Request Body:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "SecurePass123!",
  "retypedPassword": "SecurePass123!",
  "phone": "+33612345678"
}
```

**Response:** `201 Created`
```json
{
  "message": "User registered successfully.",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "role": "USER",
    "createdAt": "2025-01-06T10:00:00.000Z"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### Login
**POST** `/auth/login`

Authenticate and receive access tokens.

**Request Body:**
```json
{
  "email": "john@example.com",
  "password": "SecurePass123!"
}
```

**Response:** `200 OK`
```json
{
  "message": "Sign-in successful.",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "role": "USER",
    "createdAt": "2025-01-06T10:00:00.000Z"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### Refresh Token
**POST** `/auth/refresh`

Get a new access token using refresh token.

**Request Body:**
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response:** `200 OK`
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### Get Profile
**GET** `/auth/me`
🔒 *Protected*

Get current user profile.

**Response:** `200 OK`
```json
{
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "+33612345678",
    "role": "USER",
    "createdAt": "2025-01-06T10:00:00.000Z"
  }
}
```

### Update Profile
**PUT** `/auth/profile`
🔒 *Protected*

Update user profile information.

**Request Body:**
```json
{
  "name": "John Updated",
  "phone": "+33698765432"
}
```

**Response:** `200 OK`
```json
{
  "message": "Profile updated successfully.",
  "user": {
    "id": 1,
    "name": "John Updated",
    "email": "john@example.com",
    "phone": "+33698765432",
    "role": "USER",
    "createdAt": "2025-01-06T10:00:00.000Z"
  }
}
```

### Logout
**POST** `/auth/logout`
🔒 *Protected*

Logout and invalidate refresh token.

**Response:** `200 OK`
```json
{
  "message": "Logged out successfully."
}
```

---

## Room Endpoints

### Get All Rooms
**GET** `/rooms`

Get list of all rooms with availability info.

**Response:** `200 OK`
```json
[
  {
    "id": 1,
    "name": "Creative Hub",
    "description": "A creative space for designers",
    "capacity": 16,
    "isAvailable": true,
    "totalSeats": 16,
    "availableSeats": 12
  }
]
```

### Get Room by ID
**GET** `/rooms/:id`

Get detailed information about a specific room.

**Response:** `200 OK`
```json
{
  "id": 1,
  "name": "Creative Hub",
  "description": "A creative space for designers",
  "capacity": 16,
  "isAvailable": true,
  "totalSeats": 16,
  "availableSeats": 12
}
```

### Create Room
**POST** `/rooms`
🔒 *Admin Only*

Create a new room.

**Request Body:**
```json
{
  "name": "New Room",
  "description": "Room description",
  "capacity": 20
}
```

**Response:** `201 Created`

### Update Room
**PATCH** `/rooms/:id`
🔒 *Admin Only*

Update room information.

**Request Body:**
```json
{
  "name": "Updated Room Name",
  "isAvailable": false
}
```

**Response:** `200 OK`

### Delete Room
**DELETE** `/rooms/:id`
🔒 *Admin Only*

Delete a room.

**Response:** `204 No Content`

---

## Seat Endpoints

### Get All Seats
**GET** `/seats?roomId=1`

Get seats, optionally filtered by room.

**Query Parameters:**
- `roomId` (optional): Filter seats by room ID

**Response:** `200 OK`
```json
[
  {
    "id": 1,
    "number": 1,
    "positionX": 0.2,
    "positionY": 0.2,
    "status": "AVAILABLE",
    "roomId": 1
  }
]
```

### Get Seat by ID
**GET** `/seats/:id`

Get specific seat information.

**Response:** `200 OK`

### Create Seat
**POST** `/seats`
🔒 *Admin Only*

Create a new seat.

**Request Body:**
```json
{
  "roomId": 1,
  "number": 17,
  "status": "AVAILABLE",
  "positionX": 0.5,
  "positionY": 0.5
}
```

**Response:** `201 Created`

### Update Seat
**PATCH** `/seats/:id`
🔒 *Admin Only*

Update seat information.

**Request Body:**
```json
{
  "status": "MAINTENANCE"
}
```

**Response:** `200 OK`

### Delete Seat
**DELETE** `/seats/:id`
🔒 *Admin Only*

Delete a seat.

**Response:** `204 No Content`

---

## Reservation Endpoints

### Get Reservations
**GET** `/reservations?seatId=1&userId=5`
🔒 *Protected*

Get reservations. Users see only their own, admins see all.

**Query Parameters:**
- `seatId` (optional): Filter by seat
- `userId` (optional, admin only): Filter by user

**Response:** `200 OK`
```json
[
  {
    "id": 1,
    "startTime": "2025-01-07T09:00:00.000Z",
    "endTime": "2025-01-07T17:00:00.000Z",
    "type": "DAILY",
    "status": "CONFIRMED",
    "userId": 1,
    "seatId": 1,
    "seat": {
      "id": 1,
      "number": 1,
      "room": {
        "id": 1,
        "name": "Creative Hub"
      }
    }
  }
]
```

### Create Reservation
**POST** `/reservations`
🔒 *Protected*

Create a new reservation.

**Request Body (Option 1):**
```json
{
  "seatId": 1,
  "date": "2025-01-08",
  "startTime": "09:00",
  "endTime": "17:00",
  "type": "DAILY"
}
```

**Request Body (Option 2):**
```json
{
  "seatId": 1,
  "startTime": "2025-01-08T09:00:00.000Z",
  "endTime": "2025-01-08T17:00:00.000Z",
  "type": "HOURLY"
}
```

**Response:** `201 Created`

### Cancel Reservation
**PATCH** `/reservations/:id/cancel`
🔒 *Protected*

Cancel a reservation (owner or admin only).

**Response:** `200 OK`

### Delete Reservation
**DELETE** `/reservations/:id`
🔒 *Admin Only*

Permanently delete a reservation.

**Response:** `204 No Content`

---

## Subscription Endpoints

### Get My Subscriptions
**GET** `/subscriptions/my`
🔒 *Protected*

Get current user's subscriptions.

**Response:** `200 OK`
```json
[
  {
    "id": 1,
    "plan": "MONTHLY",
    "status": "ACTIVE",
    "startDate": "2025-01-01T00:00:00.000Z",
    "endDate": "2025-02-01T00:00:00.000Z",
    "userId": 1,
    "approvedBy": 2,
    "approvedAt": "2025-01-01T00:00:00.000Z",
    "createdAt": "2025-01-01T00:00:00.000Z"
  }
]
```

### Get All Subscriptions
**GET** `/subscriptions?status=ACTIVE&userId=5`
🔒 *Admin Only*

Get all subscriptions with optional filters.

**Query Parameters:**
- `status` (optional): Filter by status (PENDING, ACTIVE, SUSPENDED, EXPIRED, CANCELLED)
- `userId` (optional): Filter by user

**Response:** `200 OK`

### Get Subscription by ID
**GET** `/subscriptions/:id`
🔒 *Protected*

Get specific subscription (owner or admin only).

**Response:** `200 OK`

### Create Subscription
**POST** `/subscriptions`
🔒 *Protected*

Request a new subscription.

**Request Body:**
```json
{
  "plan": "MONTHLY"
}
```

**Valid plans:** `MONTHLY`, `QUARTERLY`, `SEMI_ANNUAL`

**Response:** `201 Created`

### Approve Subscription
**PATCH** `/subscriptions/:id/approve`
🔒 *Admin Only*

Approve a pending subscription.

**Response:** `200 OK`

### Cancel Subscription
**PATCH** `/subscriptions/:id/cancel`
🔒 *Protected*

Cancel a subscription (owner or admin).

**Response:** `200 OK`

### Suspend Subscription
**PATCH** `/subscriptions/:id/suspend`
🔒 *Admin Only*

Suspend an active subscription.

**Response:** `200 OK`

### Delete Subscription
**DELETE** `/subscriptions/:id`
🔒 *Admin Only*

Permanently delete a subscription.

**Response:** `204 No Content`

---

## Notification Endpoints

### Get Notifications
**GET** `/notifications?unreadOnly=true`
🔒 *Protected*

Get user notifications.

**Query Parameters:**
- `unreadOnly` (optional): Filter to only unread notifications

**Response:** `200 OK`
```json
[
  {
    "id": 1,
    "type": "CONFIRMATION_RESERVATION",
    "content": "Your reservation has been confirmed",
    "sentAt": "2025-01-06T10:00:00.000Z",
    "readAt": null
  }
]
```

### Mark as Read
**PATCH** `/notifications/:id/read`
🔒 *Protected*

Mark a notification as read.

**Response:** `200 OK`

### Mark All as Read
**PATCH** `/notifications/read-all`
🔒 *Protected*

Mark all user notifications as read.

**Response:** `204 No Content`

### Delete Notification
**DELETE** `/notifications/:id`
🔒 *Protected*

Delete a specific notification.

**Response:** `204 No Content`

### Delete All Notifications
**DELETE** `/notifications/all`
🔒 *Protected*

Delete all user notifications.

**Response:** `204 No Content`

---

## User Management Endpoints (Admin Only)

### Get All Users
**GET** `/users?role=USER`
🔒 *Admin Only*

Get list of all users.

**Query Parameters:**
- `role` (optional): Filter by role (USER, ADMIN)

**Response:** `200 OK`
```json
[
  {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "+33612345678",
    "role": "USER",
    "createdAt": "2025-01-06T10:00:00.000Z",
    "updatedAt": "2025-01-06T10:00:00.000Z",
    "_count": {
      "reservations": 5,
      "subscriptions": 1
    }
  }
]
```

### Get User Stats
**GET** `/users/stats`
🔒 *Admin Only*

Get system-wide user statistics.

**Response:** `200 OK`
```json
{
  "users": {
    "total": 150,
    "admins": 5,
    "regular": 145
  },
  "subscriptions": {
    "active": 89
  },
  "reservations": {
    "total": 1250,
    "pending": 15,
    "confirmed": 102
  }
}
```

### Get User by ID
**GET** `/users/:id`
🔒 *Admin Only*

Get detailed user information.

**Response:** `200 OK`

### Create User
**POST** `/users`
🔒 *Admin Only*

Create a new user.

**Request Body:**
```json
{
  "name": "New User",
  "email": "newuser@example.com",
  "password": "SecurePass123!",
  "phone": "+33612345678",
  "role": "USER"
}
```

**Response:** `201 Created`

### Update User
**PATCH** `/users/:id`
🔒 *Admin Only*

Update user information.

**Request Body:**
```json
{
  "name": "Updated Name",
  "role": "ADMIN",
  "password": "NewPassword123!"
}
```

**Response:** `200 OK`

### Delete User
**DELETE** `/users/:id`
🔒 *Admin Only*

Delete a user (cannot delete self).

**Response:** `204 No Content`

---

## Error Responses

All endpoints may return error responses:

### 400 Bad Request
```json
{
  "message": "Validation error message",
  "errors": ["Field-specific error messages"]
}
```

### 401 Unauthorized
```json
{
  "message": "Authentication required"
}
```

### 403 Forbidden
```json
{
  "error": "Access denied"
}
```

### 404 Not Found
```json
{
  "error": "Resource not found"
}
```

### 409 Conflict
```json
{
  "error": "Resource conflict (e.g., seat already reserved)"
}
```

### 500 Internal Server Error
```json
{
  "message": "Internal server error"
}
```

---

## Rate Limiting

The API implements rate limiting to prevent abuse. Default limits apply per IP address.

---

## Status Enums

### SeatStatus
- `AVAILABLE` - Seat is free to reserve
- `OCCUPIED` - Seat is currently in use
- `RESERVED` - Seat has an active reservation
- `MAINTENANCE` - Seat is under maintenance

### ReservationType
- `HOURLY` - Reservation by hours
- `DAILY` - Reservation by days

### ReservationStatus
- `PENDING` - Awaiting confirmation
- `CONFIRMED` - Active reservation
- `CANCELLED` - Cancelled reservation

### SubscriptionPlan
- `MONTHLY` - 1 month subscription
- `QUARTERLY` - 3 months subscription
- `SEMI_ANNUAL` - 6 months subscription

### SubscriptionStatus
- `PENDING` - Awaiting approval
- `ACTIVE` - Currently active
- `SUSPENDED` - Temporarily suspended
- `EXPIRED` - Subscription period ended
- `CANCELLED` - Cancelled by user

### NotificationType
- `CONFIRMATION_RESERVATION` - Reservation confirmation
- `REMINDER_RESERVATION` - Reservation reminder
- `SUBSCRIPTION_UPDATE` - Subscription status update

### UserRole
- `USER` - Regular user
- `ADMIN` - Administrator with full access
