// models/donation_medicine.dart
class DonationMedicine {
  String id;
  String userId;
  String userName;
  String medicineName;
  String dosage;
  int quantity;
  DateTime expiryDate;
  String? description;
  String location;
  String status;
  DateTime postedDate;

  DonationMedicine({
    required this.id,
    required this.userId,
    required this.userName,
    required this.medicineName,
    required this.dosage,
    required this.quantity,
    required this.expiryDate,
    this.description,
    required this.location,
    required this.status,
    required this.postedDate,
  });

  factory DonationMedicine.fromMap(String id, Map<dynamic, dynamic> map) {
    return DonationMedicine(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      medicineName: map['medicineName'] ?? '',
      dosage: map['dosage'] ?? '',
      quantity: map['quantity'] ?? 0,
      expiryDate: DateTime.parse(map['expiryDate']),
      description: map['description'],
      location: map['location'] ?? '',
      status: map['status'] ?? 'available',
      postedDate: DateTime.parse(map['postedDate']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'medicineName': medicineName,
      'dosage': dosage,
      'quantity': quantity,
      'expiryDate': expiryDate.toIso8601String(),
      'description': description,
      'location': location,
      'status': status,
      'postedDate': postedDate.toIso8601String(),
    };
  }
}