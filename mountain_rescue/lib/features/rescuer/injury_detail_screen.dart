import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/providers/injury_provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class InjuryDetailScreen extends ConsumerStatefulWidget {
  final String injuryId;

  const InjuryDetailScreen({super.key, required this.injuryId});

  @override
  ConsumerState<InjuryDetailScreen> createState() => _InjuryDetailScreenState();
}

class _InjuryDetailScreenState extends ConsumerState<InjuryDetailScreen> {
  bool _savingStatus = false;

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return const Color(0xFFE53935);
      case 'severe':
        return const Color(0xFFF57C00);
      case 'moderate':
        return const Color(0xFFFDD835);
      case 'minor':
        return const Color(0xFF66BB6A);
      default:
        return Colors.grey;
    }
  }

  IconData _severityIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Icons.emergency;
      case 'severe':
        return Icons.warning;
      case 'moderate':
        return Icons.healing;
      case 'minor':
        return Icons.health_and_safety;
      default:
        return Icons.medical_services;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFFA726);
      case 'approved':
        return const Color(0xFF42A5F5);
      case 'denied':
        return const Color.fromARGB(255, 255, 0, 0);
      default:
        return Colors.grey;
    }
  }

  Future<bool> _isAdmin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    final snap =
    await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = snap.data();
    return (data?['role']?.toString() == 'admin');
  }

  Future<void> _updateStatus(String injuryId, String newStatus) async {
    setState(() => _savingStatus = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      await FirebaseFirestore.instance.collection('injuries').doc(injuryId).update({
        'status': newStatus,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
        'statusUpdatedBy': uid,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to ${newStatus.toUpperCase()}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    } finally {
      if (mounted) setState(() => _savingStatus = false);
    }
  }

  Future<void> _generatePdf(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(injuryRepositoryProvider);
    final injury = await repo.getInjuryById(widget.injuryId);
    if (injury == null) return;

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Padding(
          padding: const pw.EdgeInsets.all(32),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue800,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'INJURY REPORT',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.Text(
                      'ID: ${injury.id.substring(0, 8)}',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              pw.Text(
                'PATIENT INFORMATION',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.Divider(thickness: 2, color: PdfColors.blue800),
              pw.SizedBox(height: 8),
              _buildPdfInfoRow('Name', injury.patientName),
              _buildPdfInfoRow('Age', '${injury.getPatientAge()} years'),
              _buildPdfInfoRow(
                'Date of Birth',
                DateFormat('dd MMM yyyy').format(injury.patientBirthDate),
              ),
              pw.SizedBox(height: 16),

              pw.Text(
                'INCIDENT INFORMATION',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.Divider(thickness: 2, color: PdfColors.blue800),
              pw.SizedBox(height: 8),

              // ✅ UPDATED: slopeName instead of skiSlope
              _buildPdfInfoRow(
                'Location',
                injury.slopeName.isNotEmpty
                    ? '${injury.slopeName} (ID: ${injury.slopeId})'
                    : 'Slope ID: ${injury.slopeId}',
              ),

              _buildPdfInfoRow('Severity', injury.severity.toUpperCase()),
              _buildPdfInfoRow('Status', injury.status.toUpperCase()),
              _buildPdfInfoRow(
                'Date & Time',
                DateFormat('dd MMM yyyy – HH:mm').format(injury.timestamp),
              ),
              pw.SizedBox(height: 16),

              pw.Text(
                'INJURY DETAILS',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.Divider(thickness: 2, color: PdfColors.blue800),
              pw.SizedBox(height: 8),
              ...injury.injuries.map(
                    (inj) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Row(
                    children: [
                      pw.Container(
                        width: 6,
                        height: 6,
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.blue800,
                          shape: pw.BoxShape.circle,
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Text(
                        '${inj.bodyPart}: ',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(inj.injuryType),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(height: 16),

              pw.Text(
                'ADDITIONAL COMMENTS',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.Divider(thickness: 2, color: PdfColors.blue800),
              pw.SizedBox(height: 8),
              pw.Text(injury.description),
              pw.SizedBox(height: 16),

              pw.Text(
                'RESCUER INFORMATION',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.Divider(thickness: 2, color: PdfColors.blue800),
              pw.SizedBox(height: 8),
              _buildPdfInfoRow('Name', injury.rescuerName),
              _buildPdfInfoRow('Email', injury.rescuerEmail),

              pw.Spacer(),

              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Generated: ${DateFormat('dd MMM yyyy – HH:mm').format(DateTime.now())}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey,
                    ),
                  ),
                  pw.Text(
                    'Mountain Rescue System',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  pw.Widget _buildPdfInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
            ),
          ),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final repo = ref.watch(injuryRepositoryProvider);

    return FutureBuilder(
      future: repo.getInjuryById(widget.injuryId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
            appBar: AppBar(
              title: const Text('Injury Details'),
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
            ),
            body: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
            appBar: AppBar(
              title: const Text('Injury Details'),
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  const Text(
                    'Injury not found',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        }

        final injury = snapshot.data!;
        final currentStatus =
        (injury.status.isEmpty ? 'pending' : injury.status).toLowerCase();

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
          appBar: AppBar(
            title: Text(injury.patientName),
            backgroundColor: const Color(0xFF1565C0),
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                tooltip: 'Export to PDF',
                onPressed: () => _generatePdf(context, ref),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1565C0).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _severityIcon(injury.severity),
                                  size: 20,
                                  color: _severityColor(injury.severity),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  injury.severity.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: _severityColor(injury.severity),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  currentStatus == 'pending'
                                      ? Icons.pending_actions
                                      : currentStatus == 'approved'
                                      ? Icons.check_circle_outline
                                      : Icons.cancel,
                                  size: 20,
                                  color: _statusColor(currentStatus),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  currentStatus.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: _statusColor(currentStatus),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Report ID: ${injury.id.substring(0, 8).toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      FutureBuilder<bool>(
                        future: _isAdmin(),
                        builder: (context, adminSnap) {
                          final isAdmin = adminSnap.data == true;
                          if (!isAdmin) return const SizedBox.shrink();

                          return _buildSection(
                            isDark: isDark,
                            icon: Icons.verified_user,
                            title: 'Admin Status',
                            children: [
                              _StatusEditor(
                                isDark: isDark,
                                currentStatus: currentStatus,
                                saving: _savingStatus,
                                onSave: (newStatus) =>
                                    _updateStatus(injury.id, newStatus),
                                statusColor: _statusColor,
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      _buildSection(
                        isDark: isDark,
                        icon: Icons.person,
                        title: 'Patient Information',
                        children: [
                          _buildInfoRow(
                            Icons.badge,
                            'Full Name',
                            injury.patientName,
                            isDark,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.cake,
                            'Date of Birth',
                            DateFormat('dd MMM yyyy')
                                .format(injury.patientBirthDate),
                            isDark,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.numbers,
                            'Age at Incident',
                            '${injury.getPatientAge()} years old',
                            isDark,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      _buildSection(
                        isDark: isDark,
                        icon: Icons.location_on,
                        title: 'Incident Information',
                        children: [
                          // ✅ UPDATED: show slopeName + slopeId
                          _buildInfoRow(
                            Icons.landscape,
                            'Location',
                            injury.slopeName.isNotEmpty
                                ? '${injury.slopeName} (ID: ${injury.slopeId})'
                                : 'Slope ID: ${injury.slopeId}',
                            isDark,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.access_time,
                            'Date & Time',
                            DateFormat('dd MMM yyyy – HH:mm')
                                .format(injury.timestamp),
                            isDark,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      _buildSection(
                        isDark: isDark,
                        icon: Icons.medical_information,
                        title: 'Injury Details',
                        children: [
                          ...injury.injuries.asMap().entries.map((entry) {
                            final index = entry.key;
                            final inj = entry.value;
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index < injury.injuries.length - 1
                                    ? 12
                                    : 0,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE53935)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFE53935)
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE53935)
                                            .withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.local_hospital,
                                        size: 20,
                                        color: Color(0xFFE53935),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            inj.bodyPart,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.grey[900],
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            inj.injuryType,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: isDark
                                                  ? Colors.grey[400]
                                                  : Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),

                      const SizedBox(height: 16),

                      _buildSection(
                        isDark: isDark,
                        icon: Icons.description,
                        title: 'Additional Comments',
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF3A3A3A)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Text(
                              injury.description,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: isDark
                                    ? Colors.grey[300]
                                    : Colors.grey[800],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      _buildSection(
                        isDark: isDark,
                        icon: Icons.shield,
                        title: 'Rescuer Information',
                        children: [
                          _buildInfoRow(
                            Icons.person_outline,
                            'Name',
                            injury.rescuerName,
                            isDark,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.email_outlined,
                            'Email',
                            injury.rescuerEmail,
                            isDark,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection({
    required bool isDark,
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
        isDark ? Border.all(color: Colors.white.withValues(alpha: 0.1)) : null,
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
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF1565C0), size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.grey[900],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusEditor extends StatefulWidget {
  final bool isDark;
  final String currentStatus;
  final bool saving;
  final Future<void> Function(String newStatus) onSave;
  final Color Function(String) statusColor;

  const _StatusEditor({
    required this.isDark,
    required this.currentStatus,
    required this.saving,
    required this.onSave,
    required this.statusColor,
  });

  @override
  State<_StatusEditor> createState() => _StatusEditorState();
}

class _StatusEditorState extends State<_StatusEditor> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentStatus;
  }

  @override
  void didUpdateWidget(covariant _StatusEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStatus != widget.currentStatus) {
      _selected = widget.currentStatus;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF3A3A3A) : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey[300]!,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selected,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'pending', child: Text('PENDING')),
                DropdownMenuItem(value: 'approved', child: Text('APPROVED')),
                DropdownMenuItem(value: 'denied', child: Text('DENIED')),
              ],
              onChanged: widget.saving
                  ? null
                  : (v) {
                if (v == null) return;
                setState(() => _selected = v);
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            onPressed: widget.saving ? null : () => widget.onSave(_selected),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.statusColor(_selected),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: widget.saving
                ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : Text('Save Status: ${_selected.toUpperCase()}'),
          ),
        ),
      ],
    );
  }
}
