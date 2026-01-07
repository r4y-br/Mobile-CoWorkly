import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/seats_api.dart';

class RoomVisualizationScreen extends StatefulWidget {
  const RoomVisualizationScreen({Key? key}) : super(key: key);

  @override
  State<RoomVisualizationScreen> createState() =>
      _RoomVisualizationScreenState();
}

class _RoomVisualizationScreenState extends State<RoomVisualizationScreen> {
  String? selectedSeatId;
  int? selectedSeatNumber;
  final TransformationController _transformationController =
      TransformationController();

  final SeatsApi _seatsApi = SeatsApi();
  bool _isLoading = true;
  String? _loadError;
  List<Map<String, dynamic>> _seats = [];

  final List<Map<String, dynamic>> _seatLayout = [
    // Row 1
    {'number': 1, 'x': 0.2, 'y': 0.2},
    {'number': 2, 'x': 0.4, 'y': 0.2},
    {'number': 3, 'x': 0.6, 'y': 0.2},
    {'number': 4, 'x': 0.8, 'y': 0.2},
    // Row 2
    {'number': 5, 'x': 0.2, 'y': 0.4},
    {'number': 6, 'x': 0.4, 'y': 0.4},
    {'number': 7, 'x': 0.6, 'y': 0.4},
    {'number': 8, 'x': 0.8, 'y': 0.4},
    // Row 3
    {'number': 9, 'x': 0.2, 'y': 0.6},
    {'number': 10, 'x': 0.4, 'y': 0.6},
    {'number': 11, 'x': 0.6, 'y': 0.6},
    {'number': 12, 'x': 0.8, 'y': 0.6},
    // Row 4
    {'number': 13, 'x': 0.2, 'y': 0.8},
    {'number': 14, 'x': 0.4, 'y': 0.8},
    {'number': 15, 'x': 0.6, 'y': 0.8},
    {'number': 16, 'x': 0.8, 'y': 0.8},
  ];

  @override
  void initState() {
    super.initState();
    _loadSeats();
  }

  @override
  void dispose() {
    _seatsApi.dispose();
    super.dispose();
  }

