import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/notifications_api.dart';

class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String message;
  final DateTime sentAt;
  final DateTime? readAt;
  final IconData icon;
  final Color color;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.sentAt,
    required this.readAt,
    required this.icon,
    required this.color,
  });

  bool get read => readAt != null;

  NotificationModel copyWith({DateTime? readAt}) {
    return NotificationModel(
      id: id,
      type: type,
      title: title,
      message: message,
      sentAt: sentAt,
      readAt: readAt ?? this.readAt,
      icon: icon,
      color: color,
    );
  }
}

class NotificationStyle {
  final String title;
  final IconData icon;
  final Color color;

  const NotificationStyle(this.title, this.icon, this.color);
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationsApi _notificationsApi = NotificationsApi();
  bool _showSettings = false;
  bool _isLoading = true;
  String? _loadError;
  List<NotificationModel> _notifications = [];
  final Map<String, bool> _settings = {
    'bookings': true,
    'payments': true,
    'reminders': true,
    'promotions': false,
  };

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  @override
  void dispose() {
    _notificationsApi.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    final token = Provider.of<AppProvider>(context, listen: false).authToken;
    if (token == null || token.isEmpty) {
      setState(() {
        _isLoading = false;
        _loadError = 'Login required to load notifications.';
      });
      return;
    }

    try {
      final raw = await _notificationsApi.fetchNotifications(token: token);
      final mapped = raw.map(_mapNotification).toList();
      if (!mounted) {
        return;
      }
      setState(() {
        _notifications = mapped;
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

  NotificationModel _mapNotification(Map<String, dynamic> data) {
    final type = data['type']?.toString() ?? 'GENERAL';
    final style = _styleForType(type);
    return NotificationModel(
      id: data['id']?.toString() ?? '',
      type: type,
      title: style.title,
      message: data['content']?.toString() ?? '',
      sentAt: _parseDate(data['sentAt']) ?? DateTime.now(),
      readAt: _parseDate(data['readAt']),
      icon: style.icon,
      color: style.color,
    );
  }

  DateTime? _parseDate(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value);
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return null;
  }

  NotificationStyle _styleForType(String type) {
    switch (type) {
      case 'CONFIRMATION_RESERVATION':
        return const NotificationStyle(
          'Reservation confirmee',
          Icons.check_circle,
          Color(0xFF10B981),
        );
      case 'REMINDER_RESERVATION':
        return const NotificationStyle(
          'Reservation Reminder',
          Icons.alarm,
          Color(0xFFF59E0B),
        );
      case 'SUBSCRIPTION_UPDATE':
        return const NotificationStyle(
          'Subscription Update',
          Icons.workspace_premium,
          Color(0xFF6366F1),
        );
      default:
        return const NotificationStyle(
          'Notification',
          Icons.notifications,
          Color(0xFF3B82F6),
        );
    }
  }

  String _formatRelative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inSeconds < 60) {
      return 'Just now';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} h ago';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays} d ago';
    }
    return '${date.month}/${date.day}/${date.year}';
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.read) {
      return;
    }

    final token = Provider.of<AppProvider>(context, listen: false).authToken;
    if (token == null || token.isEmpty) {
      _showError('Login required.');
      return;
    }

    final index =
        _notifications.indexWhere((item) => item.id == notification.id);
    if (index == -1) {
      return;
    }

    final updated = notification.copyWith(readAt: DateTime.now());
    setState(() {
      _notifications[index] = updated;
    });

    try {
      await _notificationsApi.markRead(token: token, id: notification.id);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _notifications[index] = notification;
      });
      _showError(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _markAllAsRead() async {
    final token = Provider.of<AppProvider>(context, listen: false).authToken;
    if (token == null || token.isEmpty) {
      _showError('Login required.');
      return;
    }

    setState(() {
      _notifications = _notifications
          .map(
            (notification) => notification.read
                ? notification
                : notification.copyWith(readAt: DateTime.now()),
          )
          .toList();
    });

    try {
      await _notificationsApi.markAllRead(token: token);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showError(error.toString().replaceFirst('Exception: ', ''));
      _loadNotifications();
    }
  }

  Future<void> _deleteNotification(NotificationModel notification) async {
    final token = Provider.of<AppProvider>(context, listen: false).authToken;
    if (token == null || token.isEmpty) {
      _showError('Login required.');
      return;
    }

    final index =
        _notifications.indexWhere((item) => item.id == notification.id);
    if (index == -1) {
      return;
    }
    final removed = _notifications[index];

    setState(() {
      _notifications.removeAt(index);
    });

    try {
      await _notificationsApi.deleteNotification(
        token: token,
        id: notification.id,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _notifications.insert(index, removed);
      });
      _showError(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _clearAll() async {
    final token = Provider.of<AppProvider>(context, listen: false).authToken;
    if (token == null || token.isEmpty) {
      _showError('Login required.');
      return;
    }

    setState(() {
      _notifications = [];
    });

    try {
      await _notificationsApi.deleteAll(token: token);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showError(error.toString().replaceFirst('Exception: ', ''));
      _loadNotifications();
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _loadError != null
                    ? _buildErrorState()
                    : _notifications.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _loadNotifications,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _notifications.length,
                              itemBuilder: (context, index) {
                                final notification = _notifications[index];
                                return Dismissible(
                                  key: Key(notification.id),
                                  direction: DismissDirection.endToStart,
                                  onDismissed: (_) =>
                                      _deleteNotification(notification),
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    color: Colors.red,
                                    child: const Icon(Icons.delete,
                                        color: Colors.white),
                                  ),
                                  child: Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    elevation: notification.read ? 0 : 2,
                                    color: notification.read
                                        ? Colors.white
                                        : const Color(0xFF6366F1)
                                            .withOpacity(0.05),
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
                                      onTap: () => _markAsRead(notification),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                color: notification.color
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
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
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          notification.title,
                                                          style:
                                                              const TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                      ),
                                                      if (!notification.read)
                                                        Container(
                                                          width: 8,
                                                          height: 8,
                                                          decoration:
                                                              const BoxDecoration(
                                                            color: Color(
                                                                0xFF6366F1),
                                                            shape:
                                                                BoxShape.circle,
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
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        _formatRelative(
                                                            notification
                                                                .sentAt),
                                                        style: TextStyle(
                                                          color:
                                                              Colors.grey[400],
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                      InkWell(
                                                        onTap: () =>
                                                            _deleteNotification(
                                                                notification),
                                                        child: Icon(
                                                          Icons.close,
                                                          size: 16,
                                                          color:
                                                              Colors.grey[400],
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
          ),
        ],
      ),
    );
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
              _loadError ?? 'Error loading notifications.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadNotifications,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Reessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
            'No notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadNotifications,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Refresh'),
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
                      'Parametres',
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
                          'Reservations',
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
                          'Sessions a venir et echeances',
                          'reminders',
                        ),
                        const Divider(),
                        _buildSwitchTile(
                          'Promotions',
                          'Offres speciales et reductions',
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
                          'Methodes de notification',
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
            onChanged: (value) {},
            activeColor: const Color(0xFF6366F1),
          ),
        ],
      ),
    );
  }
}

