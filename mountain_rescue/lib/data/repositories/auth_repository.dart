import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  // Used by your dialogs/buttons
  Future<void> signOut() => _auth.signOut();

  // FIX: method expected by your Login screen
  Future<UserCredential> loginUser(String email, String password) async {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  // FIX: method expected by your Register screen
  // Creates FirebaseAuth user + creates Firestore "users/{uid}" doc
  Future<UserCredential> registerUser(
      String name,
      String email,
      String password, {
        String role = 'rescuer',
      }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final uid = cred.user!.uid;

    // Store display name in Auth (optional but helpful)
    await cred.user!.updateDisplayName(name.trim());

    // Create/merge Firestore user profile
    await _firestore.collection('users').doc(uid).set({
      'name': name.trim(),
      'email': email.trim(),
      'role': role,
      'isActive': true, // default rescuer status
      'photoUrl': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return cred;
  }

  // Optional helper if you use password reset
  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }
}
