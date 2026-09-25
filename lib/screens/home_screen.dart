import 'package:flutter/material.dart';
import 'package:pers_ver_app/screens/turnus/turnus_list_screen.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback? onNavigateToBetreuer;
  final VoidCallback? onNavigateToPodopieczni;
  final ValueChanged<int>? onNavigateToTab;

  const HomeScreen({
    super.key,
    this.onNavigateToBetreuer,
    this.onNavigateToPodopieczni,
    this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Panel Główny'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Karta powitalna
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Witaj w CareManager 👋',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Zarządzaj zleceniami, profilem opiekunek i podopiecznymi w jednym miejscu.',
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Sekcja statystyk
          const Text(
            'Przegląd bazy',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.people,
                  color: Colors.blueAccent,
                  title: 'Opiekunki',
                  subtitle: 'Baza profili',
                  onTap: onNavigateToBetreuer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.personal_injury_outlined,
                  color: Colors.orangeAccent,
                  title: 'Podopieczni',
                  subtitle: 'Aktywne zlecenia',
                  onTap: onNavigateToPodopieczni,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Szybkie akcje
          const Text(
            'Szybkie akcje',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildActionTile(
            icon: Icons.person_add_alt_1,
            color: Colors.blue,
            title: 'Lista opiekunek',
            subtitle: 'Wyszukaj, filtruj lub dodaj nową opiekunkę',
            onTap: onNavigateToBetreuer,
          ),
          const SizedBox(height: 10),
          _buildActionTile(
            icon: Icons.commute,
            color: Colors.teal,
            title: 'Baza zleceń i dojazdów',
            subtitle: 'Przejdź do rejestru podopiecznych i tras',
            onTap: () async {
              await Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (context) => const TurnusListScreen(),
            ),
          );
        },
      ),
    ])
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ),
    );
  }
}