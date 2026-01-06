import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/subscription_provider.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  @override
  void initState() {
    super.initState();
    // On charge les données dès le début
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AppProvider>().authToken;
      if (token != null) {
        context.read<SubscriptionProvider>().fetchSubscription(token);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // On écoute les deux providers
    final subProvider = context.watch<SubscriptionProvider>();
    final appProvider = context.watch<AppProvider>();

    final sub = subProvider.subscription;
    final token = appProvider.authToken ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title:
            const Text("Mon Abonnement", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: subProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => subProvider.fetchSubscription(token),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildStatusCard(sub),
                  const SizedBox(height: 30),
                  const Text("Plans disponibles",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  _buildPlanTile(context, "Pass Mensuel", "MONTHLY", "40h",
                      "49€", sub, token),
                  _buildPlanTile(context, "Business", "QUARTERLY", "120h",
                      "129€", sub, token),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard(Map<String, dynamic>? sub) {
    // Utilisation sécurisée des données de la Map (JSON)
    final String planLabel = sub?['plan'] ?? "Aucun Plan";
    final int used = sub?['usedHours'] ?? 0;
    final int total = sub?['totalHours'] ?? 0;
    final double progress = total > 0 ? (used / total).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF4F46E5)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 20)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(planLabel,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white24,
            color: Colors.white,
            minHeight: 8,
          ),
          const SizedBox(height: 15),
          // Localise la ligne 100 dans ton fichier
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                // <--- Ajoute ceci
                child: Text(
                  "$used h utilisées",
                  style: const TextStyle(color: Colors.white70),
                  overflow: TextOverflow
                      .ellipsis, // Évite que le texte ne pousse les bords
                ),
              ),
              const SizedBox(width: 10), // Un petit espace entre les deux
              Expanded(
                // <--- Ajoute ceci aussi
                child: Text(
                  "$total h total",
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPlanTile(BuildContext context, String name, String code,
      String hours, String price, Map<String, dynamic>? current, String token) {
    bool isCurrent = current?['plan'] == code;

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("$hours de coworking"),
        trailing: isCurrent
            ? const Icon(Icons.check_circle, color: Colors.green, size: 30)
            : ElevatedButton(
                onPressed: () => context
                    .read<SubscriptionProvider>()
                    .requestNewSubscription(token, code),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                child: Text(price, style: const TextStyle(color: Colors.white)),
              ),
      ),
    );
  }
}
