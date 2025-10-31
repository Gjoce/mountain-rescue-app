import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../state/providers/injury_provider.dart';
import '../../state/providers/auth_provider.dart';
import 'injury_detail_screen.dart';

class PastInjuriesScreen extends ConsumerWidget {
  const PastInjuriesScreen({super.key});

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
          data: (list) => Scaffold(
            appBar: AppBar(
              title: const Text('Past Injuries'),
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
            ),
            body: list.isEmpty
                ? const Center(child: Text('No injuries recorded yet.'))
                : ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, index) {
                final injury = list[index];
                return Card(
                  margin: const EdgeInsets.all(12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: Icon(
                      Icons.medical_services,
                      color: injury.severity == 'Critical'
                          ? Colors.red
                          : Colors.orange,
                    ),
                    title: Text(injury.injuryType),
                    subtitle: Text(
                      '${DateFormat('dd MMM yyyy – HH:mm').format(injury.timestamp)}\n${injury.location}',
                    ),
                    isThreeLine: true,
                    trailing: Icon(Icons.arrow_forward_ios,
                        color: Colors.grey[600], size: 18),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => InjuryDetailScreen(injuryId: injury.id),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator())),
          error: (err, _) => Scaffold(body: Center(child: Text('Error: $err'))),
        );
      },
      loading: () =>
      const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }
}
