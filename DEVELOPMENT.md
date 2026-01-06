# Development Guide - Mobile CoWorkly

This guide helps developers set up their development environment and understand the project architecture.

## 🛠️ Development Setup

### Prerequisites
- **Node.js** v18+ and npm
- **PostgreSQL** v14+
- **Flutter SDK** v3.0+
- **Dart SDK** v3.0+
- **Git**
- **VS Code** or Android Studio (recommended)

### Initial Setup

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd Mobile-CoWorkly
   ```

2. **Backend Setup:**
   ```bash
   cd server
   npm install
   cp .env.example .env
   # Edit .env with your local database credentials
   npx prisma migrate dev
   npm run seed
   npm run dev
   ```

3. **Frontend Setup:**
   ```bash
   cd flutter_coworkly
   flutter pub get
   flutter run
   ```

---

## 📁 Project Architecture

### Backend Architecture

```
server/
├── src/
│   ├── controllers/      # Request handlers & business logic
│   │   ├── auth.js
│   │   ├── rooms.js
│   │   ├── seats.js
│   │   ├── reservations.js
│   │   ├── subscriptions.js
│   │   ├── notifications.js
│   │   └── users.js
│   ├── routes/          # API route definitions
│   │   └── [same files as controllers]
│   └── middlewares/     # Authentication, validation, etc.
│       └── auth.js
├── prisma/
│   ├── schema.prisma    # Database schema
│   ├── seed.js         # Seed data
│   └── migrations/     # Database migrations
├── lib/
│   ├── prisma.js       # Prisma client instance
│   ├── rateLimiter.js  # Rate limiting config
│   └── Validators.js   # Input validation utilities
├── tests/              # API tests
└── index.js           # Application entry point
```

### Frontend Architecture

```
flutter_coworkly/
├── lib/
│   ├── models/         # Data models
│   │   ├── user.dart
│   │   ├── booking.dart
│   │   ├── space.dart
│   │   └── index.dart
│   ├── providers/      # State management
│   │   └── app_provider.dart
│   ├── screens/        # UI screens
│   │   ├── auth_screen.dart
│   │   ├── home_screen.dart
│   │   ├── dashboard_screen.dart
│   │   ├── booking_screen.dart
│   │   ├── space_selection_screen.dart
│   │   ├── room_visualization_screen.dart
│   │   ├── profile_screen.dart
│   │   ├── admin_screen.dart
│   │   ├── subscriptions_screen.dart
│   │   ├── notifications_screen.dart
│   │   └── main_navigation_screen.dart
│   ├── services/       # API communication
│   │   ├── api_config.dart
│   │   ├── auth_api.dart
│   │   ├── rooms_api.dart
│   │   ├── seats_api.dart
│   │   ├── reservations_api.dart
│   │   ├── subscriptions_api.dart
│   │   ├── notifications_api.dart
│   │   └── users_api.dart
│   ├── widgets/        # Reusable widgets
│   │   └── bottom_nav.dart
│   ├── theme/          # App theming
│   │   └── app_theme.dart
│   ├── app.dart        # App configuration
│   └── main.dart       # Entry point
```

---

## 🔄 Development Workflow

### Backend Development

#### 1. Adding a New Feature

**Example: Adding a "Reviews" feature**

1. **Update Database Schema:**
   ```prisma
   // prisma/schema.prisma
   model Review {
     id        Int      @id @default(autoincrement())
     rating    Int
     comment   String?
     userId    Int
     roomId    Int
     user      User     @relation(fields: [userId], references: [id])
     room      Room     @relation(fields: [roomId], references: [id])
     createdAt DateTime @default(now())
   }
   ```

2. **Create Migration:**
   ```bash
   npx prisma migrate dev --name add-reviews
   ```

3. **Create Controller:**
   ```javascript
   // src/controllers/reviews.js
   import { prisma } from "../../lib/prisma.js";

   export const createReview = async (req, res) => {
     // Implementation
   };

   export const getAllReviews = async (req, res) => {
     // Implementation
   };
   ```

4. **Create Routes:**
   ```javascript
   // src/routes/reviews.js
   import { Router } from 'express';
   import { authenticate } from '../middlewares/auth.js';
   import { createReview, getAllReviews } from '../controllers/reviews.js';

   const router = Router();
   router.post('/', authenticate, createReview);
   router.get('/', getAllReviews);

   export default router;
   ```

5. **Register Routes:**
   ```javascript
   // index.js
   import reviewsRoutes from './src/routes/reviews.js';
   app.use('/reviews', reviewsRoutes);
   ```

6. **Test:**
   ```bash
   npm test
   ```

#### 2. Database Operations

**View Database:**
```bash
npx prisma studio
```

**Reset Database:**
```bash
npx prisma migrate reset
```

**Generate Prisma Client:**
```bash
npx prisma generate
```

**Create Migration:**
```bash
npx prisma migrate dev --name descriptive_name
```

#### 3. Running Tests

**Run all tests:**
```bash
npm test
```

**Watch mode:**
```bash
npm run test:watch
```

**With coverage:**
```bash
npm run test:coverage
```

### Frontend Development

#### 1. Adding a New Screen

1. **Create Screen File:**
   ```dart
   // lib/screens/reviews_screen.dart
   import 'package:flutter/material.dart';

   class ReviewsScreen extends StatefulWidget {
     const ReviewsScreen({Key? key}) : super(key: key);

     @override
     State<ReviewsScreen> createState() => _ReviewsScreenState();
   }

   class _ReviewsScreenState extends State<ReviewsScreen> {
     @override
     Widget build(BuildContext context) {
       return Scaffold(
         appBar: AppBar(title: const Text('Reviews')),
         body: const Center(child: Text('Reviews')),
       );
     }
   }
   ```

2. **Create API Service:**
   ```dart
   // lib/services/reviews_api.dart
   import 'dart:convert';
   import 'package:http/http.dart' as http;
   import 'api_config.dart';

   class ReviewsApi {
     Future<List<Map<String, dynamic>>> fetchReviews() async {
       // Implementation
     }
   }
   ```

3. **Add to Navigation:**
   Update routing in your app configuration.

#### 2. State Management

The app uses Provider for state management. Main provider is `AppProvider`:

```dart
// Update provider
Provider.of<AppProvider>(context, listen: false).updateData();

