class Booking {
  final String id;
  final String spaceId;
  final String spaceName;
  final DateTime date;
  final String startTime;
  final String duration;
  final String type; // 'hourly', 'daily', 'weekly'
  final double price;
  final String paymentMethod;
  final String status; // 'pending', 'confirmed', 'completed', 'cancelled'

  Booking({
    required this.id,
    required this.spaceId,
    required this.spaceName,
    required this.date,
    required this.startTime,
    required this.duration,
    required this.type,
    required this.price,
    required this.paymentMethod,
    required this.status,
  });
}
