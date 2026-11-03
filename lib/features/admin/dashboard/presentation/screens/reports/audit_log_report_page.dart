import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zim_herbs_repo/core/components/app_page_header.dart';
import 'package:zim_herbs_repo/core/utils/responsive.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';
import 'report_export_helper.dart';

enum _AuditDomainFilter { all, herbs, remedies, ailments }

class _AuditEntry {
  final _AuditDomainFilter domain;
  final String domainLabel;
  final String action;
  final String recordTitle;
  final String actor;
  final DateTime timestamp;
  final Color color;
  final IconData icon;

  const _AuditEntry({
    required this.domain,
    required this.domainLabel,
    required this.action,
    required this.recordTitle,
    required this.actor,
    required this.timestamp,
    required this.color,
    required this.icon,
  });
}

/// Dedicated full-page report for viewing and exporting the CRUD & Moderation Audit Log.
class AuditLogReportPage extends StatefulWidget {
  final VoidCallback? onBack;

  const AuditLogReportPage({super.key, this.onBack});

  @override
  State<AuditLogReportPage> createState() => _AuditLogReportPageState();
}

class _AuditLogReportPageState extends State<AuditLogReportPage> {
  final SupabaseClient _client = Supabase.instance.client;

  bool _isLoading = true;
  bool _isExporting = false;
  _AuditDomainFilter _filter = _AuditDomainFilter.all;
  List<_AuditEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadAuditLog();
  }

  Future<void> _loadAuditLog() async {
    setState(() => _isLoading = true);
    try {
      List<Map<String, dynamic>> ailmentsData = [];
      try {
        final res = await _client
            .from('ailments')
            .select()
            .order('created_at', ascending: false);
        ailmentsData = List<Map<String, dynamic>>.from(res);
      } catch (_) {
        try {
          final res = await _client
              .from('conditions')
              .select()
              .order('created_at', ascending: false);
          ailmentsData = List<Map<String, dynamic>>.from(res);
        } catch (_) {}
      }

      final results = await Future.wait([
        _client
            .from('herbs')
            .select()
            .order('created_at', ascending: false)
            .then((v) => List<Map<String, dynamic>>.from(v))
            .catchError((_) => <Map<String, dynamic>>[]),
        _client
            .from('remedies')
            .select()
            .order('created_at', ascending: false)
            .then((v) => List<Map<String, dynamic>>.from(v))
            .catchError((_) => <Map<String, dynamic>>[]),
        _client
            .from('user_profiles')
            .select()
            .then((v) => List<Map<String, dynamic>>.from(v))
            .catchError((_) => <Map<String, dynamic>>[]),
      ]);

      final herbsData = results[0];
      final remediesData = results[1];
      final usersData = results[2];

      final userLookup = <String, String>{};
      for (final u in usersData) {
        final id = u['id']?.toString();
        if (id != null && id.isNotEmpty) {
          final name = (u['full_name'] ?? u['name'] ?? u['email'] ?? id)
              .toString()
              .trim();
          userLookup[id] = name.isEmpty ? id : name;
        }
      }

      String resolveActor(dynamic rawId) {
        if (rawId == null) return 'System / Unknown';
        final id = rawId.toString();
        if (id.isEmpty) return 'System / Unknown';
        return userLookup[id] ??
            (id.length > 8 ? 'User (${id.substring(0, 8)}…)' : id);
      }

      final logs = <_AuditEntry>[];

      for (final h in herbsData) {
        final title = (h['name_en'] ?? 'Unnamed Herb').toString();
        final isApproved = h['is_approved'] == true;
        final createdAt = DateTime.tryParse(h['created_at']?.toString() ?? '');
        final verifiedAt =
            DateTime.tryParse(h['verified_at']?.toString() ?? '');

        if (verifiedAt != null && isApproved) {
          logs.add(
            _AuditEntry(
              domain: _AuditDomainFilter.herbs,
              domainLabel: 'Herb',
              action: 'Verified & Published',
              recordTitle: title,
              actor: resolveActor(h['verified_by'] ?? h['created_by']),
              timestamp: verifiedAt,
              color: const Color(0xFF15803D),
              icon: Icons.verified_rounded,
            ),
          );
        } else if (createdAt != null) {
          logs.add(
            _AuditEntry(
              domain: _AuditDomainFilter.herbs,
              domainLabel: 'Herb',
              action:
                  isApproved ? 'Created (Published)' : 'Submitted for Review',
              recordTitle: title,
              actor: resolveActor(h['created_by']),
              timestamp: createdAt,
              color: const Color(0xFF22633C),
              icon: Icons.local_florist_rounded,
            ),
          );
        }
      }

      for (final r in remediesData) {
        final title = (r['name'] ?? 'Unnamed Remedy').toString();
        final isApproved = r['is_approved'] == true;
        final createdAt = DateTime.tryParse(r['created_at']?.toString() ?? '');
        final approvedAt =
            DateTime.tryParse(r['approved_at']?.toString() ?? '');

        if (approvedAt != null && isApproved) {
          logs.add(
            _AuditEntry(
              domain: _AuditDomainFilter.remedies,
              domainLabel: 'Remedy',
              action: 'Approved & Published',
              recordTitle: title,
              actor: resolveActor(r['approved_by'] ?? r['created_by']),
              timestamp: approvedAt,
              color: const Color(0xFF295CA2),
              icon: Icons.healing_rounded,
            ),
          );
        } else if (createdAt != null) {
          logs.add(
            _AuditEntry(
              domain: _AuditDomainFilter.remedies,
              domainLabel: 'Remedy',
              action:
                  isApproved ? 'Created (Published)' : 'Submitted for Review',
              recordTitle: title,
              actor: resolveActor(r['created_by']),
              timestamp: createdAt,
              color: const Color(0xFF295CA2),
              icon: Icons.healing_outlined,
            ),
          );
        }
      }

      for (final a in ailmentsData) {
        final title = (a['name'] ?? 'Unnamed Ailment').toString();
        final createdAt = DateTime.tryParse(a['created_at']?.toString() ?? '');
        if (createdAt != null) {
          logs.add(
            _AuditEntry(
              domain: _AuditDomainFilter.ailments,
              domainLabel: 'Ailment',
              action: 'Registered Ailment',
              recordTitle: title,
              actor: resolveActor(a['created_by']),
              timestamp: createdAt,
              color: const Color(0xFF106F74),
              icon: Icons.monitor_heart_outlined,
            ),
          );
        }
      }

      logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (mounted) {
        setState(() {
          _entries = logs;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  static String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final y = local.year;
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  List<List<String>> _buildMatrix(List<_AuditEntry> items) {
    return [
      ['Timestamp', 'Domain', 'Record Name', 'Action', 'Actor'],
      ...items.map(
        (e) => [
          _formatDate(e.timestamp),
          e.domainLabel,
          e.recordTitle,
          e.action,
          e.actor,
        ],
      ),
    ];
  }

  Future<void> _export(List<_AuditEntry> items, {required bool asExcel}) async {
    setState(() => _isExporting = true);
    try {
      await ReportExportHelper.exportMatrix(
        context: context,
        matrix: _buildMatrix(items),
        baseFileName: 'zim_herbs_audit_log_report',
        sheetName: 'Audit Log',
        asExcel: asExcel,
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);
    final isDesktop = Responsive.isDesktop(context);

    final filtered = _entries.where((e) {
      if (_filter == _AuditDomainFilter.all) return true;
      return e.domain == _filter;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F8F2),
      appBar: isDesktop
          ? null
          : AppPageAppBar(
              title: 'Audit Log Report',
              onBack: widget.onBack,
            ),
      body: SafeArea(
        child: Column(
          children: [
            AppPageHeader(
              title: 'Repository Activity & Audit Log',
              subtitle:
                  'CRUD attribution & moderation history (${filtered.length} events)',
              icon: Icons.history_edu_rounded,
              onBack: widget.onBack,
              trailing: ReportExportButtons(
                onExportExcel: (_isLoading || _isExporting)
                    ? null
                    : () => _export(filtered, asExcel: true),
                onExportCsv: (_isLoading || _isExporting)
                    ? null
                    : () => _export(filtered, asExcel: false),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Padding(
                      padding: EdgeInsets.all(rs.defaultPadding),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1160),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    ChoiceChip(
                                      label: const Text('All Activity'),
                                      selected:
                                          _filter == _AuditDomainFilter.all,
                                      onSelected: (_) => setState(
                                        () => _filter = _AuditDomainFilter.all,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ChoiceChip(
                                      label: const Text('Herbs'),
                                      selected:
                                          _filter == _AuditDomainFilter.herbs,
                                      onSelected: (_) => setState(
                                        () =>
                                            _filter = _AuditDomainFilter.herbs,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ChoiceChip(
                                      label: const Text('Remedies'),
                                      selected:
                                          _filter ==
                                          _AuditDomainFilter.remedies,
                                      onSelected: (_) => setState(
                                        () => _filter =
                                            _AuditDomainFilter.remedies,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ChoiceChip(
                                      label: const Text('Ailments'),
                                      selected:
                                          _filter ==
                                          _AuditDomainFilter.ailments,
                                      onSelected: (_) => setState(
                                        () => _filter =
                                            _AuditDomainFilter.ailments,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              Expanded(
                                child: StickyReportDataTable(
                                  minTableWidth: 750,
                                  columns: const [
                                    StickyDataColumn(
                                      label: 'Record Title',
                                      flex: 3,
                                    ),
                                    StickyDataColumn(
                                      label: 'Domain',
                                      flex: 2,
                                    ),
                                    StickyDataColumn(
                                      label: 'Action / Status',
                                      flex: 3,
                                    ),
                                    StickyDataColumn(
                                      label: 'Attributed User',
                                      flex: 3,
                                    ),
                                    StickyDataColumn(
                                      label: 'Timestamp',
                                      flex: 2,
                                    ),
                                  ],
                                  rows: filtered.map((log) {
                                    return StickyDataRow(
                                      cells: [
                                        Text(
                                          log.recordTitle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: log.color.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: log.color,
                                              width: 0.8,
                                            ),
                                          ),
                                          child: Text(
                                            log.domainLabel.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: log.color,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          log.action,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                        Text(
                                          log.actor,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                        Text(
                                          _formatDate(log.timestamp),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

