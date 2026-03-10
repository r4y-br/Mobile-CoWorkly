class Booking {
  final String id;
  final int seatId;
  final String? roomName;
  final DateTime startTime;
  final DateTime endTime;
  final String type; // 'HOURLY', 'DAILY'
  final String status; // 'PENDING', 'CONFIRMED', 'CANCELLED'

  Booking({
    required this.id,
    required this.seatId,
    this.roomName,
    required this.startTime,
    required this.endTime,
    required this.type,
    required this.status,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    final seat = json['seat'] as Map<String, dynamic>?;
    final room = seat?['room'] as Map<String, dynamic>?;
    return Booking(
      id: json['id'].toString(),
      seatId: json['seatId'] as int,
      roomName: room?['name'] as String?,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      type: json['type'] as String? ?? 'HOURLY',
      status: json['status'] as String? ?? 'PENDING',
    );
  }
}
