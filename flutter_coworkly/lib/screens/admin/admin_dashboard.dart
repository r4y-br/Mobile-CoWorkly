import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../services/stats_api.dart';
import '../../services/reservations_api.dart';
import '../../services/users_api.dart';
import '../../widgets/index.dart';
import 'admin_rooms_tab.dart';
import 'admin_subscriptions_tab.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final StatsApi _statsApi = StatsApi();
  final ReservationsApi _reservationsApi = ReservationsApi();
  final UsersApi _usersApi = UsersApi();

  Map<String, dynamic>? _dashboardStats;
  List<Map<String, dynamic>> _weeklyStats = [];
  List<dynamic> _recentBookings = [];
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final token = appProvider.authToken;
    if (token == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _statsApi.fetchDashboardStats(token: token),
        _statsApi.fetchWeeklyStats(token: token),
        _reservationsApi.fetchAllReservations(token: token),
        _usersApi.fetchAllUsers(token: token),
      ]);

      final reservations = results[2] as List;
      final users = results[3] as List<Map<String, dynamic>>;

      setState(() {
        _dashboardStats = (results[0] as Map<String, dynamic>)['stats'];
        _weeklyStats = results[1] as List<Map<String, dynamic>>;
        _recentBookings = reservations.take(10).toList();
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _statsApi.dispose();
    _reservationsApi.dispose();
    _usersApi.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(context, appProvider),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildUsersTab(),
                _buildBookingsTab(),
                const AdminRoomsTab(),
                const AdminSubscriptionsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppProvider appProvider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => appProvider.goToHome(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Administration',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Welcome, ${appProvider.currentUser?.name ?? "Admin"}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _loadData,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.admin_panel_settings, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Admin',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Quick stats
          Row(
            children: [
              _buildQuickStat(
                Icons.people,
                '${_dashboardStats?['totalUsers'] ?? 0}',
                'Users',
              ),
              const SizedBox(width: 12),
              _buildQuickStat(
                Icons.calendar_today,
                '${_dashboardStats?['totalReservations'] ?? 0}',
                'Reservations',
              ),
              const SizedBox(width: 12),
              _buildQuickStat(
                Icons.meeting_room,
                '${_dashboardStats?['totalRooms'] ?? 0}',
                'Rooms',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF6366F1),
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFF6366F1),
        indicatorWeight: 3,
        indicatorPadding: const EdgeInsets.symmetric(horizontal: 8),
        labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        isScrollable: true,
        tabs: const [
          Tab(icon: Icon(Icons.dashboard, size: 18), text: 'Overview'),
          Tab(icon: Icon(Icons.people, size: 18), text: 'Users'),
          Tab(icon: Icon(Icons.calendar_today, size: 18), text: 'Reservations'),
          Tab(icon: Icon(Icons.meeting_room, size: 18), text: 'Rooms'),
          Tab(icon: Icon(Icons.card_membership, size: 18), text: 'Subscriptions'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_isLoading) {
      return const LoadingState(message: 'Loading...');
    }

    if (_error != null) {
      return ErrorState(message: _error!, onRetry: _loadData);
    }

    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final weeklyValues = List<int>.filled(7, 0);
    for (var stat in _weeklyStats) {
      final dayName = stat['day'] as String? ?? '';
      final count = stat['count'] as int? ?? 0;
      final dayIndex = days.indexOf(dayName);
      if (dayIndex >= 0) {
        weeklyValues[dayIndex] = count;
      }
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Stats cards
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Users',
                  value: '${_dashboardStats?['totalUsers'] ?? 0}',
                  icon: Icons.people,
                  color: const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Reservations',
                  value: '${_dashboardStats?['totalReservations'] ?? 0}',
                  icon: Icons.calendar_today,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Rooms',
                  value: '${_dashboardStats?['totalRooms'] ?? 0}',
                  icon: Icons.meeting_room,
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Seats',
                  value: '${_dashboardStats?['totalSeats'] ?? 0}',
                  icon: Icons.event_seat,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Weekly chart
          _buildSectionTitle('Weekly Activity'),
          const SizedBox(height: 12),
          CustomCard(
            child: SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(7, (i) => _buildBar(days[i], weeklyValues[i])),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Recent bookings
          _buildSectionTitle('Recent Reservations'),
          const SizedBox(height: 12),
          if (_recentBookings.isEmpty)
            const CustomCard(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No recent reservations'),
                ),
              ),
            )
          else
            ..._recentBookings.take(5).map((booking) => _buildBookingCard(booking)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildBar(String label, int value) {
    final clampedValue = value.clamp(0, 20);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 20,
          height: clampedValue * 5.0 + 10,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildBookingCard(dynamic booking) {
    final user = booking['user'] as Map<String, dynamic>?;
    final seat = booking['seat'] as Map<String, dynamic>?;
    final room = seat?['room'] as Map<String, dynamic>?;
    final userName = user?['name'] ?? 'User';
    final roomName = room?['name'] ?? 'Room';
    final seatNumber = seat?['number'] ?? '?';
    final status = booking['status'] ?? 'PENDING';

    final initials = userName
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: CustomCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
              child: Text(
                initials,
                style: const TextStyle(
                  color: Color(0xFF6366F1),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '$roomName - Seat $seatNumber',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            StatusBadge(status: status),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    if (_isLoading) {
      return const LoadingState();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle('Users'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_users.length} users',
                  style: const TextStyle(
                    color: Color(0xFF6366F1),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_users.isEmpty)
            const EmptyState(
              title: 'No users',
              icon: Icons.people,
            )
          else
            ..._users.map((user) => _buildUserCard(user)),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final name = user['name'] ?? 'User';
    final email = user['email'] ?? '';
    final role = user['role'] ?? 'USER';
    final id = user['id'];
    final count = user['_count'] as Map<String, dynamic>?;
    final reservationsCount = count?['reservations'] ?? 0;
    final isAdmin = role == 'ADMIN';
    final initials = name
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: CustomCard(
        border: isAdmin ? Border.all(color: const Color(0xFF6366F1), width: 2) : null,
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isAdmin
                  ? const Color(0xFF6366F1)
                  : const Color(0xFF6366F1).withOpacity(0.1),
              radius: 24,
              child: Text(
                initials,
                style: TextStyle(
                  color: isAdmin ? Colors.white : const Color(0xFF6366F1),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (isAdmin) ...[
                        const SizedBox(width: 8),
                        const RoleBadge(role: 'ADMIN', compact: true),
                      ],
                    ],
                  ),
                  Text(
                    email,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$reservationsCount reservations',
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.grey[400]),
              onSelected: (value) {
                if (value == 'toggle_role') {
                  _toggleUserRole(id, role);
                } else if (value == 'delete') {
                  _deleteUser(id, name);
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'toggle_role',
                  child: Row(
                    children: [
                      Icon(
                        isAdmin ? Icons.person : Icons.admin_panel_settings,
                        size: 18,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(width: 8),
                      Text(isAdmin ? 'Remove admin' : 'Promote to admin'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleUserRole(int userId, String currentRole) async {
    final newRole = currentRole == 'ADMIN' ? 'USER' : 'ADMIN';
    final token = Provider.of<AppProvider>(context, listen: false).authToken;
    if (token == null) return;

    try {
      await _usersApi.updateUserRole(token: token, userId: userId, role: newRole);
      _showSuccess('Role changed to $newRole');
      _loadData();
    } catch (e) {
      _showError('Error: $e');
    }
  }

  Future<void> _deleteUser(int userId, String userName) async {
    final confirm = await ConfirmDialog.show(
      context: context,
      title: 'Delete user',
      message: 'Delete "$userName"?',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (confirm != true) return;

    final token = Provider.of<AppProvider>(context, listen: false).authToken;
    if (token == null) return;

    try {
      await _usersApi.deleteUser(token: token, userId: userId);
      _showSuccess('User deleted');
      _loadData();
    } catch (e) {
      _showError('Error: $e');
    }
  }

  Widget _buildBookingsTab() {
    if (_isLoading) {
      return const LoadingState();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle('All Reservations'),
              Text(
                '${_recentBookings.length} total',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_recentBookings.isEmpty)
            const EmptyState(
              title: 'No reservations',
              icon: Icons.calendar_today,
            )
          else
            ..._recentBookings.map((booking) => _buildEnhancedBookingCard(booking)),
        ],
      ),
    );
  }

  Widget _buildEnhancedBookingCard(dynamic booking) {
    final user = booking['user'] as Map<String, dynamic>?;
    final seat = booking['seat'] as Map<String, dynamic>?;
    final room = seat?['room'] as Map<String, dynamic>?;
    final userName = user?['name'] ?? 'User';
    final roomName = room?['name'] ?? 'Room';
    final seatNumber = seat?['number'] ?? '?';
    final status = booking['status'] ?? 'PENDING';
    final startTime = booking['startTime'] ?? '';
    final id = booking['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: CustomCard(
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '#$id',
                  style: const TextStyle(
                    color: Color(0xFF6366F1),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '$roomName - Seat $seatNumber',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  Text(
                    _formatDateTime(startTime),
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusBadge(status: status),
                if (status == 'CONFIRMED')
                  TextButton(
                    onPressed: () => _cancelReservation(id),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 30),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.red, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return '${date.month}/${date.day}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoString;
    }
  }

  Future<void> _cancelReservation(int id) async {
    final confirm = await ConfirmDialog.show(
      context: context,
      title: 'Cancel reservation',
      message: 'Cancel reservation #$id?',
      confirmText: 'Cancel',
      isDestructive: true,
    );

    if (confirm != true) return;

    final token = Provider.of<AppProvider>(context, listen: false).authToken;
    if (token == null) return;

    try {
      await _usersApi.cancelReservation(token: token, reservationId: id);
      _showSuccess('Reservation cancelled');
      _loadData();
    } catch (e) {
      _showError('Error: $e');
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: const Color(0xFF10B981)),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
