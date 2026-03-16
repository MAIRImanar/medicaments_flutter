// screens/add_medicine_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import '../models/medicine.dart';

class AddMedicinePage extends StatefulWidget {
  const AddMedicinePage({Key? key}) : super(key: key);

  @override
  State<AddMedicinePage> createState() => _AddMedicinePageState();
}

class _AddMedicinePageState extends State<AddMedicinePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _totalDosesController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedFrequency = 'Quotidien';
  final List<String> _frequencies = ['Quotidien', '2 fois par jour', '3 fois par jour', 'Hebdomadaire'];
  DateTime? _expiryDate;

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _totalDosesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un médicament', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom du médicament',
                prefixIcon: Icon(Icons.medication),
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Obligatoire' : null,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _dosageController,
              decoration: const InputDecoration(
                labelText: 'Dosage (ex: 500mg)',
                prefixIcon: Icon(Icons.medical_information),
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Obligatoire' : null,
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              value: _selectedFrequency,
              decoration: const InputDecoration(
                labelText: 'Fréquence',
                prefixIcon: Icon(Icons.repeat),
                border: OutlineInputBorder(),
              ),
              items: _frequencies.map((freq) {
                return DropdownMenuItem(value: freq, child: Text(freq));
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedFrequency = value!);
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _totalDosesController,
              decoration: const InputDecoration(
                labelText: 'Nombre total de doses',
                prefixIcon: Icon(Icons.inventory),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (v) => v == null || v.isEmpty ? 'Obligatoire' : null,
            ),
            const SizedBox(height: 16),
            
            Card(
              child: ListTile(
                title: const Text('Date d\'expiration'),
                subtitle: Text(_expiryDate != null
                    ? DateFormat('dd/MM/yyyy').format(_expiryDate!)
                    : 'Choisir la date'),
                leading: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 365)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (date != null) setState(() => _expiryDate = date);
                },
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optionnel)',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: _saveMedicine,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('Enregistrer',
                  style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _saveMedicine() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser!;
    final totalDoses = int.parse(_totalDosesController.text);

    final medicine = Medicine(
      id: '',
      name: _nameController.text.trim(),
      dosage: _dosageController.text.trim(),
      frequency: _selectedFrequency,
      times: [],
      startDate: DateTime.now(),
      expiryDate: _expiryDate,
      totalDoses: totalDoses,
      remainingDoses: totalDoses,
      notes: _notesController.text.trim(),
    );

    await FirebaseDatabase.instance
        .ref('medicines/${user.uid}')
        .push()
        .set(medicine.toMap());

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Médicament ajouté avec succès ✓'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}