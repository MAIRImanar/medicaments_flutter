// screens/medicines_list_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import '../models/medicine.dart';
import 'add_medicine_page.dart';
import 'medicine_detail_page.dart';

class MedicinesListPage extends StatefulWidget {
  const MedicinesListPage({Key? key}) : super(key: key);

  @override
  State<MedicinesListPage> createState() => _MedicinesListPageState();
}

class _MedicinesListPageState extends State<MedicinesListPage> {
  final user = FirebaseAuth.instance.currentUser!;
  List<Medicine> medicines = [];
  bool isLoading = true;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _loadMedicines() {
    _subscription = FirebaseDatabase.instance
        .ref('medicines/${user.uid}')
        .onValue
        .listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        if (mounted) {
          setState(() {
            medicines = data.entries
                .map((e) => Medicine.fromMap(e.key, e.value))
                .toList();
            medicines.sort((a, b) => a.name.compareTo(b.name));
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            medicines = [];
            isLoading = false;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Médicaments', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : medicines.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.medication_outlined,
                          size: 100, color: Colors.grey[300]),
                      const SizedBox(height: 20),
                      Text(
                        'Aucun médicament ajouté',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Appuyez sur le bouton + en bas pour ajouter',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: medicines.length,
                  itemBuilder: (context, index) {
                    final med = medicines[index];
                    return _buildMedicineCard(med);
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMedicineDialog,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
        backgroundColor: Colors.teal,
      ),
    );
  }

  Widget _buildMedicineCard(Medicine med) {
    final daysUntilExpiry = med.expiryDate?.difference(DateTime.now()).inDays;
    final isExpiringSoon = daysUntilExpiry != null && daysUntilExpiry < 30;
    final isLowStock = med.remainingDoses < 5;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showMedicineDetails(med),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.medication, color: Colors.teal, size: 30),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          med.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          med.dosage,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check_circle),
                    color: Colors.green,
                    onPressed: () => _takeDose(med),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildChip(med.frequency, Icons.schedule, Colors.blue),
                  _buildChip('${med.remainingDoses} doses restantes',
                      Icons.inventory, isLowStock ? Colors.red : Colors.green),
                  if (isExpiringSoon)
                    _buildChip('Expire dans $daysUntilExpiry jours',
                        Icons.warning, Colors.orange),
                ],
              ),
              if (med.times.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Horaires: ${med.times.join(" - ")}',
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, IconData icon, Color color) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide.none,
    );
  }

  void _takeDose(Medicine med) async {
    if (med.remainingDoses > 0) {
      await FirebaseDatabase.instance
          .ref('medicines/${user.uid}/${med.id}')
          .update({'remainingDoses': med.remainingDoses - 1});

      await FirebaseDatabase.instance
          .ref('dose_history/${user.uid}')
          .push()
          .set({
        'medicineId': med.id,
        'medicineName': med.name,
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dose enregistrée ✓'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showAddMedicineDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddMedicinePage()),
    );
  }

  void _showMedicineDetails(Medicine med) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MedicineDetailPage(medicine: med),
      ),
    );
  }
}