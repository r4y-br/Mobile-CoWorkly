import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class BottomNav extends StatelessWidget {
  const BottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final activeTab = appProvider.activeTab;
    final isAdmin = appProvider.isAdmin;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: isAdmin
                ? _buildAdminNavItems(context, appProvider, activeTab)
                : _buildUserNavItems(context, appProvider, activeTab),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildUserNavItems(
      BuildContext context, AppProvider appProvider, String activeTab) {
    return [
      _buildNavItem(
        context,
        id: 'home',
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'Accueil',
        isActive: activeTab == 'home',
        onTap: () => appProvider.setActiveTab('home'),
      ),
      _buildNavItem(
        context,
        id: 'bookings',
        icon: Icons.calendar_today_outlined,
        activeIcon: Icons.calendar_today,
        label: 'Réservations',
        isActive: activeTab == 'bookings',
        onTap: () => appProvider.setActiveTab('bookings'),
      ),
      _buildNavItem(
        context,
        id: 'subscriptions',
        icon: Icons.workspace_premium_outlined,
        activeIcon: Icons.workspace_premium,
        label: 'Abonnements',
        isActive: activeTab == 'subscriptions',
        onTap: () => appProvider.setActiveTab('subscriptions'),
      ),
      _buildNavItem(
        context,
        id: 'notifications',
        icon: Icons.notifications_outlined,
        activeIcon: Icons.notifications,
        label: 'Notifications',
        isActive: activeTab == 'notifications',
        onTap: () => appProvider.setActiveTab('notifications'),
      ),
      _buildNavItem(
        context,
        id: 'profile',
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Profil',
        isActive: activeTab == 'profile',
        onTap: () => appProvider.setActiveTab('profile'),
      ),
    ];
  }

  List<Widget> _buildAdminNavItems(
      BuildContext context, AppProvider appProvider, String activeTab) {
    return [
      _buildNavItem(
        context,
        id: 'home',
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard,
        label: 'Dashboard',
        isActive: activeTab == 'home',
        onTap: () => appProvider.setActiveTab('home'),
      ),
      _buildNavItem(
        context,
        id: 'bookings',
        icon: Icons.calendar_today_outlined,
        activeIcon: Icons.calendar_today,
        label: 'Réservations',
        isActive: activeTab == 'bookings',
        onTap: () => appProvider.setActiveTab('bookings'),
      ),
      _buildNavItem(
        context,
        id: 'notifications',
        icon: Icons.notifications_outlined,
        activeIcon: Icons.notifications,
        label: 'Notifications',
        isActive: activeTab == 'notifications',
        onTap: () => appProvider.setActiveTab('notifications'),
      ),
      _buildNavItem(
        context,
        id: 'profile',
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Profil',
        isActive: activeTab == 'profile',
        onTap: () => appProvider.setActiveTab('profile'),
      ),
    ];
  }

  Widget _buildNavItem(
    BuildContext context, {
    required String id,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final color = isActive ? theme.primaryColor : theme.disabledColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: isActive
            ? BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
