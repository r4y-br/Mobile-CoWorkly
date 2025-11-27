import 'package:flutter/material.dart';

class NotificationModel {
  final String id;
  final String type; // 'booking', 'payment', 'reminder', 'promotion'
  final String title;
  final String message;
  final String time;
  bool read;
  final IconData icon;
  final Color color;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.time,
    required this.read,
    required this.icon,
    required this.color,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _showSettings = false;
  final Map<String, bool> _settings = {
    'bookings': true,
    'payments': true,
    'reminders': true,
    'promotions': false,
  };

  List<NotificationModel> _notifications = [
    NotificationModel(
      id: '1',
      type: 'booking',
      title: 'Réservation confirmée',
      message:
          'Votre réservation au Creative Hub Paris est confirmée pour le 20 nov.',
      time: "Il y a 5 min",
      read: false,
      icon: Icons.check_circle,
      color: const Color(0xFF10B981),
    ),
    NotificationModel(
      id: '2',
      type: 'reminder',
      title: 'Rappel de réservation',
      message: 'Votre session commence dans 1 heure à Tech Space Marais',
      time: "Il y a 30 min",
      read: false,
      icon: Icons.access_time,
      color: const Color(0xFFF59E0B),
    ),
    NotificationModel(
      id: '3',
      type: 'payment',
      title: 'Paiement effectué',
      message: 'Votre paiement de 149€ pour l\'abonnement Pro a été traité',
      time: "Il y a 2h",
      read: true,
      icon: Icons.credit_card,
      color: const Color(0xFF3B82F6),
    ),
    NotificationModel(
      id: '4',
      type: 'promotion',
      title: 'Offre spéciale',
      message: '🎉 -20% sur tous les espaces premium ce week-end !',
      time: "Il y a 4h",
      read: true,
      icon: Icons.local_offer,
      color: const Color(0xFFEF4444),
    ),
    NotificationModel(
      id: '5',
      type: 'booking',
      title: 'Réservation modifiée',
      message: 'Votre réservation du 18 nov. a été déplacée au 19 nov.',
      time: 'Hier',
      read: true,
      icon: Icons.calendar_today,
      color: const Color(0xFF10B981),
    ),
  ];

  void _markAsRead(String id) {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index].read = true;
      }
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var n in _notifications) {
        n.read = true;
      }
    });
  }

  void _deleteNotification(String id) {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
  }

  void _clearAll() {
    setState(() {
      _notifications.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSettings) {
      return _buildSettingsView();
    }

    final unreadCount = _notifications.where((n) => !n.read).length;

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding:
                const EdgeInsets.only(top: 48, left: 16, right: 16, bottom: 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Notifications',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (unreadCount > 0)
                          Text(
                            '$unreadCount non lue${unreadCount > 1 ? 's' : ''}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white),
                      onPressed: () => setState(() => _showSettings = true),
                    ),
                  ],
                ),
                if (_notifications.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (unreadCount > 0)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: OutlinedButton(
                            onPressed: _markAllAsRead,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                  color: Colors.white.withOpacity(0.3)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text('Tout marquer'),
                          ),
                        ),
                      OutlinedButton(
                        onPressed: _clearAll,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side:
                              BorderSide(color: Colors.white.withOpacity(0.3)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('Effacer'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // List
          Expanded(
            child: _notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.notifications_off_outlined,
                            size: 40,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Aucune notification',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Vous êtes à jour !',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return Dismissible(
                        key: Key(notification.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) =>
                            _deleteNotification(notification.id),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: notification.read ? 0 : 2,
                          color: notification.read
                              ? Colors.white
                              : const Color(0xFF6366F1).withOpacity(0.05),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: notification.read
                                ? BorderSide.none
                                : BorderSide(
                                    color: const Color(0xFF6366F1)
                                        .withOpacity(0.3),
                                  ),
                          ),
                          child: InkWell(
                            onTap: () => _markAsRead(notification.id),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color:
                                          notification.color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      notification.icon,
                                      color: notification.color,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                notification.title,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            if (!notification.read)
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFF6366F1),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          notification.message,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              notification.time,
                                              style: TextStyle(
                                                color: Colors.grey[400],
                                                fontSize: 12,
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () => _deleteNotification(
                                                  notification.id),
                                              child: Icon(
                                                Icons.close,
                                                size: 16,
                                                color: Colors.grey[400],
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

  Widget _buildSettingsView() {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.only(top: 48, left: 16, right: 16, bottom: 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => setState(() => _showSettings = false),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paramètres',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Notifications',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Types de notifications',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSwitchTile(
                          'Réservations',
                          'Confirmations et modifications',
                          'bookings',
                        ),
                        const Divider(),
                        _buildSwitchTile(
                          'Paiements',
                          'Transactions et factures',
                          'payments',
                        ),
                        const Divider(),
                        _buildSwitchTile(
                          'Rappels',
                          'Sessions à venir et échéances',
                          'reminders',
                        ),
                        const Divider(),
                        _buildSwitchTile(
                          'Promotions',
                          'Offres spéciales et réductions',
                          'promotions',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Méthodes de notification',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSimpleSwitch('Notifications push', true),
                        const Divider(),
                        _buildSimpleSwitch('Email', true),
                        const Divider(),
                        _buildSimpleSwitch('SMS', false),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, String key) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _settings[key] ?? false,
            onChanged: (value) => setState(() => _settings[key] = value),
            activeColor: const Color(0xFF6366F1),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleSwitch(String title, bool initialValue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          Switch(
            value: initialValue,
            onChanged: (value) {}, // Mock functionality
            activeColor: const Color(0xFF6366F1),
          ),
        ],
      ),
    );
  }
}
