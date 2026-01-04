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

  // ✅ NEW: slope id + name (for map-based slopes)
  final int slopeId;
  final String slopeName;

  final String description;

  final DateTime timestamp;
  final String status;

  final String? photoUrl;
  final String? signatureUrl;

  Injury({
    required this.id,
    required this.rescuerId,
    required this.rescuerName,
    required this.rescuerEmail,
    required this.patientName,
    required this.patientBirthDate,
    required this.injuries,
    required this.severity,
    required this.slopeId,
    required this.slopeName,
    required this.description,
    required this.timestamp,
    required this.status,
    this.photoUrl,
    this.signatureUrl,
  });

  factory Injury.fromMap(Map<String, dynamic> data, String id) {
    // Backward compatibility (if you previously saved only "skiSlope")
    final legacySlope = (data['skiSlope'] ?? '').toString();

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

      // ✅ NEW fields (fallback to legacy where possible)
      slopeId: (data['slopeId'] is int)
          ? data['slopeId'] as int
          : int.tryParse((data['slopeId'] ?? '').toString()) ?? -1,
      slopeName: (data['slopeName'] ?? legacySlope).toString(),

      description: data['description'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
      photoUrl: data['photoUrl'],
      signatureUrl: data['signatureUrl'],
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

      // ✅ NEW: saved to Firestore for map + filtering
      'slopeId': slopeId,
      'slopeName': slopeName,

      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status,
      'photoUrl': photoUrl,
      'signatureUrl': signatureUrl,
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
    int? slopeId,
    String? slopeName,
    String? description,
    DateTime? timestamp,
    String? status,
    String? photoUrl,
    String? signatureUrl,
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
      slopeId: slopeId ?? this.slopeId,
      slopeName: slopeName ?? this.slopeName,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      photoUrl: photoUrl ?? this.photoUrl,
      signatureUrl: signatureUrl ?? this.signatureUrl,
    );
  }
}
