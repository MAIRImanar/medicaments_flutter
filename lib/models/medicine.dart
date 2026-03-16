// models/medicine.dart
class Medicine {
  String id;
  String name;
  String dosage;
  String frequency;
  List<String> times;
  DateTime startDate;
  DateTime? endDate;
  DateTime? expiryDate;
  int totalDoses;
  int remainingDoses;
  String? notes;
  String? imageUrl;

  Medicine({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.times,
    required this.startDate,
    this.endDate,
    this.expiryDate,
    required this.totalDoses,
    required this.remainingDoses,
    this.notes,
    this.imageUrl,
  });

  factory Medicine.fromMap(String id, Map<dynamic, dynamic> map) {
    return Medicine(
      id: id,
      name: map['name'] ?? '',
      dosage: map['dosage'] ?? '',
      frequency: map['frequency'] ?? '',
      times: List<String>.from(map['times'] ?? []),
      startDate: DateTime.parse(map['startDate']),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      expiryDate: map['expiryDate'] != null ? DateTime.parse(map['expiryDate']) : null,
      totalDoses: map['totalDoses'] ?? 0,
      remainingDoses: map['remainingDoses'] ?? 0,
      notes: map['notes'],
      imageUrl: map['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'times': times,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'totalDoses': totalDoses,
      'remainingDoses': remainingDoses,
      'notes': notes,
      'imageUrl': imageUrl,
    };
  }
}