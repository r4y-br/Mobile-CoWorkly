import 'package:flutter/material.dart';

class SpaceSelectionScreen extends StatefulWidget {
  const SpaceSelectionScreen({Key? key}) : super(key: key);

  @override
  State<SpaceSelectionScreen> createState() => _SpaceSelectionScreenState();
}

class _SpaceSelectionScreenState extends State<SpaceSelectionScreen> {
  String? selectedSpaceId;

  final List<Map<String, dynamic>> spaces = [
    {
      'id': 'creative-hub',
      'name': 'Creative Hub',
      'tagline': 'Pour les créatifs et les designers',
      'description':
          'Un espace lumineux et inspirant avec des équipements professionnels pour les créatifs.',
      'image':
          'https://images.unsplash.com/photo-1497366216548-37526070297c?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=1080',
      'totalSeats': 24,
      'availableSeats': 8,
      'color': Colors.indigo,
      'gradient': [Colors.indigo, Colors.purple],
      'icon': Icons.auto_awesome,
      'features': [
        'Design Studio',
        'Tablettes graphiques',
        'Éclairage naturel',
        'Zone calme'
      ],
      'amenities': [
        {'icon': Icons.wifi, 'label': 'WiFi Pro'},
        {'icon': Icons.coffee, 'label': 'Café premium'},
        {'icon': Icons.monitor, 'label': 'Écrans 4K'},
      ],
    },
    {
      'id': 'tech-space',
      'name': 'Tech Space',
      'tagline': 'Pour les développeurs et les startups',
      'description':
          'Un environnement high-tech optimisé pour la productivité et les équipes agiles.',
      'image':
          'https://images.unsplash.com/photo-1497366811353-6870744d04b2?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=1080',
      'totalSeats': 32,
      'availableSeats': 14,
      'color': Colors.blue,
      'gradient': [Colors.blue, Colors.cyan],
      'icon': Icons.flash_on,
      'features': [
        'Postes gaming',
        'Salles de réunion',
        'Tableaux blancs',
        'Station café'
      ],
      'amenities': [
        {'icon': Icons.wifi, 'label': 'Fibre optique'},
        {'icon': Icons.coffee, 'label': 'Boissons illimitées'},
        {'icon': Icons.group, 'label': 'Espaces collab'},
      ],
    },
    {
      'id': 'work-lounge',
      'name': 'Work & Lounge',
      'tagline': 'Pour le confort et la flexibilité',
      'description':
          'Un espace polyvalent qui allie confort et professionnalisme pour tous types de missions.',
      'image':
          'https://images.unsplash.com/photo-1497366754035-f200968a6e72?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=1080',
      'totalSeats': 24,
      'availableSeats': 10,
      'color': Colors.teal,
      'gradient': [Colors.teal, Colors.green],
      'icon': Icons.chair,
      'features': [
        'Fauteuils ergonomiques',
        'Zone détente',
        'Espace verdure',
        'Cuisine équipée'
      ],
      'amenities': [
        {'icon': Icons.wifi, 'label': 'WiFi rapide'},
        {'icon': Icons.coffee, 'label': 'Espace café'},
        {'icon': Icons.chair, 'label': 'Confort premium'},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Choisissez votre espace',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sélectionnez l\'espace adapté à vos besoins',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Spaces List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: spaces.length,
              itemBuilder: (context, index) {
                final space = spaces[index];
                final occupancyRate =
                    ((space['totalSeats'] - space['availableSeats']) /
                            space['totalSeats'] *
                            100)
                        .round();
                final isLowOccupancy = occupancyRate < 50;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedSpaceId = space['id'] as String;
                    });
                    Future.delayed(const Duration(milliseconds: 200), () {
                      Navigator.pop(context, space['id']);
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image Header
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(24)),
                              child: Image.network(
                                space['image'] as String,
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 160,
                                    color: Colors.grey[300],
                                    child: const Center(
                                        child: Icon(Icons.image_not_supported)),
                                  );
                                },
                              ),
                            ),
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(24)),
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: (space['gradient'] as List<Color>)
                                        .map((c) => c.withOpacity(0.6))
                                        .toList(),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 16,
                              right: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: isLowOccupancy
                                            ? const Color(0xFF10B981)
                                            : Colors.orange,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${space['availableSeats']} places libres',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 16,
                              left: 16,
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  space['icon'] as IconData,
                                  color: space['color'] as Color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Content
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          space['name'] as String,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          space['tagline'] as String,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right,
                                      color: Colors.grey),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                space['description'] as String,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Progress Bar
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Occupation',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '$occupancyRate%',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: occupancyRate / 100,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      space['color'] as Color),
                                  minHeight: 8,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Features
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: (space['features'] as List<String>)
                                    .map((feature) => Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            feature,
                                            style: TextStyle(
                                              color: Colors.grey[800],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 16),
                              // Amenities
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: (space['amenities']
                                        as List<Map<String, dynamic>>)
                                    .map((amenity) => Row(
                                          children: [
                                            Icon(
                                              amenity['icon'] as IconData,
                                              size: 16,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              amenity['label'] as String,
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ))
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
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
}
