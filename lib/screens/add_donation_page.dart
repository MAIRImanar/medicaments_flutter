// screens/add_donation_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import '../models/medicine.dart';
import '../models/donation_medicine.dart';

class AddDonationPage extends StatefulWidget {
  const AddDonationPage({Key? key}) : super(key: key);

  @override
  State<AddDonationPage> createState() => _AddDonationPageState();
}

class _AddDonationPageState extends State<AddDonationPage> {
  final user = FirebaseAuth.instance.currentUser!;
  List<Medicine> myMedicines = [];
  bool isLoading = true;
  bool isSelectingFromList = true;
  
  Medicine? selectedMedicine;
  
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _quantityController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _expiryDate;

  @override
  void initState() {
    super.initState();
    _loadMyMedicines();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadMyMedicines() async {
    final snapshot = await FirebaseDatabase.instance
        .ref('medicines/${user.uid}')
        .get();

    if (snapshot.value != null) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      if (mounted) {
        setState(() {
          myMedicines = data.entries
              .map((e) => Medicine.fromMap(e.key, e.value))
              .toList();
          myMedicines.sort((a, b) => a.name.compareTo(b.name));
          isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          myMedicines = [];
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un don', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text('Choisir parmi mes médicaments '),
                            subtitle: const Text('Ou ajouter un nouveau médicament '),
                            value: isSelectingFromList,
                            onChanged: (value) {
                              setState(() {
                                isSelectingFromList = value;
                                selectedMedicine = null;
                                _nameController.clear();
                                _dosageController.clear();
                              });
                            },
                            activeColor: Colors.teal,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  if (isSelectingFromList) ...[
                    if (myMedicines.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Icon(Icons.info_outline, size: 48, color: Colors.orange),
                              const SizedBox(height: 8),
                              const Text(
                                'Aucun médicament dans votre liste',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Ajoutez plutôt un nouveau médicament',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Choisissez le médicament à donner :',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              ...myMedicines.map((med) => RadioListTile<Medicine>(
                                title: Text(med.name),
                                subtitle: Text(med.dosage),
                                value: med,
                                groupValue: selectedMedicine,
                                onChanged: (value) {
                                  setState(() {
                                    selectedMedicine = value;
                                    _expiryDate = value?.expiryDate;
                                  });
                                },
                                activeColor: Colors.teal,
                              )),
                            ],
                          ),
                        ),
                      ),
                  ] else ...[
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom du médicament',
                        prefixIcon: Icon(Icons.medication),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: _dosageController,
                      decoration: const InputDecoration(
                        labelText: 'Dose (exemple : 500 mg)',
                        prefixIcon: Icon(Icons.medical_information),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantité',
                      prefixIcon: Icon(Icons.inventory),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Localisation',
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Card(
                    child: ListTile(
                      title: const Text('Date d’expiration'),
                      subtitle: Text(_expiryDate != null
                          ? DateFormat('dd/MM/yyyy').format(_expiryDate!)
                          : 'Choisissez la date'),
                      leading: const Icon(Icons.calendar_today),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 180)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 3650)),
                        );
                        if (date != null) setState(() => _expiryDate = date);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description supplémentaire (facultatif)',
                      prefixIcon: Icon(Icons.description),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _submitDonation,
                      icon: const Icon(Icons.volunteer_activism),
                      label: const Text('Publier la donation', style: TextStyle(fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _submitDonation() async {
    String medicineName;
    String dosage;

    if (isSelectingFromList) {
      if (selectedMedicine == null) {
        _showError('Veuillez choisir un médicament dans la liste');
        return;
      }
      medicineName = selectedMedicine!.name;
      dosage = selectedMedicine!.dosage;
    } else {
      if (_nameController.text.isEmpty || _dosageController.text.isEmpty) {
        _showError('Veuillez entrer le nom du médicament et la dose');
        return;
      }
      medicineName = _nameController.text.trim();
      dosage = _dosageController.text.trim();
    }

    if (_quantityController.text.isEmpty) {
      _showError('Veuillez saisir la quantité');
      return;
    }

    if (_locationController.text.isEmpty) {
      _showError('Veuillez entrer Localisation');
      return;
    }

    if (_expiryDate == null) {
      _showError('Veuillez sélectionner la date de péremption');
      return;
    }

    final userSnapshot = await FirebaseDatabase.instance
        .ref('users/${user.uid}')
        .get();
    
    final userName = userSnapshot.child('name').value as String? ?? 'Utilisateur';

    final donation = DonationMedicine(
      id: '',
      userId: user.uid,
      userName: userName,
      medicineName: medicineName,
      dosage: dosage,
      quantity: int.parse(_quantityController.text),
      expiryDate: _expiryDate!,
      description: _descriptionController.text.trim(),
      location: _locationController.text.trim(),
      status: 'available',
      postedDate: DateTime.now(),
    );

    await FirebaseDatabase.instance
        .ref('donations')
        .push()
        .set(donation.toMap());

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Don ajouté avec succès ✓'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}