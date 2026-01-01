import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'auth_screen.dart';
import 'home_screen.dart';
import 'space_selection_screen.dart';
import 'room_visualization_screen.dart';
import 'booking_screen.dart';
import 'dashboard_screen.dart';
import 'subscriptions_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'admin_screen.dart';
import '../widgets/bottom_nav.dart';

class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, _) {
        final currentScreen = appProvider.currentScreen;
        final isAuthScreen = currentScreen == 'auth';
        final isDetailScreen = [
          'spaceSelection',
          'room',
          'booking',
        ].contains(currentScreen);

        return Scaffold(
          body: _buildScreen(currentScreen),
          bottomNavigationBar:
              !isAuthScreen && !isDetailScreen ? const BottomNav() : null,
        );
      },
    );
  }

  Widget _buildScreen(String screenName) {
    switch (screenName) {
      case 'auth':
        return const AuthScreen();
      case 'home':
        return const HomeScreen();
      case 'spaceSelection':
        return const SpaceSelectionScreen();
      case 'room':
        return const RoomVisualizationScreen();
      case 'booking':
        return const BookingScreen();
      case 'dashboard':
        return const DashboardScreen();
      case 'subscriptions':
        return const SubscriptionsScreen();
      case 'notifications':
        return const NotificationsScreen();
      case 'profile':
        return const ProfileScreen();
      case 'admin':
        return const AdminScreen();
      default:
        return const HomeScreen();
    }
  }
}
