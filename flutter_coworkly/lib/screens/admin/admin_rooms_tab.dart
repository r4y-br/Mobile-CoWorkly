import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../services/rooms_api.dart';
import '../../services/seats_api.dart';
import '../../widgets/index.dart';

class AdminRoomsTab extends StatefulWidget {
  const AdminRoomsTab({Key? key}) : super(key: key);

  @override
  State<AdminRoomsTab> createState() => _AdminRoomsTabState();
}

class _AdminRoomsTabState extends State<AdminRoomsTab> {
  final RoomsApi _roomsApi = RoomsApi();
  final SeatsApi _seatsApi = SeatsApi();
  
  List<Map<String, dynamic>> _rooms = [];
  bool _isLoading = true;
  String? _error;
  String? _expandedRoomId;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  @override
  void dispose() {
    _roomsApi.dispose();
    _seatsApi.dispose();
    super.dispose();
  }

  Future<void> _loadRooms() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rooms = await _roomsApi.fetchRooms();
      setState(() {
        _rooms = rooms;
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
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingState(message: 'Loading rooms...');
    }

    if (_error != null) {
      return ErrorState(
        message: _error!,
        onRetry: _loadRooms,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRooms,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header with add button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Room Management',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              CustomIconButton(
                icon: Icons.add,
                onPressed: _showAddRoomDialog,
                backgroundColor: const Color(0xFF6366F1),
                iconColor: Colors.white,
                tooltip: 'Add a room',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_rooms.length} rooms configured',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 20),

          // Rooms list
          if (_rooms.isEmpty)
            const EmptyState(
              title: 'No rooms',
              message: 'Start by creating a room',
              icon: Icons.meeting_room,
            )
          else
            ..._rooms.map((room) => _buildRoomCard(room)),
        ],
      ),
    );
  }

  Widget _buildRoomCard(Map<String, dynamic> room) {
    final id = room['id'].toString();
    final name = room['name'] ?? 'Unnamed room';
    final description = room['description'] ?? '';
    final capacity = room['capacity'] ?? 0;
    final seats = room['seats'] as List? ?? [];
    final seatCount = seats.length;
    final availableSeats = seats.where((s) => s['status'] == 'AVAILABLE').length;
    final isExpanded = _expandedRoomId == id;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          // Room header
          InkWell(
            onTap: () {
              setState(() {
                _expandedRoomId = isExpanded ? null : id;
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.meeting_room,
                          color: Color(0xFF6366F1),
                          size: 28,
                        ),
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
                                fontSize: 18,
                              ),
                            ),
                            if (description.isNotEmpty)
                              Text(
                                description,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildRoomStat(
                        Icons.event_seat,
                        '$seatCount',
                        'Seats',
                        const Color(0xFF3B82F6),
                      ),
                      const SizedBox(width: 16),
                      _buildRoomStat(
                        Icons.check_circle,
                        '$availableSeats',
                        'Available',
                        const Color(0xFF10B981),
                      ),
                      const SizedBox(width: 16),
                      _buildRoomStat(
                        Icons.people,
                        '$capacity',
                        'Max capacity',
                        Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showEditRoomDialog(room),
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Edit'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF6366F1),
                            side: const BorderSide(color: Color(0xFF6366F1)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showAddSeatDialog(id),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add seat'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF10B981),
                            side: const BorderSide(color: Color(0xFF10B981)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _deleteRoom(id, name),
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Delete room'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  
                  // Seats list
                  if (seats.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Seats',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: seats.map<Widget>((seat) => _buildSeatChip(seat)).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoomStat(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeatChip(Map<String, dynamic> seat) {
    final number = seat['number'] ?? 0;
    final status = seat['status'] ?? 'AVAILABLE';
    final seatId = seat['id'].toString();

    Color chipColor;
    switch (status) {
      case 'AVAILABLE':
        chipColor = const Color(0xFF10B981);
        break;
      case 'OCCUPIED':
        chipColor = Colors.red;
        break;
      case 'RESERVED':
        chipColor = const Color(0xFF3B82F6);
        break;
      case 'MAINTENANCE':
        chipColor = Colors.grey;
        break;
      default:
        chipColor = Colors.grey;
    }

    return GestureDetector(
      onTap: () => _showSeatOptions(seat),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: chipColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: chipColor.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_seat, size: 14, color: chipColor),
            const SizedBox(width: 4),
            Text(
              '#$number',
              style: TextStyle(
                color: chipColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSeatOptions(Map<String, dynamic> seat) {
    final seatId = seat['id'].toString();
    final number = seat['number'];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Place #$number',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildStatusOption('AVAILABLE', 'Available', Icons.check_circle, const Color(0xFF10B981), seatId),
            _buildStatusOption('MAINTENANCE', 'Maintenance', Icons.build, Colors.grey, seatId),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _deleteSeat(seatId, number);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption(String status, String label, IconData icon, Color color, String seatId) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        _updateSeatStatus(seatId, status);
      },
    );
  }

  Future<void> _showAddRoomDialog() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final capacityController = TextEditingController(text: '10');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New room'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Room name',
                prefixIcon: Icon(Icons.meeting_room),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: capacityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Capacity',
                prefixIcon: Icon(Icons.people),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _createRoom(
                nameController.text,
                descController.text,
                int.tryParse(capacityController.text) ?? 10,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditRoomDialog(Map<String, dynamic> room) async {
    final nameController = TextEditingController(text: room['name']);
    final descController = TextEditingController(text: room['description'] ?? '');
    final capacityController = TextEditingController(text: '${room['capacity'] ?? 10}');
    final roomId = room['id'].toString();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit room'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Room name',
                prefixIcon: Icon(Icons.meeting_room),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: capacityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Capacity',
                prefixIcon: Icon(Icons.people),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _updateRoom(
                roomId,
                nameController.text,
                descController.text,
                int.tryParse(capacityController.text) ?? 10,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddSeatDialog(String roomId) async {
    final numberController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New seat'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: TextField(
          controller: numberController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Seat number',
            prefixIcon: Icon(Icons.event_seat),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _createSeat(roomId, int.tryParse(numberController.text) ?? 1);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _createRoom(String name, String description, int capacity) async {
    final token = Provider.of<AppProvider>(context, listen: false).authToken;
    if (token == null) return;

    try {
      await _roomsApi.createRoom(
        token: token,
        name: name,
        description: description,
        capacity: capacity,
      );
      _showSuccess('Room created!');
      _loadRooms();
    } catch (e) {
      _showError('Error: $e');
    }
  }

  Future<void> _updateRoom(String roomId, String name, String description, int capacity) async {
    final token = Provider.of<AppProvider>(context, listen: false).authToken;
    if (token == null) return;

    try {
      await _roomsApi.updateRoom(
        token: token,
        roomId: roomId,
        name: name,
        description: description,
        capacity: capacity,
      );
      _showSuccess('Room updated!');
      _loadRooms();
    } catch (e) {
      _showError('Error: $e');
    }
  }

  Future<void> _deleteRoom(String roomId, String name) async {
    final confirm = await ConfirmDialog.show(
      context: context,
      title: 'Delete room',
      message: 'Delete "$name" and all its seats?',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (confirm != true) return;

    final token = Provider.of<AppProvider>(context, listen: false).authToken;
    if (token == null) return;

    try {
      await _roomsApi.deleteRoom(token: token, roomId: roomId);
      _showSuccess('Room deleted');
      _loadRooms();
    } catch (e) {
      _showError('Error: $e');
    }
  }

  Future<void> _createSeat(String roomId, int number) async {
    final token = Provider.of<AppProvider>(context, listen: false).authToken;
    if (token == null) return;

    try {
      await _seatsApi.createSeat(token: token, roomId: roomId, number: number);
      _showSuccess('Seat created!');
      _loadRooms();
    } catch (e) {
      _showError('Error: $e');
    }
  }

  Future<void> _updateSeatStatus(String seatId, String status) async {
    final token = Provider.of<AppProvider>(context, listen: false).authToken;
    if (token == null) return;

    try {
      await _seatsApi.updateSeat(token: token, seatId: seatId, status: status);
      _showSuccess('Status updated');
      _loadRooms();
    } catch (e) {
      _showError('Error: $e');
    }
  }

  Future<void> _deleteSeat(String seatId, int number) async {
    final confirm = await ConfirmDialog.show(
      context: context,
      title: 'Delete seat',
      message: 'Delete seat #$number?',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (confirm != true) return;

    final token = Provider.of<AppProvider>(context, listen: false).authToken;
    if (token == null) return;

    try {
      await _seatsApi.deleteSeat(token: token, seatId: seatId);
      _showSuccess('Seat deleted');
      _loadRooms();
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
