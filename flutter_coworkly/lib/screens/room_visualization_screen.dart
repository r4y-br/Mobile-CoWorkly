import 'package:flutter/material.dart';

class RoomVisualizationScreen extends StatefulWidget {
  const RoomVisualizationScreen({Key? key}) : super(key: key);

  @override
  State<RoomVisualizationScreen> createState() =>
      _RoomVisualizationScreenState();
}

class _RoomVisualizationScreenState extends State<RoomVisualizationScreen> {
  String? selectedSeatId;
  final TransformationController _transformationController =
      TransformationController();

  final List<Map<String, dynamic>> seats = [
    // Rangée 1
    {'id': 's1', 'number': 1, 'status': 'available', 'x': 0.2, 'y': 0.2},
    {'id': 's2', 'number': 2, 'status': 'occupied', 'x': 0.4, 'y': 0.2},
    {'id': 's3', 'number': 3, 'status': 'available', 'x': 0.6, 'y': 0.2},
    {'id': 's4', 'number': 4, 'status': 'reserved', 'x': 0.8, 'y': 0.2},
    // Rangée 2
    {'id': 's5', 'number': 5, 'status': 'available', 'x': 0.2, 'y': 0.4},
    {'id': 's6', 'number': 6, 'status': 'available', 'x': 0.4, 'y': 0.4},
    {'id': 's7', 'number': 7, 'status': 'occupied', 'x': 0.6, 'y': 0.4},
    {'id': 's8', 'number': 8, 'status': 'available', 'x': 0.8, 'y': 0.4},
    // Rangée 3
    {'id': 's9', 'number': 9, 'status': 'reserved', 'x': 0.2, 'y': 0.6},
    {'id': 's10', 'number': 10, 'status': 'available', 'x': 0.4, 'y': 0.6},
    {'id': 's11', 'number': 11, 'status': 'available', 'x': 0.6, 'y': 0.6},
    {'id': 's12', 'number': 12, 'status': 'occupied', 'x': 0.8, 'y': 0.6},
    // Rangée 4
    {'id': 's13', 'number': 13, 'status': 'available', 'x': 0.2, 'y': 0.8},
    {'id': 's14', 'number': 14, 'status': 'available', 'x': 0.4, 'y': 0.8},
    {'id': 's15', 'number': 15, 'status': 'available', 'x': 0.6, 'y': 0.8},
    {'id': 's16', 'number': 16, 'status': 'reserved', 'x': 0.8, 'y': 0.8},
  ];

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

  @override
  Widget build(BuildContext context) {
    final availableCount =
        seats.where((s) => s['status'] == 'available').length;
    final occupiedCount = seats.where((s) => s['status'] == 'occupied').length;
    final reservedCount = seats.where((s) => s['status'] == 'reserved').length;

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
                            onPressed: () => Navigator.pop(context),
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
                                'CoWorkly - Salle principale',
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
                _buildStatCard(availableCount, 'Disponibles', Colors.green),
                const SizedBox(width: 12),
                _buildStatCard(occupiedCount, 'Occupés', Colors.red),
                const SizedBox(width: 12),
                _buildStatCard(reservedCount, 'Réservés', Colors.orange),
              ],
            ),
          ),
          // Room Plan
          Expanded(
            child: Padding(
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
                        transformationController: _transformationController,
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
                                  bottom: constraints.maxHeight * 0.15,
                                  left: constraints.maxWidth * 0.15,
                                  width: constraints.maxWidth * 0.3,
                                  height: constraints.maxHeight * 0.2,
                                  child: _buildTableZone(),
                                ),
                                Positioned(
                                  bottom: constraints.maxHeight * 0.15,
                                  right: constraints.maxWidth * 0.15,
                                  width: constraints.maxWidth * 0.3,
                                  height: constraints.maxHeight * 0.2,
                                  child: _buildTableZone(),
                                ),
                                // Seats
                                ...seats.map((seat) {
                                  final isSelected =
                                      selectedSeatId == seat['id'];
                                  return Positioned(
                                    left: constraints.maxWidth *
                                            (seat['x'] as double) -
                                        20,
                                    top: constraints.maxHeight *
                                            (seat['y'] as double) -
                                        20,
                                    child: GestureDetector(
                                      onTap: () {
                                        if (seat['status'] == 'available') {
                                          setState(() {
                                            selectedSeatId =
                                                seat['id'] as String;
                                          });
                                        }
                                      },
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: getStatusColor(
                                              seat['status'] as String),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: isSelected
                                              ? Border.all(
                                                  color:
                                                      const Color(0xFF6366F1),
                                                  width: 3)
                                              : null,
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.1),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${seat['number']}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
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
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF6366F1),
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(16)),
                                    ),
                                    child: const Text(
                                      'Entrée',
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
                              _transformationController.value.scale(1.2);
                            }),
                            const SizedBox(height: 8),
                            _buildZoomButton(Icons.remove, () {
                              _transformationController.value.scale(0.8);
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
                            _buildLegendItem(Colors.green, 'Disponible'),
                            const SizedBox(width: 16),
                            _buildLegendItem(Colors.red, 'Occupé'),
                            const SizedBox(width: 16),
                            _buildLegendItem(Colors.orange, 'Réservé'),
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
                              'Siège ${seats.firstWhere((s) => s['id'] == selectedSeatId)['number']}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Zone principale',
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
                            'Disponible',
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
                          // Handle booking
                          Navigator.pop(context, selectedSeatId);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Réserver ce siège'),
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
