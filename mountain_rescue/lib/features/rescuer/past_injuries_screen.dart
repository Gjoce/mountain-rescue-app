import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../state/providers/injury_provider.dart';
import '../../state/providers/auth_provider.dart';
import 'injury_detail_screen.dart';

class PastInjuriesScreen extends ConsumerWidget {
  const PastInjuriesScreen({super.key});

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'moderate':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(firebaseAuthStateProvider);
    return authState.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(body: Center(child: Text('Not logged in')));
        }

        final injuries = ref.watch(rescuerInjuriesProvider(user.uid));

        return injuries.when(
          data: (injuryList) => Scaffold(
            appBar: AppBar(
              title: const Text('Past Injuries'),
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
            ),
            body: injuryList.isEmpty
                ? const Center(child: Text('No injuries recorded yet.'))
                : ListView.builder(
                    itemCount: injuryList.length,
                    itemBuilder: (context, index) {
                      final injury = injuryList[index];
                      return Card(
                        margin: const EdgeInsets.all(12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.medical_services,
                            color: _severityColor(injury.severity),
                          ),
                          title: Text(
                            injury.injurySummary, // ✅ uses computed getter
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            '${DateFormat('dd MMM yyyy – HH:mm').format(injury.timestamp)}\n'
                            'Slope: ${injury.skiSlope}',
                          ),
                          isThreeLine: true,
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.grey[600],
                            size: 18,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    InjuryDetailScreen(injuryId: injury.id),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (err, _) => Scaffold(body: Center(child: Text('Error: $err'))),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }
}
