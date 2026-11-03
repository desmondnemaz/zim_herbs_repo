import 'package:flutter/material.dart';
import 'package:zim_herbs_repo/core/components/app_page_header.dart';
import 'package:zim_herbs_repo/core/utils/responsive.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';
import 'reports/ailment_category_coverage_report_page.dart';
import 'reports/audit_log_report_page.dart';
import 'reports/herbs_catalog_report_page.dart';
import 'reports/remedies_report_page.dart';

class _ReportDirectoryItem {
  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final Color color;
  final Widget Function() pageBuilder;

  const _ReportDirectoryItem({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.color,
    required this.pageBuilder,
  });
}

/// Reports Hub screen where each report opens in its own dedicated full-page view
/// rather than crowding multiple reports onto a single page.
class AdminReportsScreen extends StatelessWidget {
  final VoidCallback? onBack;

  const AdminReportsScreen({super.key, this.onBack});

  static final List<_ReportDirectoryItem> _reports = [
    _ReportDirectoryItem(
      title: 'Ailment Category Plant Coverage Report',
      subtitle:
          'Spreadsheet breakdown of our 17 AilmentCategory classifications, No. of plants, and % share of plants.',
      badge: '17 Categories • .xlsx / .csv',
      icon: Icons.table_chart_rounded,
      color: const Color(0xFF1E5631),
      pageBuilder: () => const AilmentCategoryCoverageReportPage(),
    ),
    _ReportDirectoryItem(
      title: 'Herbs Botanical Catalog Report',
      subtitle:
          'Complete inventory of medicinal plants with English, Shona, Ndebele, and Scientific names, families, habits, and origin status.',
      badge: 'Botanical Inventory • .xlsx / .csv',
      icon: Icons.local_florist_rounded,
      color: const Color(0xFF22633C),
      pageBuilder: () => const HerbsCatalogReportPage(),
    ),
    _ReportDirectoryItem(
      title: 'Remedies & Formulations Report',
      subtitle:
          'Traditional preparations, methods of use, adult and infant dosages, frequency, and moderation status.',
      badge: 'Formulations • .xlsx / .csv',
      icon: Icons.healing_outlined,
      color: const Color(0xFF295CA2),
      pageBuilder: () => const RemediesReportPage(),
    ),
    _ReportDirectoryItem(
      title: 'Repository Activity & Audit Log Report',
      subtitle:
          'Chronological CRUD attribution and moderation audit trail across herbs, remedies, and ailments.',
      badge: 'CRUD Traceability • .xlsx / .csv',
      icon: Icons.history_edu_rounded,
      color: const Color(0xFF106F74),
      pageBuilder: () => const AuditLogReportPage(),
    ),
  ];

  void _openReportPage(BuildContext context, _ReportDirectoryItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => item.pageBuilder()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);
    final isDesktop = Responsive.isDesktop(context);
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F8F2),
      appBar: isDesktop
          ? null
          : AppPageAppBar(
              title: 'Reports',
              onBack: onBack,
            ),
      body: SafeArea(
        child: Column(
          children: [
            AppPageHeader(
              title: 'System Reports Directory',
              subtitle:
                  'Select a report below to open its dedicated view and export to Excel (.xlsx) or CSV',
              icon: Icons.assessment_rounded,
              onBack: onBack,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(rs.defaultPadding),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: isMobile
                        ? Material(
                            color: Colors.white,
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _reports.length,
                              separatorBuilder: (_, _) => const Divider(
                                height: 1,
                                color: Color(0xFFF1F5F9),
                              ),
                              itemBuilder: (context, index) {
                                final item = _reports[index];
                                return ListTile(
                                  onTap: () => _openReportPage(context, item),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: item.color.withValues(
                                      alpha: 0.12,
                                    ),
                                    child: Icon(
                                      item.icon,
                                      color: item.color,
                                      size: 22,
                                    ),
                                  ),
                                  title: Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.5,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      item.subtitle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 16,
                                    color: Color(0xFF94A3B8),
                                  ),
                                );
                              },
                            ),
                          )
                        : GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 540,
                                  mainAxisExtent: 185,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                            itemCount: _reports.length,
                            itemBuilder: (context, index) {
                              final item = _reports[index];
                              return Card(
                                elevation: 0,
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: InkWell(
                                  onTap: () => _openReportPage(context, item),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: item.color.withValues(
                                                  alpha: 0.12,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                item.icon,
                                                color: item.color,
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                item.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: Color(0xFF1E293B),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Expanded(
                                          child: Text(
                                            item.subtitle,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF64748B),
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: item.color.withValues(
                                                  alpha: 0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                item.badge,
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: item.color,
                                                ),
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                Text(
                                                  'Open Report',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: item.color,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Icon(
                                                  Icons.arrow_forward_rounded,
                                                  size: 16,
                                                  color: item.color,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
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
