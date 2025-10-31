import 'package:cloud_firestore/cloud_firestore.dart';

class InjuryDetail {
  final String bodyPart;
  final String injuryType;

  InjuryDetail({required this.bodyPart, required this.injuryType});

  factory InjuryDetail.fromMap(Map<String, dynamic> data) {
    return InjuryDetail(
      bodyPart: data['bodyPart'] ?? '',
      injuryType: data['injuryType'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'bodyPart': bodyPart, 'injuryType': injuryType};
  }
}

class Injury {
  final String id;
  final String rescuerId;
  final String rescuerName;
  final String rescuerEmail;

  final String patientName;
  final DateTime patientBirthDate;

  final List<InjuryDetail> injuries;
  final String severity;
  final String skiSlope;
  final String description;

  final DateTime timestamp;
  final String status;
  //final String? photoUrl; // To be implemented

  Injury({
    required this.id,
    required this.rescuerId,
    required this.rescuerName,
    required this.rescuerEmail,
    required this.patientName,
    required this.patientBirthDate,
    required this.injuries,
    required this.severity,
    required this.skiSlope,
    required this.description,
    required this.timestamp,
    required this.status,
    //this.photoUrl, // To be implemented
  });

  factory Injury.fromMap(Map<String, dynamic> data, String id) {
    return Injury(
      id: id,
      rescuerId: data['rescuerId'] ?? '',
      rescuerName: data['rescuerName'] ?? '',
      rescuerEmail: data['rescuerEmail'] ?? '',
      patientName: data['patientName'] ?? '',
      patientBirthDate: (data['patientBirthDate'] as Timestamp).toDate(),
      injuries:
          (data['injuries'] as List<dynamic>?)
              ?.map(
                (item) => InjuryDetail.fromMap(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
      severity: data['severity'] ?? 'minor',
      skiSlope: data['skiSlope'] ?? '',
      description: data['description'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
      //photoUrl: data['photoUrl'], // To be implemented
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rescuerId': rescuerId,
      'rescuerName': rescuerName,
      'rescuerEmail': rescuerEmail,
      'patientName': patientName,
      'patientBirthDate': Timestamp.fromDate(patientBirthDate),
      'injuries': injuries.map((injury) => injury.toMap()).toList(),
      'severity': severity,
      'skiSlope': skiSlope,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status,
      //'photoUrl': photoUrl, // To be implemented
    };
  }

  int get injuryCount => injuries.length;

  String get injurySummary {
    if (injuries.isEmpty) return 'No injuries specified';
    if (injuries.length == 1) {
      return '${injuries.first.bodyPart}: ${injuries.first.injuryType}';
    }
    return '${injuries.length} injuries';
  }

  List<String> get affectedBodyParts =>
      injuries.map((i) => i.bodyPart).toList();

  int getPatientAge() {
    final age = timestamp.year - patientBirthDate.year;
    if (timestamp.month < patientBirthDate.month ||
        (timestamp.month == patientBirthDate.month &&
            timestamp.day < patientBirthDate.day)) {
      return age - 1;
    }
    return age;
  }

  Injury copyWith({
    String? id,
    String? rescuerId,
    String? rescuerName,
    String? rescuerEmail,
    String? patientName,
    DateTime? patientBirthDate,
    List<InjuryDetail>? injuries,
    String? severity,
    String? skiSlope,
    String? description,
    DateTime? timestamp,
    String? status,
  }) {
    return Injury(
      id: id ?? this.id,
      rescuerId: rescuerId ?? this.rescuerId,
      rescuerName: rescuerName ?? this.rescuerName,
      rescuerEmail: rescuerEmail ?? this.rescuerEmail,
      patientName: patientName ?? this.patientName,
      patientBirthDate: patientBirthDate ?? this.patientBirthDate,
      injuries: injuries ?? this.injuries,
      severity: severity ?? this.severity,
      skiSlope: skiSlope ?? this.skiSlope,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
    );
  }
}
