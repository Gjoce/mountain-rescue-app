import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class _RescuerSettingsScreenState extends ConsumerState<RescuerSettingsScreen> {
  final user = FirebaseAuth.instance.currentUser!;

  Future<void> _changeDisplayName() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final currentName = userDoc.data()?['name'] ?? user.displayName ?? '';
    final controller = TextEditingController(text: currentName);

    final currentContext = context;

    final newName = await showDialog<String>(
      // ignore: use_build_context_synchronously
      context: currentContext,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                Navigator.pop(dialogContext, newName);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && mounted) {
      try {
        await user.updateDisplayName(newName);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'name': newName});

        ref.invalidate(currentUserProvider);

        if (mounted) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(currentContext).showSnackBar(
            const SnackBar(content: Text('Name updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            // ignore: use_build_context_synchronously
            currentContext,
          ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
        }
      }
    }
  }

  Future<void> _resetPassword() async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password reset email sent. Check your inbox.'),
      ),
    );
  }

  Future<void> _exportUserData() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final userName = userDoc.data()?['name'] ?? user.displayName ?? 'N/A';

    final pdf = pw.Document();
    final userData = {
      'Name': userName,
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
              pw.Text(
                'Mountain Rescue - User Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'Generated on: ${DateFormat.yMMMMd().format(DateTime.now())}',
              ),
              pw.Divider(),
              pw.SizedBox(height: 20),
              ...userData.entries.map(
                (e) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6),
                  child: pw.Text(
                    '${e.key}: ${e.value}',
                    style: const pw.TextStyle(fontSize: 16),
                  ),
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
    final userAsync = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1A237E),
                    const Color(0xFF0D47A1),
                    const Color(0xFF01579B),
                  ]
                : [
                    const Color(0xFF1565C0),
                    const Color(0xFF1976D2),
                    const Color(0xFF42A5F5),
                  ],
          ),
        ),
        child: SafeArea(
          child: userAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            error: (err, _) => Center(
              child: Text(
                'Error loading user',
                style: TextStyle(color: Colors.white),
              ),
            ),
            data: (userData) {
              final userName = userData?.name ?? 'Unnamed Rescuer';

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Settings',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        CircleAvatar(
                          radius: 56,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          child: CircleAvatar(
                            radius: 52,
                            backgroundImage: user.photoURL != null
                                ? NetworkImage(user.photoURL!)
                                : null,
                            backgroundColor: Colors.white,
                            child: user.photoURL == null
                                ? const Icon(
                                    Icons.person,
                                    color: Color(0xFF1565C0),
                                    size: 52,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email ?? '',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _changeDisplayName,
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Edit Name'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.2,
                            ),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E1E1E)
                            : Colors.grey[50],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          Text(
                            'Account Settings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 16),

                          _SettingsCard(
                            icon: Icons.lock_outline,
                            title: 'Change Password',
                            subtitle: 'Reset your password via email',
                            color: const Color(0xFF1565C0),
                            isDark: isDark,
                            onTap: _resetPassword,
                          ),

                          const SizedBox(height: 12),

                          _SettingsCard(
                            icon: Icons.picture_as_pdf,
                            title: 'Export My Data',
                            subtitle: 'Download your data as PDF',
                            color: const Color(0xFF5E35B1),
                            isDark: isDark,
                            onTap: _exportUserData,
                          ),

                          const SizedBox(height: 12),

                          _SettingsCard(
                            icon: Icons.info_outline,
                            title: 'About App',
                            subtitle: 'Version and legal information',
                            color: const Color(0xFF00897B),
                            isDark: isDark,
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

                          const SizedBox(height: 32),

                          Material(
                            color: isDark
                                ? Colors.red[900]!.withValues(alpha: 0.3)
                                : Colors.red[50],
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              onTap: () => _logout(context, ref),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.logout,
                                        color: Colors.red,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Logout',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.red,
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            'Sign out of your account',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.red,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          Center(
                            child: Text(
                              'Mountain Rescue • Ski Patrol System',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: isDark ? 0 : 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: isDark
                ? Border.all(color: Colors.white.withValues(alpha: 0.1))
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
