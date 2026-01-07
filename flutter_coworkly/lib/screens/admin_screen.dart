import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/users_api.dart';
import '../services/reservations_api.dart';
import '../services/rooms_api.dart';
import '../services/subscriptions_api.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final UsersApi _usersApi = UsersApi();
  final ReservationsApi _reservationsApi = ReservationsApi();
  final RoomsApi _roomsApi = RoomsApi();
  final SubscriptionsApi _subscriptionsApi = SubscriptionsApi();

  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _reservations = [];
  List<Map<String, dynamic>> _rooms = [];
  List<Map<String, dynamic>> _pendingSubscriptions = [];
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _usersApi.dispose();
    _reservationsApi.dispose();
    _roomsApi.dispose();
    _subscriptionsApi.dispose();
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
                    indicatorPadding: const EdgeInsets.symmetric(horizontal: 8),
                    tabs: const [
                      Tab(text: 'Aperçu'),
                      Tab(text: 'Utilisateurs'),
                      Tab(text: 'Réservations'),
                      Tab(text: 'Abonnements'),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _loadError != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(_loadError!,
                                      style: TextStyle(color: Colors.red[600])),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _loadData,
                                    child: const Text('Réessayer'),
                                  ),
                                ],
                              ),
                            )
                          : TabBarView(
                              controller: _tabController,
                              children: [
                                _buildOverviewTab(),
                                _buildUsersTab(),
                                _buildReservationsTab(),
                                _buildSubscriptionsTab(),
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
                          'Tableau de bord',
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
                  'Utilisateurs',
                  '$totalUsers',
                  '+${_stats['users']?['admins'] ?? 0} admins',
                  Icons.people,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Réservations',
                  '$totalReservations',
                  '${_stats['reservations']?['confirmed'] ?? 0} confirmées',
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
    // Calculate total seats and available
    int totalSeats = 0;
    int availableSeats = 0;
    for (var room in _rooms) {
      totalSeats += (room['totalSeats'] as int?) ?? 0;
      availableSeats += (room['availableSeats'] as int?) ?? 0;
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
        children: [
          _buildSectionTitle('Statistiques'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSmallStatCard(
                  'Abonnements actifs',
                  '${_stats['subscriptions']?['active'] ?? 0}',
                  Icons.workspace_premium,
                  const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSmallStatCard(
                  'En attente',
                  '${_pendingSubscriptions.length}',
                  Icons.pending,
                  const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSmallStatCard(
                  'Salles',
                  '${_rooms.length}',
                  Icons.meeting_room,
                  const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSmallStatCard(
                  'Places dispo.',
                  '$availableSeats/$totalSeats',
                  Icons.event_seat,
                  const Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Salles (${_rooms.length})'),
          const SizedBox(height: 16),
          ..._rooms.map((room) => _buildRoomCard(room)),
          const SizedBox(height: 24),
          _buildSectionTitle('Réservations récentes'),
          const SizedBox(height: 16),
          _buildRecentReservationsList(),
        ],
      ),
    );
  }

  Widget _buildSmallStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
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

  Widget _buildRoomCard(Map<String, dynamic> room) {
    final name = room['name']?.toString() ?? 'Salle';
    final totalSeats = room['totalSeats'] as int? ?? 20;
    final availableSeats = room['availableSeats'] as int? ?? 0;
    final isAvailable = room['isAvailable'] as bool? ?? true;

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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.meeting_room, color: Color(0xFF6366F1)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$availableSeats / $totalSeats places disponibles',
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
              color: isAvailable
                  ? const Color(0xFF10B981).withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isAvailable ? 'Actif' : 'Inactif',
              style: TextStyle(
                color: isAvailable ? const Color(0xFF10B981) : Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReservationsList() {
    final recent = _reservations.take(5).toList();

    if (recent.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'Aucune réservation',
            style: TextStyle(color: Colors.grey[600]),
          ),
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
        children: recent.map((res) => _buildReservationItem(res)).toList(),
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
              Text(
                '$roomName - Siège $seatNumber',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
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
              Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                startDt != null
                    ? '${startDt.day}/${startDt.month}/${startDt.year}'
                    : 'Date inconnue',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
}
