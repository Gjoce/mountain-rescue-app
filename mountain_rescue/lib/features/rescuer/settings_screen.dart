import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../state/providers/auth_provider.dart';

class RescuerSettingsScreen extends ConsumerStatefulWidget {
  const RescuerSettingsScreen({super.key});

  @override
  ConsumerState<RescuerSettingsScreen> createState() =>
      _RescuerSettingsScreenState();
}

class _RescuerSettingsScreenState extends ConsumerState<RescuerSettingsScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();

  bool _isDark = false;
  bool _uploadingPhoto = false;
  bool _updatingStatus = false;

  Stream<DocumentSnapshot<Map<String, dynamic>>> _userDocStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  Future<void> _pickAndUploadProfilePhoto(User user) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (picked == null) return;

    setState(() => _uploadingPhoto = true);

    try {
      final file = File(picked.path);
      final refStorage = _storage.ref().child('profile_photos/${user.uid}.jpg');

      await refStorage.putFile(file);
      final url = await refStorage.getDownloadURL();

      await user.updatePhotoURL(url);

      await _firestore.collection('users').doc(user.uid).set(
        {'photoUrl': url},
        SetOptions(merge: true),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile picture: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _changeDisplayName(User user) async {
    final controller = TextEditingController(text: user.displayName ?? '');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Change Display Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'New name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) return;

              await user.updateDisplayName(newName);
              await _firestore.collection('users').doc(user.uid).set(
                {'name': newName},
                SetOptions(merge: true),
              );

              if (!mounted) return;
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Name updated successfully')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetPassword(User user) async {
    final email = user.email;
    if (email == null || email.isEmpty) return;

    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password reset email sent. Check your inbox.'),
      ),
    );
  }

  Future<void> _updateRescuerActiveStatus({
    required User user,
    required bool isActive,
  }) async {
    setState(() => _updatingStatus = true);

    try {
      await _firestore.collection('users').doc(user.uid).set(
        {'isActive': isActive},
        SetOptions(merge: true),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isActive ? 'Status: Active' : 'Status: Inactive'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    } finally {
      if (mounted) setState(() => _updatingStatus = false);
    }
  }

  Future<void> _logout() async {
    await ref.read(authRepositoryProvider).signOut();
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    _isDark = Theme.of(context).brightness == Brightness.dark;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Rescuer Settings'),
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Not logged in')),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _userDocStream(user.uid),
      builder: (context, snapshot) {
        final userData = snapshot.data?.data();

        final name = (user.displayName?.isNotEmpty == true)
            ? user.displayName!
            : (userData?['name'] ?? 'Rescuer');

        final email = user.email ?? '';

        final photoUrl = (user.photoURL?.isNotEmpty == true)
            ? user.photoURL
            : userData?['photoUrl'];

        final isActive = (userData?['isActive'] is bool)
            ? (userData!['isActive'] as bool)
            : true; // default active

        return Scaffold(
          appBar: AppBar(
            title: const Text('Rescuer Settings'),
            backgroundColor: const Color(0xFF1565C0),
            foregroundColor: Colors.white,
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isDark
                    ? [const Color(0xFF1A237E), const Color(0xFF0D47A1)]
                    : [const Color(0xFF1565C0), const Color(0xFF42A5F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 52,
                              backgroundColor: Colors.white,
                              backgroundImage:
                              photoUrl != null ? NetworkImage(photoUrl) : null,
                              child: photoUrl == null
                                  ? const Icon(
                                Icons.person,
                                color: Color(0xFF1565C0),
                                size: 54,
                              )
                                  : null,
                            ),
                            Material(
                              color: Colors.white,
                              shape: const CircleBorder(),
                              child: InkWell(
                                onTap: _uploadingPhoto
                                    ? null
                                    : () => _pickAndUploadProfilePhoto(user),
                                customBorder: const CircleBorder(),
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: _uploadingPhoto
                                      ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                      : const Icon(
                                    Icons.camera_alt,
                                    size: 18,
                                    color: Color(0xFF1565C0),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          email,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isActive ? 'ACTIVE' : 'INACTIVE',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () => _changeDisplayName(user),
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit Name'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  ListTile(
                    leading: const Icon(Icons.toggle_on, color: Colors.white),
                    title: const Text(
                      'Rescuer Status',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      isActive ? 'Currently Active' : 'Currently Inactive',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    trailing: _updatingStatus
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : Switch(
                      value: isActive,
                      onChanged: (val) => _updateRescuerActiveStatus(
                        user: user,
                        isActive: val,
                      ),
                    ),
                  ),

                  ListTile(
                    leading: const Icon(Icons.image_outlined, color: Colors.white),
                    title: const Text(
                      'Change Profile Picture',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: _uploadingPhoto
                        ? null
                        : () => _pickAndUploadProfilePhoto(user),
                  ),

                  ListTile(
                    leading: const Icon(Icons.lock_outline, color: Colors.white),
                    title: const Text(
                      'Change Password',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () => _resetPassword(user),
                  ),

                  ListTile(
                    leading: const Icon(Icons.info_outline, color: Colors.white),
                    title: const Text(
                      'About App',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'Mountain Rescue – Rescuer App',
                        applicationVersion: '1.2.0',
                        applicationLegalese:
                        '© 2025 Mountain Rescue Team. All rights reserved.',
                      );
                    },
                  ),

                  const Divider(color: Colors.white54),

                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.redAccent),
                    title: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                    onTap: _logout,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
