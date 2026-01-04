import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../state/providers/injuries_by_slope_provider.dart';

enum SlopeDifficulty { easy, intermediate, hard }

class SlopeInfo {
  final int id; // stored in DB (int)
  final String label; // what user sees (e.g., 5a / 5b)
  final String name;
  final SlopeDifficulty difficulty;

  const SlopeInfo({
    required this.id,
    required this.label,
    required this.name,
    required this.difficulty,
  });
}

/// Screen can work in two modes:
/// - browse mode: tap slope -> see injuries for that slope
/// - select mode: tap slope -> returns slope selection to previous screen
class SlopesMapScreen extends ConsumerWidget {
  final bool selectMode;
  const SlopesMapScreen({super.key, this.selectMode = false});

  static const String _mapAsset = 'assets/maps/pohorje_slopes.jpg';

  // Difficulty colors from your legend:
  // - EASY: light blue
  // - INTERMEDIATE: red
  // - HARD: black
  static Color _diffColor(SlopeDifficulty d) {
    switch (d) {
      case SlopeDifficulty.easy:
        return const Color(0xFF1DA1F2); // light blue
      case SlopeDifficulty.intermediate:
        return const Color(0xFFE53935); // red
      case SlopeDifficulty.hard:
        return const Color(0xFF000000); // black
    }
  }

