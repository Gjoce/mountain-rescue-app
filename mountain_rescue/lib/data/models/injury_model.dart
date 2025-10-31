import 'package:cloud_firestore/cloud_firestore.dart';

class Injury {
  final String id;
  final String rescuerId;
  final String rescuerName;
  final String injuryType;
  final String severity;
  final String location;
  final String description;
  final DateTime timestamp;
  final String status; // e.g. pending, approved, resolved
  final String? photoUrl;

  Injury({
    required this.id,
    required this.rescuerId,
    required this.rescuerName,
    required this.injuryType,
    required this.severity,
    required this.location,
    required this.description,
    required this.timestamp,
    required this.status,
    this.photoUrl,
  });

  factory Injury.fromMap(Map<String, dynamic> data, String id) {
    return Injury(
      id: id,
      rescuerId: data['rescuerId'] ?? '',
      rescuerName: data['rescuerName'] ?? '',
      injuryType: data['injuryType'] ?? '',
      severity: data['severity'] ?? '',
      location: data['location'] ?? '',
      description: data['description'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
      photoUrl: data['photoUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rescuerId': rescuerId,
      'rescuerName': rescuerName,
      'injuryType': injuryType,
      'severity': severity,
      'location': location,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status,
      'photoUrl': photoUrl,
    };
  }
}
