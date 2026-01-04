import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../state/providers/injury_provider.dart';
import '../../state/providers/auth_provider.dart';
import 'injury_detail_screen.dart';

class PastInjuriesScreen extends ConsumerStatefulWidget {
  const PastInjuriesScreen({super.key});

  @override
  ConsumerState<PastInjuriesScreen> createState() => _PastInjuriesScreenState();
}

class _PastInjuriesScreenState extends ConsumerState<PastInjuriesScreen> {
  String _selectedFilter = 'all';
  String _selectedSeverity = 'all';

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
        return const Color(0xFF1565C0);
      case 'denied':
        return const Color.fromARGB(255, 255, 0, 0);
      default:
        return Colors.grey;
    }
  }

  /// ✅ FIX: your Injury model uses slopeName/slopeId, not skiSlope
  String _slopeText(dynamic injury) {
    try {
      final name = (injury.slopeName ?? '').toString().trim();
      if (name.isNotEmpty) return name;

      final id = injury.slopeId;
      if (id != null) return 'Slope #$id';

      return 'Unknown slope';
    } catch (_) {
      return 'Unknown slope';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(firebaseAuthStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Not logged in',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        }

        final injuries = ref.watch(rescuerInjuriesProvider(user.uid));

        return injuries.when(
          data: (injuryList) {
            var filteredList = injuryList;
            if (_selectedFilter != 'all') {
              filteredList = filteredList
                  .where((injury) => injury.status == _selectedFilter)
                  .toList();
            }
            if (_selectedSeverity != 'all') {
              filteredList = filteredList
                  .where((injury) => injury.severity == _selectedSeverity)
                  .toList();
            }

            return Scaffold(
              body: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            _buildTopBar(injuryList),
                            const SizedBox(height: 16),
                            _buildStatsMini(injuryList),
                            const SizedBox(height: 16),
                            _buildFilterDropdowns(isDark),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E1E1E)
                                : Colors.white,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(30),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(30),
                            ),
                            child: filteredList.isEmpty
                                ? Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: _buildEmptyState(isDark),
                            )
                                : RefreshIndicator(
                              color: const Color(0xFF1565C0),
                              onRefresh: () async {
                                ref.invalidate(
                                  rescuerInjuriesProvider(user.uid),
                                );
                              },
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                itemCount: filteredList.length,
                                itemBuilder: (context, index) {
                                  final injury = filteredList[index];
                                  return _buildInjuryCard(injury, isDark);
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          loading: () => Scaffold(
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
            body: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
              ),
            ),
          ),
          error: (err, _) => Scaffold(
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading injuries',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    err.toString(),
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => Scaffold(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
          ),
        ),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
        body: Center(child: Text('Authentication Error: $err')),
      ),
    );
  }

  Widget _buildTopBar(List<dynamic> injuryList) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 16),
        const Text(
          "Past Injuries",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${injuryList.length} total',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsMini(List<dynamic> injuries) {
    final total = injuries.length;
    final approved = injuries.where((i) => i.status == 'approved').length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _miniStatCard("All", total.toString(), Icons.apps),
          const SizedBox(width: 10),
          _miniStatCard("Approved", approved.toString(), Icons.check_circle),
        ],
      ),
    );
  }

  Widget _miniStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdowns(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildDropdown(
              value: _selectedFilter,
              items: const [
                DropdownMenuItem(
                  value: 'all',
                  child: Row(
                    children: [
                      Icon(Icons.all_inclusive, size: 18, color: Color(0xFF1565C0)),
                      SizedBox(width: 8),
                      Text('All Status'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'pending',
                  child: Row(
                    children: [
                      Icon(Icons.pending_actions, size: 18, color: Color(0xFFFFA726)),
                      SizedBox(width: 8),
                      Text('Pending'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'approved',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, size: 18, color: Color(0xFF42A5F5)),
                      SizedBox(width: 8),
                      Text('Approved'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'denied',
                  child: Row(
                    children: [
                      Icon(Icons.cancel, size: 18, color: Color.fromARGB(255, 255, 0, 0)),
                      SizedBox(width: 8),
                      Text('Denied'),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _selectedFilter = value);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildDropdown(
              value: _selectedSeverity,
              items: const [
                DropdownMenuItem(
                  value: 'all',
                  child: Row(
                    children: [
                      Icon(Icons.all_inclusive, size: 18, color: Color(0xFF1565C0)),
                      SizedBox(width: 8),
                      Text('All Severity'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'critical',
                  child: Row(
                    children: [
                      Icon(Icons.emergency, size: 18, color: Color(0xFFE53935)),
                      SizedBox(width: 8),
                      Text('Critical'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'severe',
                  child: Row(
                    children: [
                      Icon(Icons.warning, size: 18, color: Color(0xFFF57C00)),
                      SizedBox(width: 8),
                      Text('Severe'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'moderate',
                  child: Row(
                    children: [
                      Icon(Icons.healing, size: 18, color: Color(0xFFFDD835)),
                      SizedBox(width: 8),
                      Text('Moderate'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'minor',
                  child: Row(
                    children: [
                      Icon(Icons.health_and_safety, size: 18, color: Color(0xFF66BB6A)),
                      SizedBox(width: 8),
                      Text('Minor'),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _selectedSeverity = value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: Colors.white,
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1565C0)),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _selectedFilter != 'all' || _selectedSeverity != 'all'
                ? Icons.filter_list_off
                : Icons.medical_services_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            _selectedFilter != 'all' || _selectedSeverity != 'all'
                ? 'No injuries match filters'
                : 'No injuries recorded yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter != 'all' || _selectedSeverity != 'all'
                ? 'Try adjusting your filters'
                : 'Injury reports will appear here',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildInjuryCard(dynamic injury, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: Colors.white.withValues(alpha: 0.1)) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => InjuryDetailScreen(injuryId: injury.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _severityColor(injury.severity).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _severityColor(injury.severity),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _severityIcon(injury.severity),
                            size: 16,
                            color: _severityColor(injury.severity),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            injury.severity.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _severityColor(injury.severity),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _statusColor(injury.status).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        injury.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _statusColor(injury.status),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  injury.patientName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.medical_information,
                      size: 16,
                      color: isDark ? Colors.blue[200] : Colors.blueAccent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        injury.injurySummary,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.landscape,
                      size: 16,
                      color: isDark ? Colors.green[200] : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _slopeText(injury), // ✅ FIX HERE
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: isDark ? Colors.orange[200] : Colors.orangeAccent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd MMM yyyy • HH:mm').format(injury.timestamp),
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                if (injury.injuryCount > 0) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ...injury.affectedBodyParts.take(3).map(
                            (part) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565C0).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF1565C0).withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            part,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF1565C0),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      if (injury.injuryCount > 3)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '+${injury.injuryCount - 3} more',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
