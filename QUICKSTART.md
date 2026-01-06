# Quick Start Guide - Mobile CoWorkly

Get up and running with CoWorkly in 5 minutes!

## ⚡ Prerequisites

Make sure you have installed:
- **Node.js** (v18+): [Download](https://nodejs.org/)
- **PostgreSQL** (v14+): [Download](https://www.postgresql.org/download/)
- **Flutter SDK** (v3.0+): [Get Started](https://flutter.dev/docs/get-started/install)

## 🚀 Quick Setup

### 1️⃣ Backend Setup (2 minutes)

```bash
# Navigate to server directory
cd server

# Install dependencies
npm install

# Create environment file
cp .env.example .env

# Edit .env file with your database credentials
# DATABASE_URL="postgresql://user:password@localhost:5432/coworkly?schema=public"

# Run database migrations
npx prisma migrate dev

# Seed the database with sample data
npm run seed

# Start the development server
npm run dev
```

✅ Backend is now running at `http://localhost:4000`

### 2️⃣ Frontend Setup (2 minutes)

Open a new terminal:

```bash
# Navigate to Flutter directory
cd flutter_coworkly

# Install dependencies
flutter pub get

# Run the app
flutter run
```

Select your device (Android emulator, iOS simulator, or connected device).

✅ App is now running on your device!

## 🔑 Test the Application

Use these pre-configured test accounts:

**Regular User:**
- Email: `laith@example.com`
- Password: `Laith1818@`

**Admin User:**
- Email: `admin@coworkly.com`
- Password: `Admin1818@`

## 📱 Features to Try

1. **Login** with test credentials
2. **Browse** available coworking spaces
3. **Book** a seat for today or tomorrow
4. **View** your reservations in the dashboard
5. **Check** notifications
6. **Explore** user profile

**Admin Features** (login as admin):
- Manage users
- Manage rooms and seats
- Approve subscriptions
- View statistics

## 🐛 Troubleshooting

### Backend won't start?

**Database connection error:**
```bash
# Check PostgreSQL is running
# On macOS/Linux:
sudo service postgresql status

# On Windows:
# Check Services for PostgreSQL

# Create database if it doesn't exist
createdb coworkly
```

**Port already in use:**
```bash
# Change PORT in .env file
PORT=4001
```

### Frontend won't run?

**No devices found:**
```bash
# List available devices
flutter devices

# Start an emulator
flutter emulators --launch <emulator_id>
```

**Build errors:**
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

## 📖 Next Steps

- 📚 Read the [full README](README.md) for detailed information
- 🛠️ Check [DEVELOPMENT.md](DEVELOPMENT.md) for development guidelines
- 🚀 See [DEPLOYMENT.md](DEPLOYMENT.md) for production deployment
- 📡 Review [API_DOCUMENTATION.md](server/API_DOCUMENTATION.md) for API details

## 💡 Quick Tips

**Backend:**
- API runs on port 4000 by default
- View database: `npx prisma studio`
- Auto-reload on file changes with nodemon

**Frontend:**
- Hot reload: Press `r` in terminal
- Open DevTools: Press `v` in terminal
- Restart app: Press `R` in terminal

**Database:**
- Reset database: `npx prisma migrate reset`
- View data: `npx prisma studio` (opens in browser)

## 🎯 Common Tasks

**Create new reservation:**
1. Login as user
2. Go to "Réserver" tab
3. Select a room
4. Choose date and time
5. Confirm booking

**Approve subscription (Admin):**
1. Login as admin
2. Go to Admin panel
3. Navigate to Subscriptions tab
4. Find pending subscription
5. Click Approve

## 📞 Need Help?

- Check [DEVELOPMENT.md](DEVELOPMENT.md) for detailed development info
- Review API docs at [server/API_DOCUMENTATION.md](server/API_DOCUMENTATION.md)
- Open an issue on GitHub

---

Happy coding! 🎉
