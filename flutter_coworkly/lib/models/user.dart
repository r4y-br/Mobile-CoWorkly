class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String avatar;
  final bool isPremium;
  final int bookings;
  final int hours;
  final double spending;
  final DateTime memberSince;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.avatar,
    required this.isPremium,
    required this.bookings,
    required this.hours,
    required this.spending,
    required this.memberSince,
  });
}
