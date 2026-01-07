import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../services/rooms_api.dart';
import '../services/reservations_api.dart';
import '../services/seats_api.dart';

class AdminDashboardNew extends StatefulWidget {
  const AdminDashboardNew({Key? key}) : super(key: key);

  @override
  State<AdminDashboardNew> createState() => _AdminDashboardNewState();
}

class _AdminDashboardNewState extends State<AdminDashboardNew> {
  final RoomsApi _roomsApi = RoomsApi();
  final ReservationsApi _reservationsApi = ReservationsApi();
  final SeatsApi _seatsApi = SeatsApi();

  List<Map<String, dynamic>> _rooms = [];
  List<Map<String, dynamic>> _reservations = [];
  Map<int, List<Map<String, dynamic>>> _seatsByRoom = {};
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  
  bool _isLoading = true;
  String? _error;
  
  // Room images for visual display
  final Map<String, String> _roomImages = {
    'creative-hub': 'https://images.unsplash.com/photo-1497366216548-37526070297c?w=800',
    'tech-space': 'https://images.unsplash.com/photo-1497215842964-222b430dc094?w=800',
    'work-lounge': 'https://images.unsplash.com/photo-1519389950473-47ba0277781c?w=800',
    'default': 'https://images.unsplash.com/photo-1527192491265-7e15c55b1ed2?w=800',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final token = appProvider.authToken;
    
    if (token == null) {
      setState(() {
        _error = 'Not authenticated';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load rooms and reservations in parallel
      final results = await Future.wait([
        _roomsApi.fetchRooms(),
        _reservationsApi.fetchAllReservations(token: token),
      ]);

      final rooms = results[0] as List<Map<String, dynamic>>;
      final reservations = results[1] as List<Map<String, dynamic>>;

      // Load seats for each room
      final seatsByRoom = <int, List<Map<String, dynamic>>>{};
      for (final room in rooms) {
        final roomId = room['id'];
        if (roomId != null) {
          try {
            final seats = await _seatsApi.fetchSeats(roomId: roomId.toString());
            seatsByRoom[roomId as int] = seats;
          } catch (e) {
            print('Error loading seats for room $roomId: $e');
            seatsByRoom[roomId as int] = [];
          }
        }
      }

      setState(() {
        _rooms = rooms;
        _reservations = reservations;
        _seatsByRoom = seatsByRoom;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getReservationsForDateTime() {
    final selectedDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    return _reservations.where((res) {
      try {
        // IMPORTANT: Only count CONFIRMED reservations as occupied!
        final status = res['status']?.toString().toUpperCase() ?? '';
        if (status != 'CONFIRMED') {
          return false; // Ignore PENDING, CANCELLED, etc.
        }
        
        final startTime = DateTime.parse(res['startTime'] ?? '');
        final endTime = DateTime.parse(res['endTime'] ?? '');
        
        // Check if selected datetime falls within reservation period
        return (selectedDateTime.isAfter(startTime) || selectedDateTime.isAtSameMomentAs(startTime)) 
            && selectedDateTime.isBefore(endTime);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  Map<int, List<Map<String, dynamic>>> _getReservationsByRoom() {
    final activeReservations = _getReservationsForDateTime();
    final byRoom = <int, List<Map<String, dynamic>>>{};

    for (final res in activeReservations) {
      final seat = res['seat'] as Map<String, dynamic>?;
      final roomId = seat?['roomId'] as int?;
      if (roomId != null) {
        byRoom.putIfAbsent(roomId, () => []);
        byRoom[roomId]!.add(res);
      }
    }

    return byRoom;
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6366F1),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6366F1),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  void dispose() {
    _roomsApi.dispose();
    _reservationsApi.dispose();
    _seatsApi.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(appProvider),
          _buildDateTimeSelector(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorState()
                    : _buildRoomsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppProvider appProvider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => appProvider.setActiveTab('home'),
              ),
              const Expanded(
                child: Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _loadData,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatBadge(
                Icons.meeting_room,
                '${_rooms.length}',
                'Rooms',
              ),
              _buildStatBadge(
                Icons.event_seat,
                '${_seatsByRoom.values.fold(0, (sum, seats) => sum + seats.length)}',
                'Seats',
              ),
              _buildStatBadge(
                Icons.calendar_today,
                '${_reservations.where((r) => r['status']?.toString().toUpperCase() == 'CONFIRMED').length}',
                'Reservations',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
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
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
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
          const Text(
            'Select date and time',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20, color: Color(0xFF6366F1)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            DateFormat('MM/dd/yyyy').format(_selectedDate),
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: _selectTime,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, size: 20, color: Color(0xFF6366F1)),
                        const SizedBox(width: 10),
                        Text(
                          _selectedTime.format(context),
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Color(0xFF6366F1)),
                const SizedBox(width: 8),
                Text(
                  '${_getReservationsForDateTime().length} active reservation(s) at this time',
                  style: const TextStyle(
                    color: Color(0xFF6366F1),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Loading Error',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'An error occurred',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomsList() {
    final reservationsByRoom = _getReservationsByRoom();

    if (_rooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.meeting_room_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No rooms available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: _rooms.length,
      itemBuilder: (context, index) {
        final room = _rooms[index];
        final roomId = room['id'] as int?;
        final roomReservations = roomId != null 
            ? (reservationsByRoom[roomId] ?? <Map<String, dynamic>>[]) 
            : <Map<String, dynamic>>[];
        final roomSeats = roomId != null 
            ? (_seatsByRoom[roomId] ?? <Map<String, dynamic>>[]) 
            : <Map<String, dynamic>>[];

        return _buildRoomCard(room, roomReservations, roomSeats);
      },
    );
  }

  String _getRoomImage(Map<String, dynamic> room) {
    final roomId = room['id']?.toString() ?? '';
    final roomName = (room['name'] ?? '').toString().toLowerCase();
    
    // Check if room has its own image
    if (room['image'] != null && room['image'].toString().isNotEmpty) {
      return room['image'].toString();
    }
    
    // Use default images based on room name/type
    if (roomName.contains('creative') || roomName.contains('art')) {
      return _roomImages['creative-hub']!;
    } else if (roomName.contains('tech') || roomName.contains('digital')) {
      return _roomImages['tech-space']!;
    } else if (roomName.contains('lounge') || roomName.contains('relax')) {
      return _roomImages['work-lounge']!;
    }
    
    return _roomImages['default']!;
  }

  Widget _buildRoomCard(
    Map<String, dynamic> room,
    List<Map<String, dynamic>> reservations,
    List<Map<String, dynamic>> seats,
  ) {
    final roomName = room['name'] ?? 'Unnamed Room';
    final capacity = room['capacity'] ?? seats.length;
    final occupiedSeats = reservations.length;
    final availableSeats = capacity - occupiedSeats;
    final occupancyRate = capacity > 0 ? (occupiedSeats / capacity * 100).round() : 0;
    final roomImage = _getRoomImage(room);

    Color occupancyColor;
    if (occupancyRate < 30) {
      occupancyColor = const Color(0xFF10B981);
    } else if (occupancyRate < 70) {
      occupancyColor = const Color(0xFFF59E0B);
    } else {
      occupancyColor = const Color(0xFFEF4444);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
          // Image Header like user interface
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Image.network(
                  roomImage,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 140,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF6366F1),
                            const Color(0xFF8B5CF6),
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: const Center(
                        child: Icon(Icons.meeting_room, size: 48, color: Colors.white70),
                      ),
                    );
                  },
                ),
              ),
              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Room name on image
              Positioned(
                bottom: 12,
                left: 16,
                child: Text(
                  roomName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 3,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
              ),
              // Occupancy badge
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: occupancyColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$availableSeats available',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Stats row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildRoomStat(
                    Icons.event_seat,
                    '$availableSeats',
                    'Available',
                    const Color(0xFF10B981),
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey[300],
                ),
                Expanded(
                  child: _buildRoomStat(
                    Icons.person,
                    '$occupiedSeats',
                    'Occupied',
                    const Color(0xFFEF4444),
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey[300],
                ),
                Expanded(
                  child: _buildRoomStat(
                    Icons.chair,
                    '$capacity',
                    'Total',
                    const Color(0xFF6366F1),
                  ),
                ),
              ],
            ),
          ),
          // Reservations list
          if (reservations.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Color(0xFF6366F1)),
                      const SizedBox(width: 8),
                      Text(
                        'Active Reservations (${reservations.length})',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...reservations.map((res) => _buildReservationItem(res)),
                ],
              ),
            ),
          ],
          // Seat grid visualization
          if (seats.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Seat Visualization',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSeatGrid(seats, reservations),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoomStat(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildReservationItem(Map<String, dynamic> reservation) {
    final user = reservation['user'] as Map<String, dynamic>?;
    final seat = reservation['seat'] as Map<String, dynamic>?;
    final userName = user?['name'] ?? 'Unknown user';
    final userEmail = user?['email'] ?? '';
    final seatNumber = seat?['number'] ?? '?';
    final status = reservation['status'] ?? 'PENDING';

    String startTimeStr = '';
    String endTimeStr = '';
    try {
      final startTime = DateTime.parse(reservation['startTime'] ?? '');
      final endTime = DateTime.parse(reservation['endTime'] ?? '');
      startTimeStr = DateFormat('HH:mm').format(startTime);
      endTimeStr = DateFormat('HH:mm').format(endTime);
    } catch (e) {
      startTimeStr = '--:--';
      endTimeStr = '--:--';
    }

    Color statusColor;
    String statusLabel;
    switch (status.toString().toUpperCase()) {
      case 'CONFIRMED':
        statusColor = const Color(0xFF10B981);
        statusLabel = 'Confirmed';
        break;
      case 'PENDING':
        statusColor = const Color(0xFFF59E0B);
        statusLabel = 'Pending';
        break;
      case 'CANCELLED':
        statusColor = const Color(0xFFEF4444);
        statusLabel = 'Cancelled';
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = status;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$seatNumber',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6366F1),
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
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  userEmail,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$startTimeStr - $endTimeStr',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeatGrid(List<Map<String, dynamic>> seats, List<Map<String, dynamic>> reservations) {
    // Get reserved seat IDs from CONFIRMED reservations only
    final reservedSeatIds = reservations
        .where((r) => r['status']?.toString().toUpperCase() == 'CONFIRMED')
        .map((r) => r['seat']?['id'])
        .whereType<int>()
        .toSet();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: seats.map((seat) {
        final seatId = seat['id'] as int?;
        final seatNumber = seat['number'] ?? '?';
        final isReserved = seatId != null && reservedSeatIds.contains(seatId);

        Color seatColor;
        IconData seatIcon;
        String seatStatus;
        
        if (isReserved) {
          seatColor = const Color(0xFFEF4444);
          seatIcon = Icons.person;
          seatStatus = 'Occupied';
        } else {
          seatColor = const Color(0xFF10B981);
          seatIcon = Icons.event_seat;
          seatStatus = 'Available';
        }

        return Tooltip(
          message: 'Seat $seatNumber - $seatStatus',
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: seatColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: seatColor, width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(seatIcon, size: 16, color: seatColor),
                Text(
                  '$seatNumber',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: seatColor,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