// Listen to changes
Consumer<AppProvider>(
  builder: (context, provider, child) {
    return Text(provider.data);
  },
);
```

#### 3. API Integration

Pattern for API calls:

```dart
Future<void> _loadData() async {
  setState(() => _isLoading = true);
  
  try {
    final api = YourApi();
    final data = await api.fetchData(token: token);
    setState(() {
      _data = data;
      _isLoading = false;
    });
  } catch (e) {
    setState(() {
      _error = e.toString();
      _isLoading = false;
    });
  }
}
```

---

## 🧪 Testing

### Backend Testing

**Test Structure:**
```javascript
// tests/api.test.js
import { describe, it, expect } from 'vitest';
import request from 'supertest';

describe('API Tests', () => {
  it('should register a user', async () => {
    const response = await request(app)
      .post('/auth/register')
      .send({
        name: 'Test User',
        email: 'test@example.com',
        password: 'Test1234!',
        retypedPassword: 'Test1234!'
      });
    
    expect(response.status).toBe(201);
    expect(response.body).toHaveProperty('token');
  });
});
```

### Frontend Testing

**Widget Tests:**
```dart
// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('0'), findsOneWidget);
  });
}
```

---

## 🐛 Debugging

### Backend Debugging

1. **VS Code Launch Configuration:**
   ```json
   {
     "version": "0.2.0",
     "configurations": [
       {
         "type": "node",
         "request": "launch",
         "name": "Debug Server",
         "program": "${workspaceFolder}/server/index.js",
         "env": {
           "NODE_ENV": "development"
         }
       }
     ]
   }
   ```

2. **Console Logging:**
   ```javascript
   console.log('Debug:', variable);
   console.error('Error:', error);
   ```

3. **Database Queries:**
   ```javascript
   // Enable query logging
   const prisma = new PrismaClient({
     log: ['query', 'info', 'warn', 'error'],
   });
   ```

### Frontend Debugging

1. **Flutter DevTools:**
   ```bash
   flutter run
   # Press 'v' to open DevTools
   ```

2. **Print Debugging:**
   ```dart
   print('Debug: $variable');
   debugPrint('Debug message');
   ```

3. **VS Code Launch Configuration:**
   ```json
   {
     "version": "0.2.0",
     "configurations": [
       {
         "name": "Flutter",
         "type": "dart",
         "request": "launch",
         "program": "lib/main.dart"
       }
     ]
   }
   ```

---

## 📝 Code Style Guide

### Backend (JavaScript/Node.js)

**File Naming:**
- Use lowercase with hyphens: `user-controller.js`
- Or camelCase: `userController.js`

**Code Style:**
```javascript
// Use async/await
async function fetchData() {
  try {
    const data = await prisma.user.findMany();
    return data;
  } catch (error) {
    throw error;
  }
}

