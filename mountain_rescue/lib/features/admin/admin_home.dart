import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mountain_rescue/state/providers/auth_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'admin_injuries_screen.dart';
import 'admin_settings_screen.dart';
import 'add_rescuer_screen.dart';
import 'manage_rescuers_screen.dart';
import 'slopes_map_screen.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authRepositoryProvider).signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  DateTime _startOfWeek(DateTime now) {
    final d = DateTime(now.year, now.month, now.day);
    return d.subtract(Duration(days: d.weekday - DateTime.monday));
  }

  DateTime _startOfMonth(DateTime now) {
    return DateTime(now.year, now.month, 1);
  }

  Future<Map<String, String>> _fetchOverviewCounts() async {
    final fs = FirebaseFirestore.instance;
    final now = DateTime.now();

    final weekStart = _startOfWeek(now);
    final monthStart = _startOfMonth(now);

    final totalInjuriesFuture = fs.collection('injuries').count().get();

    // ✅ FIX: count ONLY active rescuers
    final activeRescuersFuture = fs
        .collection('users')
        .where('role', isEqualTo: 'rescuer')
        .where('isActive', isEqualTo: true)
        .count()
        .get();

    final weekInjuriesFuture = fs
        .collection('injuries')
        .where(
      'timestamp',
      isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart),
    )
        .count()
        .get();

    final monthInjuriesFuture = fs
        .collection('injuries')
        .where(
      'timestamp',
      isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart),
    )
        .count()
        .get();

    final results = await Future.wait([
      totalInjuriesFuture,
      activeRescuersFuture,
      weekInjuriesFuture,
      monthInjuriesFuture,
    ]);

    return {
      'totalInjuries': results[0].count.toString(),
      'activeRescuers': results[1].count.toString(),
      'thisWeek': results[2].count.toString(),
      'thisMonth': results[3].count.toString(),
    };
  }

  Future<Uint8List> _buildInjuryPdfBytes({
    required Map<String, dynamic> data,
    required String docId,
  }) async {
    final pdf = pw.Document();

    DateTime? ts;
    final rawTs = data['timestamp'];
    if (rawTs is Timestamp) ts = rawTs.toDate();
    ts ??= DateTime.now();

    final patientName = (data['patientName'] ?? 'Unknown').toString();
    final rescuerName = (data['rescuerName'] ?? 'Unknown').toString();
    final rescuerEmail = (data['rescuerEmail'] ?? '').toString();
    final severity = (data['severity'] ?? 'N/A').toString();
    final slope = (data['skiSlope'] ?? 'N/A').toString();
    final status = (data['status'] ?? 'N/A').toString();
    final description = (data['description'] ?? '').toString();

    final injuries =
    (data['injuries'] is List) ? (data['injuries'] as List) : const [];

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Mountain Rescue - Injury Report',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.red900,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text('Report ID: $docId'),
              pw.Text(
                'Created: ${DateFormat('dd MMM yyyy, HH:mm').format(ts!)}',
              ),
              pw.Divider(),
              pw.SizedBox(height: 12),
              pw.Text(
                'Patient',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text('Name: $patientName'),
              pw.SizedBox(height: 12),
              pw.Text(
                'Incident',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text('Severity: $severity'),
              pw.Text('Status: $status'),
              pw.Text('Ski slope: $slope'),
              if (description.isNotEmpty) pw.Text('Description: $description'),
              pw.SizedBox(height: 12),
              pw.Text(
                'Injuries',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              if (injuries.isEmpty)
                pw.Text('No injury details recorded.')
              else
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(2),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey200,
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Body Part',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Injury Type',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    ...injuries.map((row) {
                      final m = (row is Map) ? row : {};
                      final bodyPart = (m['bodyPart'] ?? 'N/A').toString();
                      final injuryType = (m['injuryType'] ?? 'N/A').toString();
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(bodyPart),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(injuryType),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              pw.SizedBox(height: 14),
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Text(
                'Rescuer',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text('Name: $rescuerName'),
              if (rescuerEmail.isNotEmpty) pw.Text('Email: $rescuerEmail'),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<void> _exportAllInjuriesAsZip(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Exporting Reports'),
        content: Row(
          children: const [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 16),
            Expanded(child: Text('Generating PDFs and preparing ZIP...')),
          ],
        ),
      ),
    );

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('injuries')
          .orderBy('timestamp', descending: true)
          .get();

      if (snapshot.docs.isEmpty) {
        if (context.mounted) Navigator.pop(context);
        messenger.showSnackBar(
          const SnackBar(content: Text('No injuries found to export.')),
        );
        return;
      }

      final archive = Archive();
      final dateStamp = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final docId = doc.id;

        final pdfBytes = await _buildInjuryPdfBytes(data: data, docId: docId);

        final ts = (data['timestamp'] is Timestamp)
            ? (data['timestamp'] as Timestamp).toDate()
            : DateTime.now();

        final safeDate = DateFormat('yyyyMMdd_HHmm').format(ts);
        final rescuerName = (data['rescuerName'] ?? 'Rescuer').toString();
        final safeRescuer = rescuerName
            .replaceAll(RegExp(r'[^\w\s-]'), '')
            .replaceAll(' ', '_');

        final filename = 'injury_${safeDate}_${safeRescuer}_$docId.pdf';

        archive.addFile(ArchiveFile(filename, pdfBytes.length, pdfBytes));
      }

      final zippedBytes = ZipEncoder().encode(archive);
      if (zippedBytes == null) {
        throw Exception('Failed to create ZIP.');
      }

      final zipFile = XFile.fromData(
        Uint8List.fromList(zippedBytes),
        name: 'mountain_rescue_reports_$dateStamp.zip',
        mimeType: 'application/zip',
      );

      if (context.mounted) Navigator.pop(context);

      await Share.shareXFiles(
        [zipFile],
        text: 'Mountain Rescue reports export ($dateStamp)',
      );

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Export prepared. Choose where to save it.'),
        ),
      );
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => const Center(
              child: Text(
                'Error loading user',
                style: TextStyle(color: Colors.white),
              ),
            ),
            data: (user) {
              final adminName = user?.name ?? "Administrator";

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Admin Dashboard',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  adminName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.admin_panel_settings,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.shield,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'System Administrator',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'ADMIN',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                        isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Overview',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 16),
                            FutureBuilder<Map<String, String>>(
                              future: _fetchOverviewCounts(),
                              builder: (context, snap) {
                                final counts = snap.data;

                                final total =
                                    counts?['totalInjuries'] ?? '—';
                                final rescuers =
                                    counts?['activeRescuers'] ?? '—';
                                final week = counts?['thisWeek'] ?? '—';
                                final month = counts?['thisMonth'] ?? '—';

                                return GridView.count(
                                  shrinkWrap: true,
                                  physics:
                                  const NeverScrollableScrollPhysics(),
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 1.3,
                                  children: [
                                    _StatCard(
                                      icon: Icons.local_hospital,
                                      title: 'Total Injuries',
                                      value: total,
                                      color: const Color(0xFFE53935),
                                      isDark: isDark,
                                    ),
                                    _StatCard(
                                      icon: Icons.people,
                                      title: 'Active Rescuers',
                                      value: rescuers,
                                      color: const Color(0xFF43A047),
                                      isDark: isDark,
                                    ),
                                    _StatCard(
                                      icon: Icons.today,
                                      title: 'This Week',
                                      value: week,
                                      color: const Color(0xFFFB8C00),
                                      isDark: isDark,
                                    ),
                                    _StatCard(
                                      icon: Icons.trending_up,
                                      title: 'This Month',
                                      value: month,
                                      color: const Color(0xFF1565C0),
                                      isDark: isDark,
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 32),
                            Text(
                              'Management',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _ActionButton(
                              icon: Icons.map,
                              title: 'Injury Map',
                              subtitle:
                              'View all incidents on interactive map',
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF1565C0),
                                  Color(0xFF0D47A1),
                                ],
                              ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const SlopesMapScreen()),
                                  );
                                },
                            ),
                            const SizedBox(height: 12),
                            _ActionButton(
                              icon: Icons.list_alt,
                              title: 'View All Injuries',
                              subtitle: 'Browse and manage injury reports',
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF5E35B1),
                                  Color(0xFF4527A0),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                    const AdminInjuriesScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            _ActionButton(
                              icon: Icons.person_add,
                              title: 'Add New Rescuer',
                              subtitle: 'Register new ski patrol member',
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF43A047),
                                  Color(0xFF388E3C),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                    const AddRescuerScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            _ActionButton(
                              icon: Icons.people_outline,
                              title: 'Manage Rescuers',
                              subtitle: 'View and edit rescuer profiles',
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFFB8C00),
                                  Color(0xFFF57C00),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                    const ManageRescuersScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 32),
                            Row(
                              children: [
                                Expanded(
                                  child: _SecondaryActionCard(
                                    icon: Icons.file_download,
                                    title: 'Export Reports',
                                    color: const Color(0xFF00897B),
                                    isDark: isDark,
                                    onTap: () =>
                                        _exportAllInjuriesAsZip(context),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _SecondaryActionCard(
                                    icon: Icons.settings,
                                    title: 'Settings',
                                    color: const Color(0xFF5E35B1),
                                    isDark: isDark,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                          const AdminSettingsScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  _showLogoutDialog(context, ref),
                              icon: const Icon(Icons.logout),
                              label: const Text('Log Out'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: isDark
                                    ? Colors.red[300]
                                    : Colors.red[700],
                                side: BorderSide(
                                  color: isDark
                                      ? Colors.red[300]!
                                      : Colors.red[700]!,
                                  width: 2,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: Text(
                                'Mountain Rescue • Admin Panel',
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.1))
            : null,
        boxShadow: isDark
            ? null
            : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey[800],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _SecondaryActionCard({
    required this.icon,
    required this.title,
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: isDark
                ? Border.all(color: Colors.white.withValues(alpha: 0.1))
                : null,
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
