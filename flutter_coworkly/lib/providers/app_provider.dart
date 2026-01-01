import 'package:flutter/foundation.dart';
import '../models/index.dart';
import '../services/auth_api.dart';

class AppProvider extends ChangeNotifier {
  final AuthApi _authApi = AuthApi();
  bool _isLoggedIn = false;
  String? _authToken;
  User? _currentUser;
  String _currentScreen = 'home';
  String _activeTab = 'home';
  String? _selectedRoomId;
  String _selectedRoomName = '';
  String? _selectedSeatId;
  int? _selectedSeatNumber;

  bool get isLoggedIn => _isLoggedIn;
  String? get authToken => _authToken;
  User? get currentUser => _currentUser;
  String get currentScreen => _currentScreen;
  String get activeTab => _activeTab;
  String? get selectedRoomId => _selectedRoomId;
  String get selectedRoomName => _selectedRoomName;
  String? get selectedSeatId => _selectedSeatId;
  int? get selectedSeatNumber => _selectedSeatNumber;
  bool get isAdmin => _currentUser?.role == 'ADMIN';

  Future<void> login(String email, String password) async {
    final response = await _authApi.login(email: email, password: password);
    _authToken = response['token'] as String?;
    final userData = response['user'] as Map<String, dynamic>?;
    if (userData != null) {
      _currentUser = _buildUserFromApi(userData);
    }
    _isLoggedIn = _authToken != null && _currentUser != null;
    if (_isLoggedIn) {
      _currentScreen = isAdmin ? 'admin' : 'home';
      _activeTab = 'home';
    }
    notifyListeners();
  }

  Future<void> register(String email, String password, String name,
      {String? phone}) async {
    final response = await _authApi.register(
      email: email,
      password: password,
      name: name,
      phone: phone,
    );
    _authToken = response['token'] as String?;
    final userData = response['user'] as Map<String, dynamic>?;
    if (userData != null) {
      _currentUser = _buildUserFromApi(userData);
    }
    _isLoggedIn = _authToken != null && _currentUser != null;
    if (_isLoggedIn) {
      _currentScreen = isAdmin ? 'admin' : 'home';
      _activeTab = 'home';
    }
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _authToken = null;
    _currentUser = null;
    _currentScreen = 'home';
    _activeTab = 'home';
    _selectedRoomId = null;
    _selectedRoomName = '';
    _selectedSeatId = null;
    _selectedSeatNumber = null;
    notifyListeners();
  }

  void navigateToScreen(String screenName) {
    _currentScreen = screenName;
    notifyListeners();
  }

  void setActiveTab(String tabName) {
    _activeTab = tabName;
    if (tabName == 'home') {
      // Admin sees admin dashboard, users see home
      _currentScreen = isAdmin ? 'admin' : 'home';
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

  void selectRoom(String roomId, String roomName) {
    _selectedRoomId = roomId;
    _selectedRoomName = roomName;
    _selectedSeatId = null;
    _selectedSeatNumber = null;
    _currentScreen = 'room';
    notifyListeners();
  }

  void goToSpaceSelection() {
    _currentScreen = 'spaceSelection';
    _selectedSeatId = null;
    _selectedSeatNumber = null;
    notifyListeners();
  }

  void goToRoom() {
    _currentScreen = 'room';
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

  void selectSeat(String seatId, int seatNumber) {
    _selectedSeatId = seatId;
    _selectedSeatNumber = seatNumber;
    _currentScreen = 'booking';
    notifyListeners();
  }

  void confirmBooking() {
    _currentScreen = 'dashboard';
    _activeTab = 'bookings';
    notifyListeners();
  }

  bool goToAdminPanel() {
    if (!isAdmin) {
      return false;
    }
    _currentScreen = 'admin';
    notifyListeners();
    return true;
  }

  void recordBooking({required double price, required int hours}) {
    final user = _currentUser;
    if (user == null) {
      return;
    }
    _currentUser = User(
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      avatar: user.avatar,
      isPremium: user.isPremium,
      role: user.role,
      bookings: user.bookings + 1,
      hours: user.hours + hours,
      spending: user.spending + price,
      memberSince: user.memberSince,
    );
    notifyListeners();
  }

  User _buildUserFromApi(Map<String, dynamic> userData) {
    final name = (userData['name'] as String?)?.trim();
    final email = (userData['email'] as String?)?.trim() ?? '';
    final avatar = (userData['avatar'] as String?)?.trim();
    final memberSinceRaw = userData['createdAt'];
    DateTime memberSince = DateTime.now();
    if (memberSinceRaw is String) {
      final parsed = DateTime.tryParse(memberSinceRaw);
      if (parsed != null) {
        memberSince = parsed;
      }
    }

    // Handle both int and String IDs
    final rawId = userData['id'];
    final id = rawId is int ? rawId.toString() : (rawId as String?) ?? '';

    return User(
      id: id,
      name: name?.isNotEmpty == true ? name! : email,
      email: email,
      phone: (userData['phone'] as String?) ?? '+33 1 42 36 52 78',
      avatar:
          avatar?.isNotEmpty == true ? avatar! : _buildAvatar(name ?? email),
      isPremium: (userData['isPremium'] as bool?) ?? false,
      role: (userData['role'] as String?) ?? 'CLIENT',
      bookings: (userData['reservationsCount'] as int?) ?? 0,
      hours: (userData['hours'] as int?) ?? 0,
      spending: (userData['spending'] as num?)?.toDouble() ?? 0,
      memberSince: memberSince,
    );
  }

  String _buildAvatar(String source) {
    final parts =
        source.trim().split(RegExp('\\s+')).where((p) => p.isNotEmpty);
    final initials = parts.map((part) => part[0]).join().toUpperCase();
    if (initials.isEmpty) {
      return 'NA';
    }
    final end = initials.length.clamp(1, 2).toInt();
    return initials.substring(0, end);
  }

  @override
  void dispose() {
    _authApi.dispose();
    super.dispose();
  }
}
