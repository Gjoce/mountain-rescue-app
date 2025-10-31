import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/providers/injury_provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class InjuryDetailScreen extends ConsumerWidget {
  final String injuryId;

  const InjuryDetailScreen({super.key, required this.injuryId});

  Future<void> _generatePdf(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(injuryRepositoryProvider);
    final injury = await repo.getInjuryById(injuryId);
    if (injury == null) return;

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Padding(
          padding: const pw.EdgeInsets.all(24),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Injury Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),

              pw.Text('Rescuer: ${injury.rescuerName}'),
              pw.Text('Patient: ${injury.patientName}'),
              pw.Text('Age: ${injury.getPatientAge()}'),
              pw.Text('Ski Slope: ${injury.skiSlope}'),
              pw.Text('Severity: ${injury.severity}'),
              pw.Text('Status: ${injury.status}'),

              pw.SizedBox(height: 12),
              pw.Text(
                'Injuries:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),

              ...injury.injuries.map(
                (inj) => pw.Text('${inj.bodyPart}: ${inj.injuryType}'),
              ),

              pw.SizedBox(height: 12),
              pw.Text(
                'Description:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(injury.description),
              pw.SizedBox(height: 12),

              pw.Text(
                'Reported: ${DateFormat('dd MMM yyyy – HH:mm').format(injury.timestamp)}',
              ),
            ],
          ),
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(injuryRepositoryProvider);

    return FutureBuilder(
      future: repo.getInjuryById(injuryId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final injury = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: Text('${injury.patientName} — ${injury.severity}'),
            backgroundColor: const Color(0xFF1565C0),
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                onPressed: () => _generatePdf(context, ref),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rescuer: ${injury.rescuerName}',
                  style: const TextStyle(fontSize: 18),
                ),
                Text(
                  'Patient: ${injury.patientName}',
                  style: const TextStyle(fontSize: 18),
                ),
                Text(
                  'Age: ${injury.getPatientAge()}',
                  style: const TextStyle(fontSize: 18),
                ),
                Text(
                  'Ski Slope: ${injury.skiSlope}',
                  style: const TextStyle(fontSize: 18),
                ),
                Text(
                  'Severity: ${injury.severity}',
                  style: const TextStyle(fontSize: 18),
                ),
                Text(
                  'Status: ${injury.status}',
                  style: const TextStyle(fontSize: 18),
                ),

                const SizedBox(height: 12),
                Text(
                  'Injuries:',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),
                ...injury.injuries.map(
                  (inj) => Text(
                    '${inj.bodyPart}: ${inj.injuryType}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),

                const SizedBox(height: 12),
                Text(
                  'Description:',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(injury.description, style: const TextStyle(fontSize: 16)),

                const SizedBox(height: 12),
                Text(
                  'Reported: ${DateFormat('dd MMM yyyy – HH:mm').format(injury.timestamp)}',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
