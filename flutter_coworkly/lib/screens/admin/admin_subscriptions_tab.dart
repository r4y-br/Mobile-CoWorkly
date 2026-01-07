import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../services/subscription_api.dart';
import '../../services/users_api.dart';
import '../../widgets/index.dart';

class AdminSubscriptionsTab extends StatefulWidget {
  const AdminSubscriptionsTab({Key? key}) : super(key: key);

  @override
  State<AdminSubscriptionsTab> createState() => _AdminSubscriptionsTabState();
}

class _AdminSubscriptionsTabState extends State<AdminSubscriptionsTab> {
  List<Map<String, dynamic>> _subscriptions = [];
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _error;
  String _filterStatus = 'ALL';
  final UsersApi _usersApi = UsersApi();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final token = Provider.of<AppProvider>(context, listen: false).authToken;
    if (token == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        SubscriptionApi.getAllSubscriptions(token),
        _usersApi.fetchAllUsers(token: token),
      ]);
      setState(() {
        _subscriptions = results[0] as List<Map<String, dynamic>>;
        _users = results[1] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
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
      return const Scaffold(body: LoadingState(message: 'Loading subscriptions...'));
    }

    if (_error != null) {
      return Scaffold(body: ErrorState(
        message: _error!,
        onRetry: _loadData,
      ));
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateSubscriptionDialog,
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Future<void> _showCreateSubscriptionDialog() async {
    int? selectedUserId;
    String selectedPlan = 'MONTHLY';
    bool autoApprove = true;

    // Filter out users who already have active/pending subscriptions
    final usersWithSubs = _subscriptions
        .where((s) => s['status'] == 'ACTIVE' || s['status'] == 'PENDING')
        .map((s) => s['userId'] ?? s['user']?['id'])
        .toSet();
    final availableUsers = _users.where((u) => !usersWithSubs.contains(u['id'])).toList();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Subscription'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Select User'),
                  value: selectedUserId,
                  items: availableUsers.map((u) => DropdownMenuItem<int>(
                    value: u['id'] as int,
                    child: Text('${u['name']} (${u['email']})'),
                  )).toList(),
                  onChanged: (val) => setDialogState(() => selectedUserId = val),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Plan'),
                  value: selectedPlan,
                  items: const [
                    DropdownMenuItem(value: 'MONTHLY', child: Text('Monthly (40h)')),
                    DropdownMenuItem(value: 'QUARTERLY', child: Text('Quarterly (120h)')),
                    DropdownMenuItem(value: 'SEMI_ANNUAL', child: Text('Semi-Annual (250h)')),
                  ],
                  onChanged: (val) => setDialogState(() => selectedPlan = val ?? 'MONTHLY'),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Auto-approve'),
                  subtitle: const Text('Activate immediately'),
                  value: autoApprove,
                  onChanged: (val) => setDialogState(() => autoApprove = val ?? true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedUserId == null ? null : () async {
                Navigator.pop(context);
                await _createSubscription(selectedUserId!, selectedPlan, autoApprove);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
              child: const Text('Create', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createSubscription(int userId, String plan, bool autoApprove) async {
    final token = Provider.of<AppProvider>(context, listen: false).authToken;
    if (token == null) return;

    try {
      await SubscriptionApi.createSubscriptionForUser(token, userId, plan, autoApprove: autoApprove);
      _showSuccess('Subscription created!');
      _loadData();
    } catch (e) {
      _showError('Error: $e');
    }
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
