import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../../firebase_options.dart';

class AddRescuerScreen extends StatefulWidget {
  const AddRescuerScreen({super.key});

  @override
  State<AddRescuerScreen> createState() => _AddRescuerScreenState();
}

class _AddRescuerScreenState extends State<AddRescuerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  String? _generatedPassword;
  String? _createdUserEmail;

  /// Generate a random 10-character password
  String _generatePassword() {
    const chars =
        'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789@#%!';
    final rand = Random.secure();
    return List.generate(10, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<FirebaseApp> _getOrCreateSecondaryApp() async {
    // If it already exists, reuse it
    for (final app in Firebase.apps) {
      if (app.name == 'secondary') return app;
    }
    // Otherwise create it
    return Firebase.initializeApp(
      name: 'secondary',
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  Future<void> _addRescuer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _generatedPassword = null;
      _createdUserEmail = null;
    });

    final adminUserBefore = FirebaseAuth.instance.currentUser;

    try {
      final password = _generatePassword();

      // Create rescuer account WITHOUT switching admin session:
      final secondaryApp = await _getOrCreateSecondaryApp();
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: password,
      );

      final rescuerUid = cred.user?.uid;
      if (rescuerUid == null) {
        throw Exception('Failed to create rescuer account (no UID).');
      }

      // Save user in Firestore
      await FirebaseFirestore.instance.collection('users').doc(rescuerUid).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': 'rescuer',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Important: sign out secondary auth (cleanup)
      await secondaryAuth.signOut();

      // Safety: ensure admin session is still the same
      final adminAfter = FirebaseAuth.instance.currentUser;
      if (adminUserBefore?.uid != adminAfter?.uid) {
        // In practice this should not happen with secondary app, but keep it safe.
        // (No automatic "fix" here—just a defensive check.)
        debugPrint('Warning: admin session changed unexpectedly.');
      }

      setState(() {
        _generatedPassword = password;
        _createdUserEmail = _emailController.text.trim();
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rescuer account created successfully')),
      );

      // Optional: clear inputs after success
      _nameController.clear();
      _emailController.clear();
    } on FirebaseAuthException catch (e) {
      String message = 'Error: ${e.message}';
      if (e.code == 'email-already-in-use') {
        message = 'This email is already registered.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email format.';
      } else if (e.code == 'weak-password') {
        message = 'Generated password is too weak.';
      } else if (e.code == 'operation-not-allowed') {
        message =
            'Email/password accounts are not enabled in Firebase Auth settings.';
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unexpected error: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Rescuer'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter rescuer name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Enter email address';
                  }
                  if (!v.contains('@')) return 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _addRescuer,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.person_add),
                  label: Text(
                    _isLoading ? 'Creating...' : 'Add Rescuer',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              if (_generatedPassword != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock, color: Colors.green, size: 30),
                      const SizedBox(height: 8),
                      const Text(
                        'Rescuer Account Created!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_createdUserEmail != null)
                        Text(
                          'Email: $_createdUserEmail',
                          style: TextStyle(color: Colors.grey[800]),
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 10),
                      Text(
                        'Temporary Password:',
                        style: TextStyle(color: Colors.grey[800]),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        _generatedPassword!,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Give this password to the rescuer. They can log in and then change it.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
