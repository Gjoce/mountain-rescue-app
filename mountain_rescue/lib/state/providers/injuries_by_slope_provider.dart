import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Live stream of injuries for a specific slope.
///
/// Fixes the "flashing + loading every few seconds" issue by avoiding Firestore
/// composite-index requirements (no `orderBy` in Firestore).
/// We sort by timestamp client-side instead.
final injuriesBySlopeProvider =
    StreamProvider.family<
      List<QueryDocumentSnapshot<Map<String, dynamic>>>,
      int
    >((ref, slopeId) {
      final query = FirebaseFirestore.instance
          .collection('injuries') // adjust if your collection path is different
          .where('slopeId', isEqualTo: slopeId);

      return query.snapshots().map((snapshot) {
        final docs = snapshot.docs.toList();

        docs.sort((a, b) {
          final ta = a.data()['timestamp'];
          final tb = b.data()['timestamp'];

          DateTime da = DateTime.fromMillisecondsSinceEpoch(0);
          DateTime db = DateTime.fromMillisecondsSinceEpoch(0);

          if (ta is Timestamp) da = ta.toDate();
          if (tb is Timestamp) db = tb.toDate();

          return db.compareTo(da); // newest first
        });

        return docs;
      });
    });
