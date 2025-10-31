import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

  /// Generate a random 10-character password
  String _generatePassword() {
    const chars =
        'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789@#%!';
    final rand = Random.secure();
    return List.generate(10, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<void> _addRescuer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _generatedPassword = null;
    });

    try {
      final password = _generatePassword();

      // 1️⃣ Create user in Firebase Authentication
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: password,
      );

      // 2️⃣ Save user in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'role': 'rescuer',
            'createdAt': FieldValue.serverTimestamp(),
          });

      setState(() => _generatedPassword = password);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rescuer account created successfully')),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Error: ${e.message}';
      if (e.code == 'email-already-in-use') {
        message = 'This email is already registered.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email format.';
      } else if (e.code == 'weak-password') {
        message = 'Generated password is too weak.';
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unexpected error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
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
                    v == null || v.isEmpty ? 'Enter rescuer name' : null,
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
                  if (v == null || v.isEmpty) return 'Enter email address';
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[300]!),
                  ),
                  child: Column(
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
                      const SizedBox(height: 8),
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
