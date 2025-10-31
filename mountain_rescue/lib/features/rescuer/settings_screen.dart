import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../state/providers/auth_provider.dart';

class RescuerSettingsScreen extends ConsumerStatefulWidget {
  const RescuerSettingsScreen({super.key});

  @override
  ConsumerState<RescuerSettingsScreen> createState() =>
      _RescuerSettingsScreenState();
}

class _RescuerSettingsScreenState
    extends ConsumerState<RescuerSettingsScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  bool _isDark = false;

  Future<void> _changeDisplayName(BuildContext context) async {
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
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await user.updateDisplayName(newName);
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .update({'name': newName});
                setState(() {});
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Name updated successfully')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _changeProfilePhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final file = File(image.path);
    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_photos')
        .child('${user.uid}.jpg');

    await ref.putFile(file);
    final url = await ref.getDownloadURL();

    await user.updatePhotoURL(url);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({'photoUrl': url});

    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile photo updated')),
    );
  }

  Future<void> _resetPassword(BuildContext context) async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Password reset email sent. Check your inbox.')),
    );
  }

  Future<void> _exportUserData() async {
    final pdf = pw.Document();
    final userData = {
      'Name': user.displayName ?? 'N/A',
      'Email': user.email ?? 'N/A',
      'Role': 'Rescuer',
      'Joined': DateFormat.yMMMd().format(user.metadata.creationTime!),
    };

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Padding(
          padding: const pw.EdgeInsets.all(32),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Mountain Rescue - User Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  )),
              pw.SizedBox(height: 16),
              pw.Text('Generated on: ${DateFormat.yMMMMd().format(DateTime.now())}'),
              pw.Divider(),
              pw.SizedBox(height: 20),
              ...userData.entries.map(
                    (e) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6),
                  child: pw.Text('${e.key}: ${e.value}',
                      style: const pw.TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  void _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authRepositoryProvider).signOut();
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    _isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
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
                    GestureDetector(
                      onTap: _changeProfilePhoto,
                      child: CircleAvatar(
                        radius: 48,
                        backgroundImage: user.photoURL != null
                            ? NetworkImage(user.photoURL!)
                            : null,
                        backgroundColor: Colors.white,
                        child: user.photoURL == null
                            ? const Icon(Icons.person,
                            color: Color(0xFF1565C0), size: 48)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user.displayName ?? 'Unnamed Rescuer',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      user.email ?? '',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.9), fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _changeDisplayName(context),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Name'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              ListTile(
                leading: const Icon(Icons.dark_mode, color: Colors.white),
                title: const Text('Dark Mode',
                    style: TextStyle(color: Colors.white)),
                trailing: Switch(
                  value: _isDark,
                  onChanged: (_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                        Text('System theme toggle works automatically.'),
                      ),
                    );
                  },
                ),
              ),
              const Divider(color: Colors.white54),
              ListTile(
                leading: const Icon(Icons.lock_outline, color: Colors.white),
                title: const Text('Change Password',
                    style: TextStyle(color: Colors.white)),
                onTap: () => _resetPassword(context),
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.white),
                title: const Text('Export My Data (PDF)',
                    style: TextStyle(color: Colors.white)),
                onTap: _exportUserData,
              ),
              ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.white),
                title: const Text('About App',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Mountain Rescue',
                    applicationVersion: '1.2.0',
                    applicationLegalese:
                    '© 2025 Mountain Rescue Team. All rights reserved.',
                  );
                },
              ),
              const Divider(color: Colors.white54),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text('Logout',
                    style: TextStyle(color: Colors.redAccent)),
                onTap: () => _logout(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
