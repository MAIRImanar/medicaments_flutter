// screens/donations_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../models/donation_medicine.dart';
import '../models/medicine.dart';
import 'add_donation_page.dart';

class DonationsPage extends StatefulWidget {
  const DonationsPage({Key? key}) : super(key: key);

  @override
  State<DonationsPage> createState() => _DonationsPageState();
}

class _DonationsPageState extends State<DonationsPage> {
  final user = FirebaseAuth.instance.currentUser!;
  List<DonationMedicine> donations = [];
  bool isLoading = true;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _loadDonations();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _loadDonations() {
    _subscription = FirebaseDatabase.instance
        .ref('donations')
        .onValue
        .listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        if (mounted) {
          setState(() {
            donations = data.entries
                .map((e) => DonationMedicine.fromMap(e.key, e.value))
                .where((d) => d.status == 'available')
                .toList();
            donations.sort((a, b) => b.postedDate.compareTo(a.postedDate));
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            donations = [];
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
        title: const Text('Les dons', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : donations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.volunteer_activism,
                          size: 100, color: Colors.grey[300]),
                      const SizedBox(height: 20),
                      Text(
                        'Aucun don disponible pour le moment',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: donations.length,
                  itemBuilder: (context, index) {
                    final donation = donations[index];
                    return _buildDonationCard(donation);
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddDonation(),
        icon: const Icon(Icons.add),
        label: const Text('Faire un don de médicament'),
        backgroundColor: Colors.teal,
      ),
    );
  }

  Widget _buildDonationCard(DonationMedicine donation) {
    final daysUntilExpiry = donation.expiryDate.difference(DateTime.now()).inDays;
    final isMyDonation = donation.userId == user.uid;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.favorite, color: Colors.green, size: 30),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        donation.medicineName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Le donateur : ${donation.userName}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildChip('${donation.dosage}', Icons.medical_information, Colors.indigo),
                _buildChip('Quantité : ${donation.quantity}', Icons.inventory, Colors.blue),
                _buildChip(donation.location, Icons.location_on, Colors.purple),
                _buildChip('Valable pour$daysUntilExpiry jours',
                    Icons.calendar_today, daysUntilExpiry < 90 ? Colors.orange : Colors.green),
              ],
            ),
            if (donation.description != null && donation.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                donation.description!,
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isMyDonation)
                  TextButton.icon(
                    onPressed: () => _deleteDonation(donation.id),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () => _requestDonation(donation),
                    icon: const Icon(Icons.phone),
                    label: const Text('Demande de contact'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ],
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

  void _navigateToAddDonation() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddDonationPage()),
    );
  }

  void _requestDonation(DonationMedicine donation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Demande de don'),
        content: Text(
          'Pour contacter le donateur ${donation.userName}\n'
          'Localisation : ${donation.location}\n\n'
          'Vous pouvez contacter directement le donateur pour organiser la récupération du médicament.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _deleteDonation(String donationId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous supprimer ce don ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseDatabase.instance
          .ref('donations/$donationId')
          .remove();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Don supprimé'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