  Future<void> _loadSeats() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
      selectedSeatId = null;
      selectedSeatNumber = null;
    });

    final roomId =
        Provider.of<AppProvider>(context, listen: false).selectedRoomId;
    if (roomId == null || roomId.isEmpty) {
      setState(() {
        _loadError = 'No room selected.';
        _isLoading = false;
      });
      return;
    }

    try {
      final seats = await _seatsApi.fetchSeats(roomId: roomId);
      final byNumber = <int, Map<String, dynamic>>{};
      for (final seat in seats) {
        final number = seat['number'];
        if (number is int) {
          byNumber[number] = seat;
        }
      }

      final mapped = _seatLayout.map((layout) {
        final number = layout['number'] as int;
        final apiSeat = byNumber[number];
        final status = apiSeat != null
            ? _mapStatus(apiSeat['status'] as String?)
            : 'available';
        // Handle both int and String IDs from API
        final rawId = apiSeat?['id'];
        final id = rawId is int ? rawId.toString() : rawId?.toString();
        return {
          'id': id,
          'number': number,
          'status': status,
          'x': layout['x'],
          'y': layout['y'],
        };
      }).toList();

      if (!mounted) {
        return;
      }
      setState(() {
        _seats = mapped;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadError = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  String _mapStatus(String? status) {
    switch (status) {
      case 'AVAILABLE':
        return 'available';
      case 'OCCUPIED':
        return 'occupied';
      case 'RESERVED':
        return 'reserved';
      default:
        return 'available';
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'available':
        return const Color(0xFF10B981);
      case 'occupied':
        return const Color(0xFFEF4444);
      case 'reserved':
        return const Color(0xFFF59E0B);
      default:
        return Colors.grey;
    }
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 48, color: Colors.grey[500]),
            const SizedBox(height: 16),
            Text(
              _loadError ?? 'Error loading seats.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSeats,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableCount =
        _seats.where((s) => s['status'] == 'available').length;
    final occupiedCount = _seats.where((s) => s['status'] == 'occupied').length;
    final reservedCount = _seats.where((s) => s['status'] == 'reserved').length;
    final spaceName = Provider.of<AppProvider>(context).selectedRoomName;
    final subtitle = spaceName.isNotEmpty
        ? 'CoWorkly - $spaceName'
        : 'CoWorkly - Salle principale';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header
          Stack(
            children: [
              Container(
                height: 140,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(48),
                    bottomRight: Radius.circular(48),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -30,
                      right: -30,
                      child: Container(
                        width: 128,
                        height: 128,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -30,
                      left: -30,
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 48, 16, 0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white),
                            onPressed: () => Provider.of<AppProvider>(
                              context,
                              listen: false,
                            ).goToSpaceSelection(),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Plan de la salle',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Stats
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildStatCard(availableCount, 'Available', Colors.green),
                const SizedBox(width: 12),
                _buildStatCard(occupiedCount, 'Occupied', Colors.red),
                const SizedBox(width: 12),
                _buildStatCard(reservedCount, 'Reserved', Colors.orange),
              ],
            ),
          ),
          // Room Plan
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _loadError != null
                    ? _buildErrorState()
                    : Padding(
                        padding: const EdgeInsets.all(16),
                        child: Container(
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
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Stack(
                              children: [
                                InteractiveViewer(
                                  transformationController:
                                      _transformationController,
                                  minScale: 0.5,
                                  maxScale: 3.0,
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      return Stack(
                                        children: [
                                          // Tables (zones)
                                          Positioned(
                                            top: constraints.maxHeight * 0.15,
                                            left: constraints.maxWidth * 0.15,
                                            width: constraints.maxWidth * 0.3,
                                            height: constraints.maxHeight * 0.2,
                                            child: _buildTableZone(),
                                          ),
                                          Positioned(
                                            top: constraints.maxHeight * 0.15,
                                            right: constraints.maxWidth * 0.15,
                                            width: constraints.maxWidth * 0.3,
                                            height: constraints.maxHeight * 0.2,
                                            child: _buildTableZone(),
                                          ),
                                          Positioned(
                                            bottom:
                                                constraints.maxHeight * 0.15,
                                            left: constraints.maxWidth * 0.15,
                                            width: constraints.maxWidth * 0.3,
                                            height: constraints.maxHeight * 0.2,
                                            child: _buildTableZone(),
                                          ),
                                          Positioned(
                                            bottom:
                                                constraints.maxHeight * 0.15,
                                            right: constraints.maxWidth * 0.15,
                                            width: constraints.maxWidth * 0.3,
                                            height: constraints.maxHeight * 0.2,
                                            child: _buildTableZone(),
                                          ),
                                          // Seats
                                          ..._seats.map((seat) {
                                            final isSelected =
                                                selectedSeatId == seat['id'];
                                            final seatId =
                                                seat['id'] as String?;
                                            final isAvailable =
                                                seat['status'] == 'available';
                                            return Positioned(
                                              left: constraints.maxWidth *
                                                      (seat['x'] as double) -
                                                  20,
                                              top: constraints.maxHeight *
                                                      (seat['y'] as double) -
                                                  20,
                                              child: GestureDetector(
                                                onTap: () {
                                                  if (isAvailable &&
                                                      seatId != null) {
                                                    setState(() {
                                                      selectedSeatId = seatId;
                                                      selectedSeatNumber =
                                                          seat['number'] as int;
                                                    });
                                                  }
                                                },
                                                child: Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color: getStatusColor(
                                                        seat['status']
                                                            as String),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    border: isSelected
                                                        ? Border.all(
                                                            color: const Color(
                                                                0xFF6366F1),
                                                            width: 3)
                                                        : null,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withOpacity(0.1),
                                                        blurRadius: 4,
                                                        offset:
                                                            const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      '${seat['number']}',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                          // Entrance
                                          Positioned(
                                            bottom: 0,
                                            left: constraints.maxWidth / 2 - 40,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 8),
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF6366F1),
                                                borderRadius:
                                                    BorderRadius.vertical(
                                                        top: Radius.circular(
                                                            16)),
                                              ),
                                              child: const Text(
                                                'Entrance',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                                // Zoom Controls
                                Positioned(
                                  top: 16,
                                  right: 16,
                                  child: Column(
                                    children: [
                                      _buildZoomButton(Icons.add, () {
                                        _transformationController.value
                                            .scale(1.2);
                                      }),
                                      const SizedBox(height: 8),
                                      _buildZoomButton(Icons.remove, () {
                                        _transformationController.value
                                            .scale(0.8);
                                      }),
                                    ],
                                  ),
                                ),
                                // Legend
                                Positioned(
                                  bottom: 16,
                                  left: 16,
                                  right: 16,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildLegendItem(
                                          Colors.green, 'Available'),
                                      const SizedBox(width: 16),
                                      _buildLegendItem(Colors.red, 'Occupied'),
                                      const SizedBox(width: 16),
                                      _buildLegendItem(
                                          Colors.orange, 'Reserved'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
          ),
          // Selection Info
          if (selectedSeatId != null)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Seat ${selectedSeatNumber ?? ''}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Main area',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Available',
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final seatId = selectedSeatId;
                          final seatNumber = selectedSeatNumber;
                          if (seatId == null || seatNumber == null) {
                            return;
                          }
                          Provider.of<AppProvider>(
                            context,
                            listen: false,
                          ).selectSeat(seatId, seatNumber);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Book this seat'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(int count, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableZone() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[300]!,
          style: BorderStyle
              .solid, // Dashed border is harder in Flutter without package
          width: 2,
        ),
      ),
    );
  }

  Widget _buildZoomButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 20),
        onPressed: onPressed,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
