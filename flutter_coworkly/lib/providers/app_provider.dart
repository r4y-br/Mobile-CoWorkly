import 'package:flutter/foundation.dart';
import '../models/index.dart';

class AppProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  User? _currentUser;
  String _currentScreen = 'home';
  String _activeTab = 'home';
  String? _selectedSpaceId;
  String _selectedSpaceName = '';

  bool get isLoggedIn => _isLoggedIn;
  User? get currentUser => _currentUser;
  String get currentScreen => _currentScreen;
  String get activeTab => _activeTab;
  String? get selectedSpaceId => _selectedSpaceId;
  String get selectedSpaceName => _selectedSpaceName;

  void login(String email, String password) {
    _currentUser = User(
      id: '1',
      name: 'Jean Dupont',
      email: email,
      phone: '+33 1 42 36 52 78',
      avatar: 'JD',
      isPremium: true,
      bookings: 24,
      hours: 156,
      spending: 890,
      memberSince: DateTime(2024),
    );
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _currentUser = null;
    _currentScreen = 'home';
    _activeTab = 'home';
    notifyListeners();
  }

  void navigateToScreen(String screenName) {
    _currentScreen = screenName;
    notifyListeners();
  }

  void setActiveTab(String tabName) {
    _activeTab = tabName;
    if (tabName == 'home') {
      _currentScreen = 'home';
    } else if (tabName == 'bookings') {
      _currentScreen = 'dashboard';
    } else if (tabName == 'subscriptions') {
      _currentScreen = 'subscriptions';
    } else if (tabName == 'notifications') {
      _currentScreen = 'notifications';
    } else if (tabName == 'profile') {
      _currentScreen = 'profile';
    }
    notifyListeners();
  }

  void selectSpace(String spaceId, String spaceName) {
    _selectedSpaceId = spaceId;
    _selectedSpaceName = spaceName;
    _currentScreen = 'room';
    notifyListeners();
  }

  void goToSpaceSelection() {
    _currentScreen = 'spaceSelection';
    notifyListeners();
  }

  void goToHome() {
    _currentScreen = 'home';
    _activeTab = 'home';
    notifyListeners();
  }

  void goToBooking() {
    _currentScreen = 'booking';
    notifyListeners();
  }

  void confirmBooking() {
    _currentScreen = 'dashboard';
    _activeTab = 'bookings';
    notifyListeners();
  }

  void goToAdminPanel() {
    _currentScreen = 'admin';
    notifyListeners();
  }
}
