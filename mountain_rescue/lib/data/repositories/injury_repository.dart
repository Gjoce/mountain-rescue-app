import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/injury_model.dart';

class InjuryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Injury>> getInjuriesByRescuer(String rescuerId) {
    return _firestore
        .collection('injuries')
        .where('rescuerId', isEqualTo: rescuerId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Injury.fromMap(doc.data(), doc.id)).toList());
  }

  Future<Injury?> getInjuryById(String id) async {
    final doc = await _firestore.collection('injuries').doc(id).get();
    if (!doc.exists) return null;
    return Injury.fromMap(doc.data()!, doc.id);
  }
}
