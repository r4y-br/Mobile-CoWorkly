import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final Map<String, StatusStyle>? customStyles;

  const StatusBadge({
    Key? key,
    required this.status,
    this.customStyles,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final style = _getStyle();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: style.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (style.icon != null) ...[
            Icon(style.icon, size: 12, color: style.color),
            const SizedBox(width: 4),
          ],
          Text(
            style.label,
            style: TextStyle(
              color: style.color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  StatusStyle _getStyle() {
    if (customStyles?.containsKey(status) == true) {
      return customStyles![status]!;
    }

    switch (status.toUpperCase()) {
      // Reservation statuses
      case 'CONFIRMED':
        return StatusStyle(
          label: 'Confirmed',
          color: const Color(0xFF10B981),
          icon: Icons.check_circle,
        );
      case 'PENDING':
        return StatusStyle(
          label: 'Pending',
          color: const Color(0xFFF59E0B),
          icon: Icons.schedule,
        );
      case 'CANCELLED':
        return StatusStyle(
          label: 'Cancelled',
          color: const Color(0xFFEF4444),
          icon: Icons.cancel,
        );
      // Subscription statuses
      case 'ACTIVE':
        return StatusStyle(
          label: 'Active',
          color: const Color(0xFF10B981),
          icon: Icons.check_circle,
        );
      case 'SUSPENDED':
        return StatusStyle(
          label: 'Suspended',
          color: const Color(0xFFF59E0B),
          icon: Icons.pause_circle,
        );
      case 'EXPIRED':
        return StatusStyle(
          label: 'Expired',
          color: const Color(0xFF6B7280),
          icon: Icons.timer_off,
        );
      // Seat statuses
      case 'AVAILABLE':
        return StatusStyle(
          label: 'Available',
          color: const Color(0xFF10B981),
          icon: Icons.event_seat,
        );
      case 'OCCUPIED':
        return StatusStyle(
          label: 'Occupied',
          color: const Color(0xFFEF4444),
          icon: Icons.person,
        );
      case 'RESERVED':
        return StatusStyle(
          label: 'Reserved',
          color: const Color(0xFF3B82F6),
          icon: Icons.bookmark,
        );
      case 'MAINTENANCE':
        return StatusStyle(
          label: 'Maintenance',
          color: const Color(0xFF6B7280),
          icon: Icons.build,
        );
      // Roles
      case 'ADMIN':
        return StatusStyle(
          label: 'Admin',
          color: const Color(0xFF6366F1),
          icon: Icons.admin_panel_settings,
        );
      case 'USER':
        return StatusStyle(
          label: 'User',
          color: const Color(0xFF3B82F6),
          icon: Icons.person,
        );
      default:
        return StatusStyle(
          label: status,
          color: const Color(0xFF6B7280),
        );
    }
  }
}

class StatusStyle {
  final String label;
  final Color color;
  final IconData? icon;

  StatusStyle({
    required this.label,
    required this.color,
    this.icon,
  });
}

class RoleBadge extends StatelessWidget {
  final String role;
  final bool compact;

  const RoleBadge({
    Key? key,
    required this.role,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isAdmin = role.toUpperCase() == 'ADMIN';
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: isAdmin ? const Color(0xFF6366F1) : const Color(0xFF3B82F6),
        borderRadius: BorderRadius.circular(compact ? 4 : 6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAdmin ? Icons.admin_panel_settings : Icons.person,
            size: compact ? 10 : 12,
            color: Colors.white,
          ),
          if (!compact) const SizedBox(width: 4),
          Text(
            isAdmin ? 'ADMIN' : 'USER',
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 8 : 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class PlanBadge extends StatelessWidget {
  final String plan;

  const PlanBadge({
    Key? key,
    required this.plan,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final style = _getStyle();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: style.gradientColors,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            style.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  PlanStyle _getStyle() {
    switch (plan.toUpperCase()) {
      case 'MONTHLY':
        return PlanStyle(
          label: 'Monthly',
          icon: Icons.flash_on,
          gradientColors: [Colors.blue, Colors.blue.shade700],
        );
      case 'QUARTERLY':
        return PlanStyle(
          label: 'Quarterly',
          icon: Icons.star,
          gradientColors: [const Color(0xFF10B981), const Color(0xFF059669)],
        );
      case 'SEMI_ANNUAL':
        return PlanStyle(
          label: 'Semi-Annual',
          icon: Icons.emoji_events,
          gradientColors: [Colors.purple, Colors.purple.shade700],
        );
      default:
        return PlanStyle(
          label: 'None',
          icon: Icons.block,
          gradientColors: [Colors.grey, Colors.grey.shade700],
        );
    }
  }
}

class PlanStyle {
  final String label;
  final IconData icon;
  final List<Color> gradientColors;

  PlanStyle({
    required this.label,
    required this.icon,
    required this.gradientColors,
  });
}
