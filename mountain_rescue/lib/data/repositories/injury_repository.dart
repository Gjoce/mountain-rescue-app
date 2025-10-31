import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/injury_model.dart';
import 'dart:typed_data';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class InjuryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'injuries';
  final String bucketName = 'injury-files';
  final String apiUrl =
      "https://hrghcaaqxkznzpwexuaq.supabase.co/functions/v1/upload_injury_photo";

  Stream<List<Injury>> getInjuriesByRescuer(String rescuerId) {
    return _firestore
        .collection('injuries')
        .where('rescuerId', isEqualTo: rescuerId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Injury.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<Injury?> getInjuryById(String id) async {
    final doc = await _firestore.collection('injuries').doc(id).get();
    if (!doc.exists) return null;
    return Injury.fromMap(doc.data()!, doc.id);
  }

  Future<String> createInjury(Map<String, dynamic> injuryData) async {
    try {
      final docRef = await _firestore
          .collection(_collectionName)
          .add(injuryData);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create injury report: $e');
    }
  }

  Stream<List<Injury>> getInjuriesByStatus(String status) {
    return _firestore
        .collection(_collectionName)
        .where('status', isEqualTo: status)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Injury.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<Injury>> getAllInjuries() {
    return _firestore
        .collection(_collectionName)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Injury.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<Injury>> getInjuriesBySeverity(String severity) {
    return _firestore
        .collection(_collectionName)
        .where('severity', isEqualTo: severity)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Injury.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<Injury>> getInjuriesBySlope(String skiSlope) {
    return _firestore
        .collection(_collectionName)
        .where('skiSlope', isEqualTo: skiSlope)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Injury.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> updateInjuryStatus(String id, String status) async {
    try {
      await _firestore.collection(_collectionName).doc(id).update({
        'status': status,
      });
    } catch (e) {
      throw Exception('Failed to update injury status: $e');
    }
  }

  Future<void> updateInjurySeverity(String id, String severity) async {
    try {
      await _firestore.collection(_collectionName).doc(id).update({
        'severity': severity,
      });
    } catch (e) {
      throw Exception('Failed to update injury severity: $e');
    }
  }

  Future<void> updateInjury(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_collectionName).doc(id).update(data);
    } catch (e) {
      throw Exception('Failed to update injury: $e');
    }
  }

  Future<void> deleteInjury(String id) async {
    try {
      await _firestore.collection(_collectionName).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete injury: $e');
    }
  }

  Stream<List<Injury>> getInjuriesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return _firestore
        .collection(_collectionName)
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        )
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Injury.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<Injury>> getRecentInjuries() {
    final yesterday = DateTime.now().subtract(const Duration(hours: 24));
    return _firestore
        .collection(_collectionName)
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(yesterday),
        )
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Injury.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<Map<String, dynamic>> getInjuryStatistics() async {
    try {
      final snapshot = await _firestore.collection(_collectionName).get();
      final injuries = snapshot.docs
          .map((doc) => Injury.fromMap(doc.data(), doc.id))
          .toList();

      final statusCounts = <String, int>{};
      final severityCounts = <String, int>{};
      final slopeCounts = <String, int>{};

      for (var injury in injuries) {
        statusCounts[injury.status] = (statusCounts[injury.status] ?? 0) + 1;
        severityCounts[injury.severity] =
            (severityCounts[injury.severity] ?? 0) + 1;
        slopeCounts[injury.skiSlope] = (slopeCounts[injury.skiSlope] ?? 0) + 1;
      }

      return {
        'total': injuries.length,
        'statusBreakdown': statusCounts,
        'severityBreakdown': severityCounts,
        'slopeBreakdown': slopeCounts,
      };
    } catch (e) {
      throw Exception('Failed to get statistics: $e');
    }
  }

  Future<String> uploadIdPhoto(String injuryId, Uint8List fileBytes) async {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid;

    final request = http.MultipartRequest(
      "POST",
      Uri.parse("$apiUrl/upload-id-photo"),
    );

    request.fields["injuryId"] = injuryId;
    request.fields["userId"] = userId!;

    request.files.add(
      http.MultipartFile.fromBytes(
        "file",
        fileBytes,
        filename: "id_photo.jpg",
        contentType: MediaType("image", "jpeg"),
      ),
    );

    request.headers["Authorization"] =
        "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhyZ2hjYWFxeGt6bnpwd2V4dWFxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE5MTcyMTUsImV4cCI6MjA3NzQ5MzIxNX0.rBvDfhjFOM-crmmZ_csEh63fnQYYfR2StGPmlt8CcTc";

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception("File upload failed -> $body");
    }

    final Map<String, dynamic> json = jsonDecode(body);

    final String publicUrl = json['filePath'] as String;

    return publicUrl;
  }
}
