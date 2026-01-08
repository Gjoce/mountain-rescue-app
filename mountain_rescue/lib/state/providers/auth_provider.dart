import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_model.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firebaseAuthStateProvider = StreamProvider<User?>((ref) {
  return ref.read(firebaseAuthProvider).authStateChanges();
});

/// Your app-level auth repository (used in login/register/logout)
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    auth: ref.read(firebaseAuthProvider),
    firestore: ref.read(firestoreProvider),
  );
});

/// Current signed-in user from Firestore as a *typed* UserModel?
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authAsync = ref.watch(firebaseAuthStateProvider);

  return authAsync.when(
    data: (firebaseUser) {
      if (firebaseUser == null) {
        return Stream<UserModel?>.value(null); // NOT const
      }

      final firestore = ref.read(firestoreProvider);

      return firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .snapshots()
          .map((doc) {
            if (!doc.exists) return null;
            final data = doc.data() as Map<String, dynamic>;
            return UserModel.fromMap(data, doc.id);
          });
    },
    loading: () => Stream<UserModel?>.value(null),
    error: (_, __) => Stream<UserModel?>.value(null),
  );
});

class AuthRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  AuthRepository({required this.auth, required this.firestore});

  Future<UserCredential> loginUser(String email, String password) async {
    return auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  /// Creates FirebaseAuth user + Firestore users/{uid} document
  Future<UserCredential> registerUser({
    required String name,
    required String email,
    required String password,
    String role = 'rescuer',
  }) async {
    final cred = await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    await cred.user?.updateDisplayName(name.trim());

    await firestore.collection('users').doc(cred.user!.uid).set({
      'name': name.trim(),
      'email': email.trim(),
      'role': role,
      'isActive': true,
      'photoUrl': null,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return cred;
  }

  Future<void> signOut() async {
    await auth.signOut();
  }

  /// Helper used by settings to update name consistently
  Future<void> updateDisplayNameAndFirestoreName({
    required String uid,
    required String newName,
  }) async {
    final u = auth.currentUser;
    if (u != null && u.uid == uid) {
      await u.updateDisplayName(newName);
    }

    await firestore.collection('users').doc(uid).set({
      'name': newName,
    }, SetOptions(merge: true));
  }

  /// Helper used by settings to update profile picture URL
  Future<void> updatePhotoUrl({
    required String uid,
    required String photoUrl,
  }) async {
    final u = auth.currentUser;
    if (u != null && u.uid == uid) {
      await u.updatePhotoURL(photoUrl);
    }

    await firestore.collection('users').doc(uid).set({
      'photoUrl': photoUrl,
    }, SetOptions(merge: true));
  }

  /// Helper used by rescuer settings to toggle active/inactive
  Future<void> updateRescuerActiveStatus({
    required String uid,
    required bool isActive,
  }) async {
    await firestore.collection('users').doc(uid).set({
      'isActive': isActive,
    }, SetOptions(merge: true));
  }
}
