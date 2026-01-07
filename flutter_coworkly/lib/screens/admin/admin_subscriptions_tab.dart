import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../services/subscription_api.dart';
import '../../widgets/index.dart';

class AdminSubscriptionsTab extends StatefulWidget {
  const AdminSubscriptionsTab({Key? key}) : super(key: key);

  @override
  State<AdminSubscriptionsTab> createState() => _AdminSubscriptionsTabState();
}

class _AdminSubscriptionsTabState extends State<AdminSubscriptionsTab> {
  List<Map<String, dynamic>> _subscriptions = [];
  bool _isLoading = true;
  String? _error;
  String _filterStatus = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    final token = Provider.of<AppProvider>(context, listen: false).authToken;
    if (token == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final subs = await SubscriptionApi.getAllSubscriptions(token);
      setState(() {
        _subscriptions = subs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredSubscriptions {
    if (_filterStatus == 'ALL') return _subscriptions;
    return _subscriptions.where((s) => s['status'] == _filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingState(message: 'Loading subscriptions...');
    }

    if (_error != null) {
      return ErrorState(
        message: _error!,
        onRetry: _loadSubscriptions,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSubscriptions,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Stats summary
          _buildStatsSummary(),
          const SizedBox(height: 20),
          
          // Filter chips
          _buildFilterChips(),
          const SizedBox(height: 16),
          
          // Subscriptions list
          if (_filteredSubscriptions.isEmpty)
            const EmptyState(
              title: 'No subscriptions',
              message: 'No subscriptions match the criteria',
              icon: Icons.card_membership,
            )
          else
            ..._filteredSubscriptions.map((sub) => _buildSubscriptionCard(sub)),
        ],
      ),
    );
  }

  Widget _buildStatsSummary() {
    final pending = _subscriptions.where((s) => s['status'] == 'PENDING').length;
    final active = _subscriptions.where((s) => s['status'] == 'ACTIVE').length;
    final suspended = _subscriptions.where((s) => s['status'] == 'SUSPENDED').length;

    return Row(
      children: [
        Expanded(
          child: _buildMiniStat('Pending', '$pending', Colors.orange),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMiniStat('Active', '$active', const Color(0xFF10B981)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMiniStat('Suspended', '$suspended', Colors.red),
        ),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'id': 'ALL', 'label': 'All'},
      {'id': 'PENDING', 'label': 'Pending'},
      {'id': 'ACTIVE', 'label': 'Active'},
      {'id': 'SUSPENDED', 'label': 'Suspended'},
      {'id': 'CANCELLED', 'label': 'Cancelled'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _filterStatus == f['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(f['label']!),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _filterStatus = f['id']!;
                });
              },
              selectedColor: const Color(0xFF6366F1).withOpacity(0.2),
              checkmarkColor: const Color(0xFF6366F1),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF6366F1) : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSubscriptionCard(Map<String, dynamic> sub) {
    final user = sub['user'] as Map<String, dynamic>?;
    final userName = user?['name'] ?? 'User';
    final userEmail = user?['email'] ?? '';
    final plan = sub['plan'] ?? 'MONTHLY';
    final status = sub['status'] ?? 'PENDING';
    final id = sub['id'] as int;
    final startDate = sub['startDate'];
    final endDate = sub['endDate'];

    final initials = userName
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: status == 'PENDING' 
            ? Border.all(color: Colors.orange, width: 2) 
            : null,
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
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Color(0xFF6366F1),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 8),
                        PlanBadge(plan: plan),
                      ],
                    ),
                    Text(
                      userEmail,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    if (startDate != null)
                      Text(
                        'Start: ${_formatDate(startDate)}',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (status == 'PENDING')
                _buildActionButton(
                  'Approve',
                  Icons.check,
                  const Color(0xFF10B981),
                  () => _approveSubscription(id),
                ),
              if (status == 'ACTIVE')
                _buildActionButton(
                  'Suspend',
                  Icons.pause,
                  Colors.orange,
                  () => _suspendSubscription(id),
                ),
              if (status == 'SUSPENDED' || status == 'PENDING')
                _buildActionButton(
                  'Delete',
                  Icons.delete,
                  Colors.red,
                  () => _deleteSubscription(id),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: color),
      label: Text(
        label,
        style: TextStyle(color: color, fontSize: 13),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return '-';
    try {
      final date = DateTime.parse(isoString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return isoString;
    }
  }

  Future<void> _approveSubscription(int id) async {
    final confirm = await ConfirmDialog.show(
      context: context,
      title: 'Approve subscription',
      message: 'Do you want to approve this subscription?',
      confirmText: 'Approve',
      icon: Icons.check_circle,
    );

    if (confirm != true) return;

    final token = Provider.of<AppProvider>(context, listen: false).authToken;
    if (token == null) return;

    try {
      await SubscriptionApi.approveSubscription(token, id);
      _showSuccess('Subscription approved!');
      _loadSubscriptions();
    } catch (e) {
      _showError('Error: $e');
    }
  }

  Future<void> _suspendSubscription(int id) async {
    final confirm = await ConfirmDialog.show(
      context: context,
      title: 'Suspend subscription',
      message: 'Do you want to suspend this subscription?',
      confirmText: 'Suspend',
      confirmColor: Colors.orange,
      icon: Icons.pause_circle,
    );

    if (confirm != true) return;

    final token = Provider.of<AppProvider>(context, listen: false).authToken;
    if (token == null) return;

    try {
      await SubscriptionApi.suspendSubscription(token, id);
      _showSuccess('Subscription suspended');
      _loadSubscriptions();
    } catch (e) {
      _showError('Error: $e');
    }
  }

  Future<void> _deleteSubscription(int id) async {
    final confirm = await ConfirmDialog.show(
      context: context,
      title: 'Delete subscription',
      message: 'This action is irreversible. Continue?',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (confirm != true) return;

    final token = Provider.of<AppProvider>(context, listen: false).authToken;
    if (token == null) return;

    try {
      await SubscriptionApi.deleteSubscription(token, id);
      _showSuccess('Subscription deleted');
      _loadSubscriptions();
    } catch (e) {
      _showError('Error: $e');
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
