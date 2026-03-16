// screens/medicine_detail_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import '../models/medicine.dart';

class MedicineDetailPage extends StatelessWidget {
  final Medicine medicine;
  const MedicineDetailPage({Key? key, required this.medicine}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(medicine.name, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteMedicine(context, user.uid),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informations du médicament',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  _buildDetailRow('Dosage', medicine.dosage),
                  _buildDetailRow('Fréquence', medicine.frequency),
                  _buildDetailRow('Doses totales', '${medicine.totalDoses}'),
                  _buildDetailRow('Doses restantes', '${medicine.remainingDoses}'),
                  if (medicine.expiryDate != null)
                    _buildDetailRow('Date d\'expiration',
                        DateFormat('dd/MM/yyyy').format(medicine.expiryDate!)),
                  _buildDetailRow('Date de début',
                      DateFormat('dd/MM/yyyy').format(medicine.startDate)),
                  if (medicine.notes != null && medicine.notes!.isNotEmpty)
                    _buildDetailRow('Notes', medicine.notes!),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _deleteMedicine(BuildContext context, String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous supprimer ce médicament ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseDatabase.instance
          .ref('medicines/$userId/${medicine.id}')
          .remove();
      
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Médicament supprimé'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}