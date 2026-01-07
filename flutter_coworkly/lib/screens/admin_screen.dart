import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/stats_api.dart';
import '../services/reservations_api.dart';
import '../services/users_api.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
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
    _tabController = TabController(length: 4, vsync: this);
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
        _recentBookings = reservations.take(10).toList().cast<Map<String, dynamic>>();
        _users = users;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('Error loading data: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
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

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    final token = Provider.of<AppProvider>(context, listen: false).authToken;
    if (token == null || token.isEmpty) {
      setState(() {
        _loadError = 'Non authentifié';
        _isLoading = false;
      });
      return;
    }

    try {
      final results = await Future.wait([
        _usersApi.fetchUserStats(token: token),
        _usersApi.fetchAllUsers(token: token),
        _reservationsApi.fetchAllReservations(token: token),
        _roomsApi.fetchRooms(),
        _subscriptionsApi.fetchAllSubscriptions(
            token: token, status: 'PENDING'),
      ]);

      setState(() {
        _stats = results[0] as Map<String, dynamic>;
        _users = results[1] as List<Map<String, dynamic>>;
        _reservations = results[2] as List<Map<String, dynamic>>;
        _rooms = results[3] as List<Map<String, dynamic>>;
        _pendingSubscriptions = results[4] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _loadError = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _approveSubscription(int id) async {
    final token = Provider.of<AppProvider>(context, listen: false).authToken;
    if (token == null) return;

    try {
      await _subscriptionsApi.approveSubscription(token: token, id: id);
      _showMessage('Abonnement approuvé');
      _loadData();
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  Future<void> _deleteUser(int id) async {
    final token = Provider.of<AppProvider>(context, listen: false).authToken;
    if (token == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l\'utilisateur'),
        content: const Text('Cette action est irréversible. Continuer?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _usersApi.deleteUser(token: token, id: id);
      _showMessage('Utilisateur supprimé');
      _loadData();
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(context, appProvider),
          Expanded(
            child: Column(
              children: [
                Container(
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
                    indicatorPadding:
                        const EdgeInsets.symmetric(horizontal: 8),
                    labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    tabs: const [
                      Tab(icon: Icon(Icons.dashboard, size: 20), text: 'Overview'),
                      Tab(icon: Icon(Icons.people, size: 20), text: 'Users'),
                      Tab(icon: Icon(Icons.calendar_today, size: 20), text: 'Reservations'),
                      Tab(icon: Icon(Icons.meeting_room, size: 20), text: 'Rooms'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildUsersTab(),
                      _buildBookingsTab(),
                      _buildRoomsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppProvider appProvider) {
    final totalUsers = _stats['users']?['total'] ?? 0;
    final totalReservations = _stats['reservations']?['total'] ?? 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 220,
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Administration',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Dashboard',
                          style: TextStyle(
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Admin',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          bottom: -40,
          left: 24,
          right: 24,
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Users',
                  _dashboardStats != null ? '${_dashboardStats!['totalUsers'] ?? 0}' : '--',
                  'Total registered',
                  Icons.people,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Reservations',
                  _dashboardStats != null ? '${_dashboardStats!['totalReservations'] ?? 0}' : '--',
                  'Total',
                  Icons.calendar_today,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Icon(Icons.trending_up, color: Colors.green[400], size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.green[600],
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }
    
    // Build weekly stats bars
    final days = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];
    final weeklyValues = List<int>.filled(7, 0);
    for (var stat in _weeklyStats) {
      final dayName = stat['day'] as String? ?? '';
      final count = stat['count'] as int? ?? 0;
      final dayIndex = days.indexOf(dayName);
      if (dayIndex >= 0) {
        weeklyValues[dayIndex] = count;
      }
    }
    
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      children: [
        _buildSectionTitle('Reservations this week'),
        const SizedBox(height: 16),
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (i) => _buildBar(days[i], weeklyValues[i] * 10)),
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('Recent reservations'),
        const SizedBox(height: 16),
        _buildRecentBookingsList(),
        const SizedBox(height: 24),
        _buildSectionTitle('Statistiques globales'),
        const SizedBox(height: 16),
        _buildGlobalStatsCard(),
      ],
    );
  }

  Widget _buildGlobalStatsCard() {
    final totalRooms = _dashboardStats?['totalRooms'] ?? 0;
    final totalSeats = _dashboardStats?['totalSeats'] ?? 0;
    final availableSeats = _dashboardStats?['availableSeats'] ?? 0;
    final occupancy = totalSeats > 0 ? ((totalSeats - availableSeats) / totalSeats * 100).round() : 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSpaceStat('Rooms', '$totalRooms'),
              _buildSpaceStat('Places totales', '$totalSeats'),
              _buildSpaceStat('Disponibles', '$availableSeats'),
              _buildSpaceStat('Occupation', '$occupancy%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBar(String label, int value) {
    final clampedValue = value.clamp(0, 100);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 8,
          height: clampedValue * 1.5,
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1),
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentBookingsList() {
    if (_recentBookings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: Text('No recent reservations'),
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: _recentBookings.map((booking) {
          final user = booking['user'];
          final seat = booking['seat'];
          final room = seat?['room'];
          final userName = user?['name'] ?? 'User';
          final initials = userName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();
          final spaceName = '${room?['name'] ?? 'Room'} - Seat ${seat?['number'] ?? '?'}';
          final status = booking['status'] ?? 'PENDING';
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                CircleAvatar(
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
                        spaceName,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: status == 'CONFIRMED'
                        ? const Color(0xFF10B981).withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status == 'CONFIRMED' ? 'Confirmed' : status,
                    style: TextStyle(
                      color: status == 'CONFIRMED'
                          ? const Color(0xFF10B981)
                          : Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReservationItem(Map<String, dynamic> res) {
    final status = res['status']?.toString() ?? 'PENDING';
    final seat = res['seat'] as Map<String, dynamic>?;
    final seatNumber = seat?['number'] ?? '?';
    final room = seat?['room'] as Map<String, dynamic>?;
    final roomName = room?['name'] ?? 'Salle';
    final startTime = res['startTime']?.toString();
    final startDt = startTime != null ? DateTime.tryParse(startTime) : null;

    Color statusColor;
    switch (status) {
      case 'CONFIRMED':
        statusColor = const Color(0xFF10B981);
        break;
      case 'CANCELLED':
        statusColor = Colors.red;
        break;
      default:
        statusColor = const Color(0xFFF59E0B);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '$seatNumber',
                style: const TextStyle(
                  color: Color(0xFF6366F1),
                  fontWeight: FontWeight.bold,
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
                  '$roomName - Siège $seatNumber',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  startDt != null
                      ? '${startDt.day}/${startDt.month}/${startDt.year}'
                      : 'Date inconnue',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
        itemCount: _users.length + 1,
        itemBuilder: (ctx, index) {
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Utilisateurs (${_users.length})'),
                const SizedBox(height: 16),
              ],
            );
          }
          final user = _users[index - 1];
          return _buildUserCard(user);
        },
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final id = user['id'] as int?;
    final name = user['name']?.toString() ?? 'Utilisateur';
    final email = user['email']?.toString() ?? '';
    final role = user['role']?.toString() ?? 'USER';
    final initials = name
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: role == 'ADMIN'
                ? const Color(0xFFEF4444).withOpacity(0.1)
                : const Color(0xFF6366F1).withOpacity(0.1),
            child: Text(
              initials,
              style: TextStyle(
                color: role == 'ADMIN'
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF6366F1),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  email,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: role == 'ADMIN'
                  ? const Color(0xFFEF4444).withOpacity(0.1)
                  : const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              role,
              style: TextStyle(
                color: role == 'ADMIN'
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF6366F1),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (id != null && role != 'ADMIN')
            IconButton(
              icon:
                  const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              onPressed: () => _deleteUser(id),
            ),
        ],
      ),
    );
  }

  Widget _buildReservationsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
        itemCount: _reservations.length + 1,
        itemBuilder: (ctx, index) {
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(
                    'Toutes les réservations (${_reservations.length})'),
                const SizedBox(height: 16),
              ],
            );
          }
          final res = _reservations[index - 1];
          return _buildFullReservationCard(res);
        },
      ),
    );
  }

  Widget _buildFullReservationCard(Map<String, dynamic> res) {
    final status = res['status']?.toString() ?? 'PENDING';
    final type = res['type']?.toString() ?? 'DAILY';
    final seat = res['seat'] as Map<String, dynamic>?;
    final seatNumber = seat?['number'] ?? '?';
    final room = seat?['room'] as Map<String, dynamic>?;
    final roomName = room?['name'] ?? 'Salle';
    final startTime = res['startTime']?.toString();
    final endTime = res['endTime']?.toString();
    final startDt = startTime != null ? DateTime.tryParse(startTime) : null;
    final endDt = endTime != null ? DateTime.tryParse(endTime) : null;

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'CONFIRMED':
        statusColor = const Color(0xFF10B981);
        statusLabel = 'Confirmé';
        break;
      case 'CANCELLED':
        statusColor = Colors.red;
        statusLabel = 'Annulé';
        break;
      default:
        statusColor = const Color(0xFFF59E0B);
        statusLabel = 'En attente';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Active',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$totalSeats seats',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildSpaceStat('Disponibles', '$availableSeats'),
              _buildSpaceStat('Revenus', '$revenue€'),
              _buildSpaceStat('Reservations', '$bookings'),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Occupation',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '$occupancy%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                startDt != null && endDt != null
                    ? '${startDt.hour}:${startDt.minute.toString().padLeft(2, '0')} - ${endDt.hour}:${endDt.minute.toString().padLeft(2, '0')}'
                    : 'Heure inconnue',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  type,
                  style: const TextStyle(
                    color: Color(0xFF6366F1),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
        itemCount: _pendingSubscriptions.length + 1,
        itemBuilder: (ctx, index) {
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(
                    'Abonnements en attente (${_pendingSubscriptions.length})'),
                const SizedBox(height: 16),
                if (_pendingSubscriptions.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.check_circle,
                              size: 48, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun abonnement en attente',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          }
          final sub = _pendingSubscriptions[index - 1];
          return _buildSubscriptionCard(sub);
        },
      ),
    );
  }

  Widget _buildSubscriptionCard(Map<String, dynamic> sub) {
    final id = sub['id'] as int?;
    final plan = sub['plan']?.toString() ?? 'MONTHLY';
    final user = sub['user'] as Map<String, dynamic>?;
    final userName = user?['name']?.toString() ?? 'Utilisateur';
    final userEmail = user?['email']?.toString() ?? '';
    final createdAt = sub['createdAt']?.toString();
    final createdDt = createdAt != null ? DateTime.tryParse(createdAt) : null;

    String planLabel;
    switch (plan) {
      case 'QUARTERLY':
        planLabel = 'Trimestriel';
        break;
      case 'SEMI_ANNUAL':
        planLabel = 'Semestriel';
        break;
      default:
        planLabel = 'Mensuel';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.workspace_premium,
                    color: Color(0xFFF59E0B)),
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
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      userEmail,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  planLabel,
                  style: const TextStyle(
                    color: Color(0xFF6366F1),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                createdDt != null
                    ? 'Demandé le ${createdDt.day}/${createdDt.month}/${createdDt.year}'
                    : 'Date inconnue',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const Spacer(),
              if (id != null)
                ElevatedButton(
                  onPressed: () => _approveSubscription(id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child:
                      const Text('Approuver', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBookingsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('All reservations'),
            Text(
              '${_recentBookings.length} total',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildEnhancedBookingsList(),
      ],
    );
  }

  Widget _buildEnhancedBookingsList() {
    if (_recentBookings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No reservations',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _recentBookings.map((booking) {
        final user = booking['user'] as Map<String, dynamic>?;
        final seat = booking['seat'] as Map<String, dynamic>?;
        final room = seat?['room'] as Map<String, dynamic>?;
        final userName = user?['name'] ?? 'User';
        final userEmail = user?['email'] ?? '';
        final roomName = room?['name'] ?? 'Room';
        final seatNumber = seat?['number'] ?? '?';
        final status = booking['status'] ?? 'PENDING';
        final startTime = booking['startTime'] ?? '';
        final id = booking['id'];

        Color statusColor;
        String statusLabel;
        switch (status) {
          case 'CONFIRMED':
            statusColor = const Color(0xFF10B981);
            statusLabel = 'Confirmed';
            break;
          case 'CANCELLED':
            statusColor = Colors.red;
            statusLabel = 'Cancelled';
            break;
          default:
            statusColor = Colors.orange;
            statusLabel = 'Pending';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
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
                    const SizedBox(height: 2),
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
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
        );
      }).toList(),
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel reservation'),
        content: Text('Do you want to cancel reservation #$id?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, cancel'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final token = Provider.of<AppProvider>(context, listen: false).authToken;
    if (token == null) return;

    try {
      await _usersApi.cancelReservation(token: token, reservationId: id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reservation cancelled'), backgroundColor: Colors.green),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildUsersTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('User Management'),
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
        ..._users.map((user) => _buildUserCard(user)).toList(),
      ],
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final name = user['name'] ?? 'User';
    final email = user['email'] ?? '';
    final role = user['role'] ?? 'USER';
    final id = user['id'];
    final count = user['_count'] as Map<String, dynamic>?;
    final reservationsCount = count?['reservations'] ?? 0;
    final subscriptionsCount = count?['subscriptions'] ?? 0;
    final isAdmin = role == 'ADMIN';
    final initials = name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isAdmin ? Border.all(color: const Color(0xFF6366F1), width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'ADMIN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  email,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildMiniStat(Icons.calendar_today, '$reservationsCount res.'),
                    const SizedBox(width: 12),
                    _buildMiniStat(Icons.card_membership, '$subscriptionsCount sub.'),
                  ],
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
    );
  }

  Widget _buildMiniStat(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(color: Colors.grey[500], fontSize: 11),
        ),
      ],
    );
  }

  Future<void> _toggleUserRole(int userId, String currentRole) async {
    final newRole = currentRole == 'ADMIN' ? 'USER' : 'ADMIN';
    final token = Provider.of<AppProvider>(context, listen: false).authToken;
    if (token == null) return;

    try {
      await _usersApi.updateUserRole(token: token, userId: userId, role: newRole);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Role changed to $newRole'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteUser(int userId, String userName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete user'),
        content: Text('Are you sure you want to delete "$userName"? This action is irreversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final token = Provider.of<AppProvider>(context, listen: false).authToken;
    if (token == null) return;

    try {
      await _usersApi.deleteUser(token: token, userId: userId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User deleted'), backgroundColor: Colors.green),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildRoomsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final rooms = (_dashboardStats?['rooms'] as List?) ?? 
                  ((Provider.of<AppProvider>(context, listen: false) as dynamic)._dashboardStats?['rooms'] as List?) ?? 
                  [];

    // Get rooms from stats API response
    final fullStats = _dashboardStats;
    
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      children: [
        _buildSectionTitle('Room Management'),
        const SizedBox(height: 16),
        _buildRoomsSummary(),
        const SizedBox(height: 24),
        _buildSectionTitle('Room Details'),
        const SizedBox(height: 16),
        _buildRoomDetailsList(),
      ],
    );
  }

  Widget _buildRoomsSummary() {
    final totalRooms = _dashboardStats?['totalRooms'] ?? 0;
    final totalSeats = _dashboardStats?['totalSeats'] ?? 0;
    final availableSeats = _dashboardStats?['availableSeats'] ?? 0;
    final occupiedSeats = totalSeats - availableSeats;
    final occupancyRate = totalSeats > 0 ? (occupiedSeats / totalSeats * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Rooms', '$totalRooms', Icons.meeting_room),
              _buildSummaryItem('Seats', '$totalSeats', Icons.event_seat),
              _buildSummaryItem('Available', '$availableSeats', Icons.check_circle),
              _buildSummaryItem('Occupancy', '$occupancyRate%', Icons.pie_chart),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildRoomDetailsList() {
    // Simulated rooms data - in real app, this would come from API
    final rooms = [
      {'name': 'Creative Hub', 'capacity': 16, 'available': 11, 'status': 'Open'},
      {'name': 'Tech Space', 'capacity': 20, 'available': 19, 'status': 'Open'},
      {'name': 'Work Lounge', 'capacity': 12, 'available': 12, 'status': 'Open'},
      {'name': 'Meeting Room', 'capacity': 8, 'available': 8, 'status': 'Open'},
    ];

    return Column(
      children: rooms.map((room) {
        final name = room['name'] as String;
        final capacity = room['capacity'] as int;
        final available = room['available'] as int;
        final occupied = capacity - available;
        final occupancy = capacity > 0 ? occupied / capacity : 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      room['status'] as String,
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$available/$capacity seats available',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: occupancy,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              occupancy > 0.8 ? Colors.red : 
                              occupancy > 0.5 ? Colors.orange : 
                              const Color(0xFF10B981),
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${(occupancy * 100).round()}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
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
}