// Use arrow functions
const processData = (data) => {
  return data.map(item => item.name);
};

// Destructuring
const { name, email } = req.body;

// Template literals
const message = `Hello ${name}`;
```

**Error Handling:**
```javascript
try {
  // Code that might throw
} catch (error) {
  console.error('Error:', error);
  res.status(500).json({ error: 'Internal server error' });
}
```

### Frontend (Flutter/Dart)

**File Naming:**
- Use snake_case: `user_profile_screen.dart`

**Code Style:**
```dart
// Class naming (PascalCase)
class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);
}

// Method naming (camelCase)
Future<void> loadUserData() async {
  // Implementation
}

// Variable naming (camelCase)
final String userName = 'John';
bool isLoading = false;

// Private members (prefix with _)
String _privateVariable;
void _privateMethod() {}

// Constants (lowerCamelCase)
const String apiBaseUrl = 'http://localhost:4000';
```

**Widget Structure:**
```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Title'),
    ),
    body: _buildBody(),
  );
}

Widget _buildBody() {
  return Container(
    // Widget tree
  );
}
```

---

## 🔧 Common Tasks

### Add New API Endpoint

1. Create controller function
2. Create route
3. Register route in index.js
4. Add to API documentation
5. Create corresponding Flutter service
6. Test endpoint

### Update Database Schema

1. Modify `prisma/schema.prisma`
2. Run `npx prisma migrate dev --name change_description`
3. Update seed.js if needed
4. Update controllers if needed
5. Test changes

### Add New Flutter Package

1. Add to `pubspec.yaml`
2. Run `flutter pub get`
3. Import in Dart files
4. Use the package

---

## 📚 Resources

### Documentation
- [Express.js](https://expressjs.com/)
- [Prisma](https://www.prisma.io/docs/)
- [Flutter](https://flutter.dev/docs)
- [PostgreSQL](https://www.postgresql.org/docs/)

### Tools
- [Postman](https://www.postman.com/) - API testing
- [Prisma Studio](https://www.prisma.io/studio) - Database GUI
- [Flutter DevTools](https://flutter.dev/docs/development/tools/devtools/overview)

---

## 🤝 Contributing

1. Create a feature branch
2. Make your changes
3. Write/update tests
4. Update documentation
5. Submit a pull request

### Commit Message Format
```
type(scope): subject

body

footer
```

**Types:** feat, fix, docs, style, refactor, test, chore

**Example:**
```
feat(auth): add password reset functionality

Implements password reset via email link.
Includes backend API and Flutter UI.

Closes #123
```

---

## 🔍 Troubleshooting

### Common Issues

**"Cannot connect to database"**
- Check PostgreSQL is running
- Verify DATABASE_URL in .env
- Check database exists

**"Port already in use"**
```bash
# Find process using port
lsof -i :4000
# Kill process
kill -9 <PID>
```

**"Prisma client not generated"**
```bash
npx prisma generate
```

**"Flutter build failed"**
```bash
flutter clean
flutter pub get
flutter run
```

---

## 📞 Getting Help

- Check documentation
- Review API documentation
- Search existing issues
- Ask in team chat
- Create a new issue

---

Happy coding! 🚀
