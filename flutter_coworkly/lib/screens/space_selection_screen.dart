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
  bool _isLoading = false;
  String? _loadError;
  List<Map<String, dynamic>> _rooms = [];

  @override
  void initState() {
    super.initState();
    _loadSpaces();
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
    final rawId = room['id'];
    final id = rawId is int ? rawId.toString() : (rawId as String?) ?? '';
    return {
      'id': id,
      'name': room['name']?.toString() ?? '',
      'description': room['description']?.toString() ?? '',
      'capacity': (room['capacity'] as num?)?.toInt() ?? 0,
      'isAvailable': room['isAvailable'] == true,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 200,
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
              ),
              Positioned(
                top: 50,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        Provider.of<AppProvider>(context, listen: false)
                            .goToHome();
                      },
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nos Espaces',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Sélectionnez un espace de coworking',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 32),
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_loadError != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Erreur: $_loadError',
                        style: TextStyle(
                          color: Colors.red[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                else if (_rooms.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.location_off,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun espace disponible',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    children: _rooms.map((space) {
                      final isSelected = selectedRoomId == space['id'];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedRoomId = space['id'];
                          });
                          // Use provider navigation
                          Provider.of<AppProvider>(context, listen: false)
                              .selectRoom(space['id'], space['name']);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: isSelected
                                ? Border.all(
                                    color: const Color(0xFF6366F1), width: 2)
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6366F1)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(
                                      Icons.meeting_room,
                                      color: Color(0xFF6366F1),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          space['name'],
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          space['description'],
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 13,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    Icons.people,
                                    size: 16,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Capacité: ${space['capacity']} places',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  if (space['isAvailable'] == true)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Disponible',
                                        style: TextStyle(
                                          color: Color(0xFF10B981),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
