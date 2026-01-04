import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../rescuer/injury_detail_screen.dart';

class AdminInjuriesScreen extends StatefulWidget {
  const AdminInjuriesScreen({super.key});

  @override
  State<AdminInjuriesScreen> createState() => _AdminInjuriesScreenState();
}

class _AdminInjuriesScreenState extends State<AdminInjuriesScreen> {
  String _selectedStatus = 'all';
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

  String _safeString(dynamic v, String fallback) {
    if (v == null) return fallback;
    final s = v.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  DateTime _safeTimestamp(dynamic v) {
    if (v is Timestamp) return v.toDate();
    return DateTime.now();
  }

  int _countWhere(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    bool Function(Map<String, dynamic> d) predicate,
  ) {
    var c = 0;
    for (final doc in docs) {
      if (predicate(doc.data())) c++;
    }
    return c;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('injuries')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  backgroundColor: isDark
                      ? const Color(0xFF1E1E1E)
                      : Colors.grey[50],
                  body: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF1565C0),
                      ),
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return _errorState(isDark, snapshot.error.toString());
              }

              final docs = snapshot.data?.docs ?? const [];
              final total = docs.length;
              final approved = _countWhere(
                docs,
                (d) =>
                    _safeString(d['status'], 'pending').toLowerCase() ==
                    'approved',
              );

              // apply filters
              var filtered = docs;

              if (_selectedStatus != 'all') {
                filtered = filtered
                    .where(
                      (doc) =>
                          _safeString(
                            doc.data()['status'],
                            'pending',
                          ).toLowerCase() ==
                          _selectedStatus,
                    )
                    .toList();
              }

              if (_selectedSeverity != 'all') {
                filtered = filtered
                    .where(
                      (doc) =>
                          _safeString(
                            doc.data()['severity'],
                            '',
                          ).toLowerCase() ==
                          _selectedSeverity,
                    )
                    .toList();
              }

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        _buildTopBar(total),
                        const SizedBox(height: 16),
                        _buildStatsMini(total: total, approved: approved),
                        const SizedBox(height: 16),
                        _buildFilterDropdowns(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
                        child: filtered.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: _buildEmptyState(isDark),
                              )
                            : RefreshIndicator(
                                color: const Color(0xFF1565C0),
                                onRefresh: () async {
                                  setState(() {}); // stream refreshes itself
                                },
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  itemCount: filtered.length,
                                  itemBuilder: (context, index) {
                                    final doc = filtered[index];
                                    final data = doc.data();
                                    return _buildInjuryCard(
                                      isDark: isDark,
                                      docId: doc.id,
                                      data: data,
                                    );
                                  },
                                ),
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
      appBar: AppBar(
        title: const Text('All Injury Reports'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }

  Widget _buildTopBar(int total) {
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
          "All Injuries",
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
            '$total total',
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

  Widget _buildStatsMini({required int total, required int approved}) {
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

  Widget _buildFilterDropdowns() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildDropdown(
              value: _selectedStatus,
              items: const [
                DropdownMenuItem(
                  value: 'all',
                  child: Row(
                    children: [
                      Icon(
                        Icons.all_inclusive,
                        size: 18,
                        color: Color(0xFF1565C0),
                      ),
                      SizedBox(width: 8),
                      Text('All Status'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'pending',
                  child: Row(
                    children: [
                      Icon(
                        Icons.pending_actions,
                        size: 18,
                        color: Color(0xFFFFA726),
                      ),
                      SizedBox(width: 8),
                      Text('Pending'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'approved',
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color: Color(0xFF42A5F5),
                      ),
                      SizedBox(width: 8),
                      Text('Approved'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'denied',
                  child: Row(
                    children: [
                      Icon(
                        Icons.cancel,
                        size: 18,
                        color: Color.fromARGB(255, 255, 0, 0),
                      ),
                      SizedBox(width: 8),
                      Text('Denied'),
                    ],
                  ),
                ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _selectedStatus = v);
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
                      Icon(
                        Icons.all_inclusive,
                        size: 18,
                        color: Color(0xFF1565C0),
                      ),
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
                      Icon(
                        Icons.health_and_safety,
                        size: 18,
                        color: Color(0xFF66BB6A),
                      ),
                      SizedBox(width: 8),
                      Text('Minor'),
                    ],
                  ),
                ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _selectedSeverity = v);
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
            _selectedStatus != 'all' || _selectedSeverity != 'all'
                ? Icons.filter_list_off
                : Icons.medical_services_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            _selectedStatus != 'all' || _selectedSeverity != 'all'
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
            _selectedStatus != 'all' || _selectedSeverity != 'all'
                ? 'Try adjusting your filters'
                : 'Injury reports will appear here',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _errorState(bool isDark, String error) {
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                error,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInjuryCard({
    required bool isDark,
    required String docId,
    required Map<String, dynamic> data,
  }) {
    final severity = _safeString(data['severity'], 'unknown');
    final status = _safeString(data['status'], 'pending');
    final patientName = _safeString(data['patientName'], 'Unknown Patient');
    final skiSlope = _safeString(data['skiSlope'], 'Unknown slope');
    final rescuerName = _safeString(data['rescuerName'], 'Unknown rescuer');
    final time = _safeTimestamp(data['timestamp']);

    String summary = '';
    if (data['injuries'] is List && (data['injuries'] as List).isNotEmpty) {
      final first = (data['injuries'] as List).first;
      if (first is Map) {
        summary = _safeString(first['injuryType'], '');
      }
    }
    if (summary.isEmpty) summary = _safeString(data['injuryType'], '');
    if (summary.isEmpty) {
      summary = _safeString(data['description'], 'No details');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.1))
            : null,
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
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => InjuryDetailScreen(injuryId: docId),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _severityColor(severity).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _severityColor(severity),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _severityIcon(severity),
                            size: 16,
                            color: _severityColor(severity),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            severity.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _severityColor(severity),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _statusColor(status),
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
                  patientName,
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
                        summary,
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
                    Expanded(
                      child: Text(
                        skiSlope,
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
                      Icons.person_outline,
                      size: 16,
                      color: isDark ? Colors.purple[200] : Colors.purple,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        rescuerName,
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
                      Icons.access_time,
                      size: 16,
                      color: isDark ? Colors.orange[200] : Colors.orangeAccent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd MMM yyyy • HH:mm').format(time),
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
