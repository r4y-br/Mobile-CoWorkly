class SubscriptionData {
  final String planEnum;
  final String status;
  final int usedHours;
  final int totalHours;
  final DateTime? endDate;

  SubscriptionData({
    required this.planEnum,
    required this.status,
    required this.usedHours,
    required this.totalHours,
    this.endDate,
  });

  // Transforme MONTHLY en "Pro", etc.
  String get displayName {
    switch (planEnum) {
      case 'MONTHLY':
        return 'Pro';
      case 'QUARTERLY':
        return 'Business';
      case 'SEMI_ANNUAL':
        return 'Expert';
      default:
        return 'Gratuit';
    }
  }

  factory SubscriptionData.fromJson(Map<String, dynamic> json) {
    return SubscriptionData(
      planEnum: json['plan'] ?? 'NONE',
      status: json['status'] ?? 'INACTIVE',
      usedHours: json['usedHours'] ?? 0,
      totalHours: json['totalHours'] ?? 2,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
    );
  }
}
