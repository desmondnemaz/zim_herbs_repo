import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zim_herbs_repo/core/components/app_page_header.dart';
import 'package:zim_herbs_repo/core/utils/enums.dart';
import 'package:zim_herbs_repo/core/utils/responsive.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';
import 'package:zim_herbs_repo/features/admin/herb_management/presentation/add_edit_herb_page.dart';
import 'package:zim_herbs_repo/features/admin/remedy_management/presentation/add_edit_remedy_page.dart';
import 'package:zim_herbs_repo/features/repository/conditions/data/datasources/condition_remote_datasource.dart';
import 'package:zim_herbs_repo/features/repository/conditions/data/models/condition_model.dart';

/// Hub where public users can contribute Herbs, Remedies, and Conditions to the Zim Herbs repository.
class ContributionsPage extends StatefulWidget {
  final VoidCallback? onBack;
  const ContributionsPage({super.key, this.onBack});

  @override
  State<ContributionsPage> createState() => _ContributionsPageState();
}

class _ContributionsPageState extends State<ContributionsPage> {
  Future<void> _showAddConditionDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final symptomsController = TextEditingController();
    final precautionsController = TextEditingController();
    AilmentCategory selectedCategory = AilmentCategory.respiratory;
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: [
                Icon(Icons.monitor_heart_outlined, color: Color(0xFF106F74)),
                SizedBox(width: 10),
                Text('Contribute Condition', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Share health conditions to help community members match targeted botanical remedies.',
                      style: TextStyle(fontSize: 12.5, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Condition Name *',
                        hintText: 'e.g. Asthma, Headaches, Arthritis',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<AilmentCategory>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Ailment Category *',
                        border: OutlineInputBorder(),
                      ),
                      items: AilmentCategory.values.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(ailmentCategoryLabel(category)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedCategory = val);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: descController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Description / Overview',
                        hintText: 'Brief summary of the condition and background',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: symptomsController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Common Symptoms (comma separated)',
                        hintText: 'e.g. Chest tightness, wheezing, shortness of breath',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: precautionsController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Precautions / Contraindications (comma separated)',
                        hintText: 'e.g. Avoid cold exposure, monitor breathing',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF106F74)),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final name = nameController.text.trim();
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        final nav = Navigator.of(ctx);

                        if (name.isEmpty) {
                          scaffoldMessenger.showSnackBar(
                            const SnackBar(content: Text('Please enter a condition name.')),
                          );
                          return;
                        }

                        setDialogState(() => isSubmitting = true);

                        try {
                          final symptoms = symptomsController.text
                              .split(',')
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList();

                          final precautions = precautionsController.text
                              .split(',')
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList();

                          final newCondition = ConditionModel(
                            id: '',
                            name: name,
                            ailmentCategory: selectedCategory,
                            description: descController.text.trim().isNotEmpty
                                ? descController.text.trim()
                                : null,
                            symptoms: symptoms,
                            precautions: precautions,
                          );

                          final ds = ConditionRemoteDataSource(Supabase.instance.client);
                          await ds.createCondition(newCondition);

                          if (mounted) {
                            nav.pop();
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFF16A34A),
                                content: Text('Thank you! "$name" has been submitted for review.'),
                              ),
                            );
                          }
                        } catch (e) {
                          setDialogState(() => isSubmitting = false);
                          if (mounted) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.red,
                                content: Text('Failed to submit condition: $e'),
                              ),
                            );
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Submit Condition'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F8F2),
      appBar: isDesktop
          ? null
          : AppPageAppBar(
              title: 'Contributions',
              onBack: widget.onBack,
            ),
      body: SafeArea(
        child: Column(
          children: [
            AppPageHeader(
              title: 'Community Contributions',
              subtitle: 'Contribute herbs, remedies, and conditions to preserve Zimbabwe\'s botanical heritage',
              icon: Icons.volunteer_activism_outlined,
              iconColor: const Color(0xFFD97706),
              onBack: widget.onBack,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(rs.defaultPadding),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Informational Banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFD97706), Color(0xFFB45309)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFD97706).withValues(alpha: 0.28),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.verified_user_rounded, color: Colors.white, size: 36),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Peer-Reviewed Contributions',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'All community submissions are verified by licensed practitioners & moderators before public catalog publication. Your authorship is recorded.',
                                      style: TextStyle(color: Colors.white, fontSize: 13, height: 1.35),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        Text(
                          'What would you like to contribute?',
                          style: TextStyle(
                            fontSize: rs.titleFont * 1.05,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Contribution Options
                        _ContributionCard(
                          title: 'Contribute Herb',
                          subtitle: 'Document a medicinal plant, botanical names, vernacular names (Shona/Ndebele), preparation, and photos.',
                          icon: Icons.local_florist_rounded,
                          color: const Color(0xFF22633C),
                          pastelColor: const Color(0xFFEAF5EB),
                          buttonLabel: 'Contribute Herb',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AddEditHerbPage()),
                            );
                          },
                        ),
                        const SizedBox(height: 14),

                        _ContributionCard(
                          title: 'Contribute Remedy',
                          subtitle: 'Share traditional multi-herb formulations, dosage, preparation steps, and targeted illnesses.',
                          icon: Icons.healing_outlined,
                          color: const Color(0xFF295CA2),
                          pastelColor: const Color(0xFFEBF3FC),
                          buttonLabel: 'Contribute Remedy',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AddEditRemedyPage()),
                            );
                          },
                        ),
                        const SizedBox(height: 14),

                        _ContributionCard(
                          title: 'Contribute Condition',
                          subtitle: 'Register medical symptoms, affected organ systems, and safety precautions to link with remedies.',
                          icon: Icons.monitor_heart_outlined,
                          color: const Color(0xFF106F74),
                          pastelColor: const Color(0xFFE6F5F5),
                          buttonLabel: 'Contribute Condition',
                          onTap: () => _showAddConditionDialog(context),
                        ),
                        const SizedBox(height: 40),
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

class _ContributionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color pastelColor;
  final String buttonLabel;
  final VoidCallback onTap;

  const _ContributionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.pastelColor,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.2), width: 1.2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: pastelColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.add_circle_outline, size: 16),
                      label: Text(buttonLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: onTap,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
