import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AdminInjuriesScreen extends StatefulWidget {
  const AdminInjuriesScreen({super.key});

  @override
  State<AdminInjuriesScreen> createState() => _AdminInjuriesScreenState();
}

class _AdminInjuriesScreenState extends State<AdminInjuriesScreen> {
  final _firestore = FirebaseFirestore.instance;

  Future<void> _generateInjuryPDF(Map<String, dynamic> injury) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Padding(
          padding: const pw.EdgeInsets.all(32),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Mountain Rescue - Injury Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.red900,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'Date: ${DateFormat.yMMMd().format((injury['timestamp'] as Timestamp).toDate())}',
              ),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text(
                'Injury Details:',
                style: const pw.TextStyle(fontSize: 18),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Type: ${injury['injuryType'] ?? 'Unknown'}'),
              pw.Text('Severity: ${injury['severity'] ?? 'N/A'}'),
              pw.Text('Location: ${injury['location'] ?? 'N/A'}'),
              pw.Text('Description: ${injury['description'] ?? 'No details'}'),
              pw.SizedBox(height: 20),
              pw.Text(
                'Rescuer Information:',
                style: const pw.TextStyle(fontSize: 18),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Rescuer ID: ${injury['rescuerId'] ?? 'Unknown'}'),
              pw.Text('Rescuer Name: ${injury['rescuerName'] ?? 'Unknown'}'),
            ],
          ),
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Injury Reports'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1A237E), const Color(0xFF0D47A1)]
                : [const Color(0xFF1565C0), const Color(0xFF42A5F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('injuries')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  'No injuries have been reported yet.',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              );
            }

            final injuries = snapshot.data!.docs;

            return ListView.builder(
              itemCount: injuries.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final data = injuries[index].data() as Map<String, dynamic>;
                final date = (data['timestamp'] as Timestamp).toDate();
                final formattedDate = DateFormat(
                  'dd MMM yyyy, HH:mm',
                ).format(date);

                return Card(
                  color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: Colors.red[400],
                      child: const Icon(
                        Icons.medical_services,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      data['injuryType'] ?? 'Unknown injury',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Severity: ${data['severity'] ?? 'N/A'}',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Rescuer: ${data['rescuerName'] ?? 'Unknown'}',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Reported: $formattedDate',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.grey[700],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                      onPressed: () => _generateInjuryPDF(data),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
