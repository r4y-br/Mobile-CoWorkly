import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/subscriptions_api.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  final SubscriptionsApi _subscriptionsApi = SubscriptionsApi();
  List<dynamic> _mySubscriptions = [];
  bool _isLoading = false;
  String? _loadError;
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _plans = [
    {
      'id': 'MONTHLY',
      'name': 'Mensuel',
      'price': 99,
      'duration': '1 mois',
      'features': ['Accès illimité', 'WiFi haute vitesse', 'Café gratuit'],
    },
    {
      'id': 'QUARTERLY',
      'name': 'Trimestriel',
      'price': 269,
      'duration': '3 mois',
      'features': [
        'Accès illimité',
        'WiFi haute vitesse',
        'Café gratuit',
        'Salle de réunion 2h/mois'
      ],
      'popular': true,
    },
    {
      'id': 'SEMI_ANNUAL',
      'name': 'Semestriel',
      'price': 499,
      'duration': '6 mois',
      'features': [
        'Accès illimité',
        'WiFi haute vitesse',
        'Café gratuit',
        'Salle de réunion 5h/mois',
        'Casier personnel'
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadMySubscriptions();
  }

  @override
  void dispose() {
    _subscriptionsApi.dispose();
    super.dispose();
  }

  Future<void> _loadMySubscriptions() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final token = Provider.of<AppProvider>(context, listen: false).authToken;
      if (token == null || token.isEmpty) {
        setState(() {
          _loadError = 'Connexion requise.';
          _isLoading = false;
        });
        return;
      }
      final response =
          await _subscriptionsApi.fetchMySubscriptions(token: token);
      setState(() {
        _mySubscriptions = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _loadError = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _requestSubscription(String plan) async {
    final token = Provider.of<AppProvider>(context, listen: false).authToken;
    if (token == null || token.isEmpty) {
      _showMessage('Connexion requise.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _subscriptionsApi.createSubscription(token: token, plan: plan);
      _showMessage('Demande d\'abonnement envoyée avec succès!');
      _loadMySubscriptions();
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _cancelSubscription(int id) async {
    final token = Provider.of<AppProvider>(context, listen: false).authToken;
    if (token == null || token.isEmpty) {
      _showMessage('Connexion requise.', isError: true);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler l\'abonnement'),
        content: const Text('Voulez-vous vraiment annuler cet abonnement?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _subscriptionsApi.cancelSubscription(token: token, id: id);
      _showMessage('Abonnement annulé.');
      _loadMySubscriptions();
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF10B981),
      ),
    );
  }

  void _showSubscribePlansDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Choisir un abonnement',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sélectionnez le forfait qui vous convient',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _plans.length,
                itemBuilder: (ctx, index) {
                  final plan = _plans[index];
                  final isPopular = plan['popular'] == true;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isPopular
                            ? const Color(0xFF6366F1)
                            : Colors.grey.shade200,
                        width: isPopular ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        if (isPopular)
                          Positioned(
                            top: 0,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: const BoxDecoration(
                                color: Color(0xFF6366F1),
                                borderRadius: BorderRadius.vertical(
                                    bottom: Radius.circular(8)),
                              ),
                              child: const Text(
                                'Populaire',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        plan['name'],
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        plan['duration'],
                                        style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${plan['price']}€',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF6366F1),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ...(plan['features'] as List<String>)
                                  .map((feature) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.check_circle,
                                                color: Color(0xFF10B981),
                                                size: 18),
                                            const SizedBox(width: 8),
                                            Text(feature,
                                                style: TextStyle(
                                                    color: Colors.grey[700],
                                                    fontSize: 13)),
                                          ],
                                        ),
                                      )),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isSubmitting
                                      ? null
                                      : () {
                                          Navigator.pop(ctx);
                                          _requestSubscription(plan['id']);
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isPopular
                                        ? const Color(0xFF6366F1)
                                        : Colors.grey[100],
                                    foregroundColor: isPopular
                                        ? Colors.white
                                        : Colors.black87,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Souscrire'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSubscribePlansDialog,
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nouvel abonnement',
            style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadMySubscriptions,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 220,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(48),
                      bottomRight: Radius.circular(48),
                    ),
                  ),
                ),
                Positioned(
                  top: 60,
                  left: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Mes Abonnements',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Gérez vos abonnements actifs',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_loadError != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              _loadError!,
                              style: TextStyle(
                                color: Colors.red[600],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadMySubscriptions,
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_mySubscriptions.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.workspace_premium,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun abonnement',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Vous n\'avez pas d\'abonnement actif',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _showSubscribePlansDialog,
                              icon: const Icon(Icons.workspace_premium),
                              label: const Text('Découvrir les forfaits'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Column(
                      children: _mySubscriptions.map((sub) {
                        final id = sub['id'] as int?;
                        final plan = (sub['plan'] as String?) ?? 'MONTHLY';
                        final status = (sub['status'] as String?) ?? 'PENDING';
                        final start = sub['startDate']?.toString();
                        final end = sub['endDate']?.toString();
                        final startDt =
                            start != null ? DateTime.tryParse(start) : null;
                        final endDt =
                            end != null ? DateTime.tryParse(end) : null;

                        Color statusColor;
                        String statusLabel;
                        switch (status) {
                          case 'ACTIVE':
                            statusColor = const Color(0xFF10B981);
                            statusLabel = 'Actif';
                            break;
                          case 'SUSPENDED':
                            statusColor = const Color(0xFFF59E0B);
                            statusLabel = 'Suspendu';
                            break;
                          case 'CANCELLED':
                            statusColor = Colors.red;
                            statusLabel = 'Annulé';
                            break;
                          case 'EXPIRED':
                            statusColor = Colors.grey;
                            statusLabel = 'Expiré';
                            break;
                          case 'PENDING':
                          default:
                            statusColor = const Color(0xFF6366F1);
                            statusLabel = 'En attente';
                        }

                        String planLabel;
                        switch (plan) {
                          case 'QUARTERLY':
                            planLabel = 'Trimestriel';
                            break;
                          case 'SEMI_ANNUAL':
                            planLabel = 'Semestriel';
                            break;
                          case 'MONTHLY':
                          default:
                            planLabel = 'Mensuel';
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.workspace_premium,
                                      color: statusColor,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              planLabel,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: statusColor
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: statusColor,
                                                ),
                                              ),
                                              child: Text(
                                                statusLabel,
                                                style: TextStyle(
                                                  color: statusColor,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.calendar_today,
                                              size: 14,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                startDt != null && endDt != null
                                                    ? 'Du ${startDt.day}/${startDt.month}/${startDt.year} au ${endDt.day}/${endDt.month}/${endDt.year}'
                                                    : 'En attente d\'approbation',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (status == 'ACTIVE' ||
                                  status == 'PENDING') ...[
                                const SizedBox(height: 12),
                                const Divider(),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: id != null
                                        ? () => _cancelSubscription(id)
                                        : null,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text('Annuler l\'abonnement'),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
