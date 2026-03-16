// screens/statistics_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/medicine.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({Key? key}) : super(key: key);

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final user = FirebaseAuth.instance.currentUser!;
  int totalMedicines = 0;
  int activeMedicines = 0;
  int expiringSoon = 0;
  int lowStock = 0;
  int totalDosesTaken = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  void _loadStatistics() async {
    final medicinesSnapshot = await FirebaseDatabase.instance
        .ref('medicines/${user.uid}')
        .get();

    final historySnapshot = await FirebaseDatabase.instance
        .ref('dose_history/${user.uid}')
        .get();

    if (medicinesSnapshot.value != null) {
      final data = Map<String, dynamic>.from(medicinesSnapshot.value as Map);
      final medicines = data.entries
          .map((e) => Medicine.fromMap(e.key, e.value))
          .toList();

      totalMedicines = medicines.length;
      activeMedicines = medicines.where((m) => m.remainingDoses > 0).length;
      expiringSoon = medicines.where((m) {
        if (m.expiryDate == null) return false;
        final days = m.expiryDate!.difference(DateTime.now()).inDays;
        return days > 0 && days < 30;
      }).length;
      lowStock = medicines.where((m) => m.remainingDoses < 5 && m.remainingDoses > 0).length;
    }

    if (historySnapshot.value != null) {
      final data = Map<String, dynamic>.from(historySnapshot.value as Map);
      totalDosesTaken = data.length;
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildStatCard(
                  'Total des médicaments',
                  totalMedicines.toString(),
                  Icons.medication,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Médicaments actifs',
                  activeMedicines.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildStatCard(
                  'Expire bientôt',
                  expiringSoon.toString(),
                  Icons.warning,
                  Colors.orange,
                ),
                _buildStatCard(
                  'Stock faible',
                  lowStock.toString(),
                  Icons.inventory,
                  Colors.red,
                ),
                _buildStatCard(
                  'Doses consommées',
                  totalDosesTaken.toString(),
                  Icons.history,
                  Colors.purple,
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}