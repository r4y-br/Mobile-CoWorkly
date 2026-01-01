import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/rooms_api.dart';

class SpaceSelectionScreen extends StatefulWidget {
  const SpaceSelectionScreen({Key? key}) : super(key: key);

  @override
  State<SpaceSelectionScreen> createState() => _SpaceSelectionScreenState();
}

class _SpaceSelectionScreenState extends State<SpaceSelectionScreen> {
  String? selectedRoomId;
  final RoomsApi _roomsApi = RoomsApi();
  bool _isLoading = true;
  String? _loadError;
  List<Map<String, dynamic>> _rooms = [];

  @override
  void initState() {
    super.initState();
    _loadSpaces();
  }

  @override
  void dispose() {
    _roomsApi.dispose();
    super.dispose();
  }

  Future<void> _loadSpaces() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final rooms = await _roomsApi.fetchRooms();
      final mapped = rooms.map(_mapRoom).toList();
      if (!mounted) {
        return;
      }
      setState(() {
        _rooms = mapped;
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

  Map<String, dynamic> _mapRoom(Map<String, dynamic> room) {
    // Handle both int and String IDs from API
    final rawId = room['id'];
    final id = rawId is int ? rawId.toString() : (rawId as String?) ?? '';
    final color = _parseColor(room['color'] as String?, Colors.indigo);
    final gradientRaw = room['gradient'];
    final gradient = gradientRaw is List
        ? gradientRaw
            .map((value) => _parseColor(value as String?, color))
            .toList()
        : <Color>[color, color];
    final featuresRaw = room['features'];
    final features = featuresRaw is List
        ? featuresRaw.map((item) => item.toString()).toList()
        : <String>[];
    final amenitiesRaw = room['amenities'];
    final amenities = amenitiesRaw is List
        ? amenitiesRaw.map((item) {
            if (item is Map<String, dynamic>) {
              final iconName = item['icon'] as String?;
              final label = item['label']?.toString() ?? '';
              return {'icon': _iconForAmenity(iconName), 'label': label};
            }
            return {
              'icon': Icons.help_outline,
              'label': item.toString(),
            };
          }).toList()
        : <Map<String, dynamic>>[];

    return {
      'id': id,
      'name': room['name']?.toString() ?? '',
      'tagline': room['tagline']?.toString() ?? '',
      'description': room['description']?.toString() ?? '',
      'image': room['image']?.toString() ?? '',
      'totalSeats': (room['totalSeats'] as num?)?.toInt() ?? 0,
      'availableSeats': (room['availableSeats'] as num?)?.toInt() ?? 0,
      'color': color,
      'gradient': gradient.isNotEmpty ? gradient : [color, color],
      'icon': _iconForSpace(id),
      'features': features,
      'amenities': amenities,
    };
  }

  Color _parseColor(String? value, Color fallback) {
    if (value == null || value.isEmpty) {
      return fallback;
    }
    final hex = value.replaceAll('#', '');
    final normalized = hex.length == 6 ? 'FF$hex' : hex;
    final parsed = int.tryParse(normalized, radix: 16);
    if (parsed == null) {
      return fallback;
    }
    return Color(parsed);
  }

  IconData _iconForSpace(String id) {
    switch (id) {
      case 'creative-hub':
        return Icons.auto_awesome;
      case 'tech-space':
        return Icons.flash_on;
      case 'work-lounge':
        return Icons.chair;
      default:
        return Icons.apartment;
    }
  }

  IconData _iconForAmenity(String? iconName) {
    switch (iconName) {
      case 'wifi':
        return Icons.wifi;
      case 'coffee':
        return Icons.coffee;
      case 'monitor':
        return Icons.monitor;
      case 'group':
        return Icons.group;
      case 'chair':
        return Icons.chair;
      default:
        return Icons.check_circle;
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
              _loadError ?? 'Erreur lors du chargement des espaces.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSpaces,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.meeting_room, size: 48, color: Colors.grey[500]),
            const SizedBox(height: 16),
            Text(
              'Aucun espace disponible pour le moment.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSpaces,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Actualiser'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Provider.of<AppProvider>(
                        context,
                        listen: false,
                      ).goToHome(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Choisissez votre espace',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sélectionnez l\'espace adapté à vos besoins',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Spaces List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _loadError != null
                    ? _buildErrorState()
                    : _rooms.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(24),
                            itemCount: _rooms.length,
                            itemBuilder: (context, index) {
                              final space = _rooms[index];
                              final totalSeats =
                                  space['totalSeats'] as int? ?? 0;
                              final availableSeats =
                                  space['availableSeats'] as int? ?? 0;
                              final occupancyRate = totalSeats > 0
                                  ? ((totalSeats - availableSeats) /
                                          totalSeats *
                                          100)
                                      .round()
                                  : 0;
                              final isLowOccupancy = occupancyRate < 50;

                              return GestureDetector(
                                onTap: () {
                                  final appProvider = Provider.of<AppProvider>(
                                    context,
                                    listen: false,
                                  );
                                  setState(() {
                                    selectedRoomId = space['id'] as String;
                                  });
                                  Future.delayed(
                                      const Duration(milliseconds: 200), () {
                                    appProvider.selectRoom(
                                      space['id'] as String,
                                      space['name'] as String,
                                    );
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 24),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Image Header
                                      Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                    top: Radius.circular(24)),
                                            child: Image.network(
                                              space['image'] as String,
                                              height: 160,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Container(
                                                  height: 160,
                                                  color: Colors.grey[300],
                                                  child: const Center(
                                                      child: Icon(Icons
                                                          .image_not_supported)),
                                                );
                                              },
                                            ),
                                          ),
                                          Positioned.fill(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius: const BorderRadius
                                                    .vertical(
                                                    top: Radius.circular(24)),
                                                gradient: LinearGradient(
                                                  begin: Alignment.bottomCenter,
                                                  end: Alignment.topCenter,
                                                  colors: (space['gradient']
                                                          as List<Color>)
                                                      .map((c) =>
                                                          c.withOpacity(0.6))
                                                      .toList(),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 16,
                                            right: 16,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withOpacity(0.9),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration: BoxDecoration(
                                                      color: isLowOccupancy
                                                          ? const Color(
                                                              0xFF10B981)
                                                          : Colors.orange,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    '$availableSeats places libres',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 16,
                                            left: 16,
                                            child: Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withOpacity(0.9),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              child: Icon(
                                                space['icon'] as IconData,
                                                color: space['color'] as Color,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Content
                                      Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        space['name'] as String,
                                                        style: const TextStyle(
                                                          fontSize: 20,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      Text(
                                                        space['tagline']
                                                            as String,
                                                        style: TextStyle(
                                                          color:
                                                              Colors.grey[600],
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const Icon(Icons.chevron_right,
                                                    color: Colors.grey),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              space['description'] as String,
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                                height: 1.5,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            // Progress Bar
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'Occupation',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                Text(
                                                  '$occupancyRate%',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              child: LinearProgressIndicator(
                                                value: occupancyRate / 100,
                                                backgroundColor:
                                                    Colors.grey[200],
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                            Color>(
                                                        space['color']
                                                            as Color),
                                                minHeight: 8,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            // Features
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: (space['features']
                                                      as List<String>)
                                                  .map((feature) => Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 12,
                                                                vertical: 6),
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              Colors.grey[100],
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(20),
                                                        ),
                                                        child: Text(
                                                          feature,
                                                          style: TextStyle(
                                                            color: Colors
                                                                .grey[800],
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ))
                                                  .toList(),
                                            ),
                                            const SizedBox(height: 16),
                                            const Divider(),
                                            const SizedBox(height: 16),
                                            // Amenities
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceAround,
                                              children: (space['amenities']
                                                      as List<
                                                          Map<String, dynamic>>)
                                                  .map((amenity) => Row(
                                                        children: [
                                                          Icon(
                                                            amenity['icon']
                                                                as IconData,
                                                            size: 16,
                                                            color: Colors
                                                                .grey[600],
                                                          ),
                                                          const SizedBox(
                                                              width: 4),
                                                          Text(
                                                            amenity['label']
                                                                as String,
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .grey[600],
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ],
                                                      ))
                                                  .toList(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