  static const List<SlopeInfo> _slopes = [
    SlopeInfo(
      id: 1,
      label: '1',
      name: 'Turistična proga',
      difficulty: SlopeDifficulty.easy,
    ),
    SlopeInfo(
      id: 2,
      label: '2',
      name: 'Andrejeva proga',
      difficulty: SlopeDifficulty.easy,
    ),
    SlopeInfo(
      id: 3,
      label: '3',
      name: 'Bellevue',
      difficulty: SlopeDifficulty.easy,
    ),
    SlopeInfo(
      id: 4,
      label: '4',
      name: 'Mariborski slalom',
      difficulty: SlopeDifficulty.intermediate,
    ),

    SlopeInfo(
      id: 5,
      label: '5a',
      name: 'Miranova proga A',
      difficulty: SlopeDifficulty.intermediate,
    ),
    SlopeInfo(
      id: 6,
      label: '5b',
      name: 'Miranova proga B',
      difficulty: SlopeDifficulty.intermediate,
    ),

    SlopeInfo(
      id: 7,
      label: '6',
      name: 'Gradisova proga',
      difficulty: SlopeDifficulty.intermediate,
    ),
    SlopeInfo(
      id: 8,
      label: '7',
      name: 'FIS slalom',
      difficulty: SlopeDifficulty.hard,
    ),
    SlopeInfo(
      id: 9,
      label: '8',
      name: 'Jonatan',
      difficulty: SlopeDifficulty.hard,
    ),
    SlopeInfo(
      id: 10,
      label: '9',
      name: 'Repova proga',
      difficulty: SlopeDifficulty.easy,
    ),
    SlopeInfo(
      id: 11,
      label: '10',
      name: 'Ravna proga',
      difficulty: SlopeDifficulty.easy,
    ),

    SlopeInfo(
      id: 12,
      label: '11',
      name: 'Markova proga',
      difficulty: SlopeDifficulty.hard,
    ),

    SlopeInfo(
      id: 13,
      label: '12',
      name: 'Marinova proga',
      difficulty: SlopeDifficulty.intermediate,
    ),
    SlopeInfo(
      id: 14,
      label: '13',
      name: 'Glažarska pot',
      difficulty: SlopeDifficulty.easy,
    ),
    SlopeInfo(
      id: 15,
      label: '14',
      name: 'Areška pot',
      difficulty: SlopeDifficulty.easy,
    ),
    SlopeInfo(
      id: 16,
      label: '15',
      name: 'Cvirnova proga',
      difficulty: SlopeDifficulty.easy,
    ),
    SlopeInfo(
      id: 17,
      label: '16',
      name: 'Ruški smuk',
      difficulty: SlopeDifficulty.intermediate,
    ),

    SlopeInfo(
      id: 18,
      label: '17',
      name: 'Šolska proga',
      difficulty: SlopeDifficulty.easy,
    ),

    SlopeInfo(
      id: 19,
      label: '18',
      name: 'Partizanovo',
      difficulty: SlopeDifficulty.intermediate,
    ),
    SlopeInfo(
      id: 20,
      label: '19',
      name: 'Mali X 1',
      difficulty: SlopeDifficulty.easy,
    ),
    SlopeInfo(
      id: 21,
      label: '20',
      name: 'Mali X 2',
      difficulty: SlopeDifficulty.easy,
    ),
    SlopeInfo(
      id: 22,
      label: '21',
      name: 'Povezava Žigart',
      difficulty: SlopeDifficulty.easy,
    ),

    SlopeInfo(
      id: 23,
      label: '22',
      name: 'Žigart',
      difficulty: SlopeDifficulty.easy,
    ),
    SlopeInfo(
      id: 24,
      label: '23',
      name: 'Pisker',
      difficulty: SlopeDifficulty.intermediate,
    ),
    SlopeInfo(
      id: 25,
      label: '24',
      name: 'Cojzerica',
      difficulty: SlopeDifficulty.intermediate,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(selectMode ? 'Select Slope' : 'Pohorje Slopes Map'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 6.0,
                  child: Image.asset(_mapAsset, fit: BoxFit.contain),
                ),
              ),
            ),
            const Divider(height: 1),
            _SlopeGrid(
              slopes: _slopes,
              isDark: isDark,
              diffColor: _diffColor,
              onTapSlope: (s) {
                if (selectMode) {
                  Navigator.pop(context, {
                    'slopeId': s.id,
                    'slopeName': s.name,
                    'slopeLabel': s.label,
                  });
                  return;
                }
                _openSlopeInjuriesSheet(
                  context: context,
                  ref: ref,
                  slopeId: s.id,
                  slopeName: s.name,
                  slopeLabel: s.label,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openSlopeInjuriesSheet({
    required BuildContext context,
    required WidgetRef ref,
    required int slopeId,
    required String slopeName,
    required String slopeLabel,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return _SlopeInjuriesSheet(
          slopeId: slopeId,
          slopeName: slopeName,
          slopeLabel: slopeLabel,
        );
      },
    );
  }
}

class _SlopeGrid extends StatelessWidget {
  final List<SlopeInfo> slopes;
  final bool isDark;
  final Color Function(SlopeDifficulty) diffColor;
  final void Function(SlopeInfo) onTapSlope;

  const _SlopeGrid({
    required this.slopes,
    required this.isDark,
    required this.diffColor,
    required this.onTapSlope,
  });

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final panelHeight = (h * 0.38).clamp(240.0, 360.0);

    return SizedBox(
      height: panelHeight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select slope',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: ListView.separated(
                itemCount: slopes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final s = slopes[index];
                  final c = diffColor(s.difficulty);
                  return _SlopeRowButton(
                    isDark: isDark,
                    label: s.label,
                    name: s.name,
                    color: c,
                    onTap: () => onTapSlope(s),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlopeRowButton extends StatelessWidget {
  final bool isDark;
  final String label;
  final String name;
  final Color color;
  final VoidCallback onTap;

  const _SlopeRowButton({
    required this.isDark,
    required this.label,
    required this.name,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.10);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 44,
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1565C0),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlopeInjuriesSheet extends ConsumerWidget {
  final int slopeId;
  final String slopeName;
  final String slopeLabel;

  const _SlopeInjuriesSheet({
    required this.slopeId,
    required this.slopeName,
    required this.slopeLabel,
  });

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return const Color(0xFFE53935);
      case 'severe':
        return const Color(0xFFF57C00);
      case 'moderate':
        return const Color(0xFFFFA726);
      case 'minor':
        return const Color(0xFF66BB6A);
      default:
        return Colors.grey;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFFA726);
      case 'approved':
        return const Color(0xFF1565C0);
      case 'denied':
        return const Color(0xFFE53935);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final injuriesAsync = ref.watch(injuriesBySlopeProvider(slopeId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Slope $slopeLabel — $slopeName',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            injuriesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Error loading injuries: $e',
                  style: TextStyle(color: Colors.red[300]),
                ),
              ),
              data: (docs) {
                if (docs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No injuries recorded for this slope.',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                  );
                }

                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.65,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final data = docs[index].data();
                      final patient = (data['patientName'] ?? 'Unknown')
                          .toString();
                      final severity = (data['severity'] ?? 'N/A').toString();
                      final status = (data['status'] ?? 'pending').toString();

                      DateTime ts = DateTime.now();
                      final rawTs = data['timestamp'];
                      if (rawTs is Timestamp) ts = rawTs.toDate();

                      return Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2A2A2A)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: isDark
                              ? Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                )
                              : Border.all(
                                  color: Colors.black.withValues(alpha: 0.06),
                                ),
                          boxShadow: isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                        ),
                        child: ListTile(
                          title: Text(
                            patient,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            DateFormat('dd MMM yyyy • HH:mm').format(ts),
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[700],
                            ),
                          ),
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              _Pill(
                                text: severity.toUpperCase(),
                                color: _severityColor(severity),
                              ),
                              _Pill(
                                text: status.toUpperCase(),
                                color: _statusColor(status),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;

  const _Pill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
