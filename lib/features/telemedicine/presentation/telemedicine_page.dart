import 'package:flutter/material.dart';
import 'package:zim_herbs_repo/core/components/app_page_header.dart';
import 'package:zim_herbs_repo/core/utils/responsive.dart';
import 'package:zim_herbs_repo/core/utils/responsive_sizes.dart';

class _PractitionerItem {
  final String name;
  final String specialization;
  final int yearsOfExperience;
  final String location;
  final double rating;
  final IconData avatarIcon;

  const _PractitionerItem({
    required this.name,
    required this.specialization,
    required this.yearsOfExperience,
    required this.location,
    required this.rating,
    required this.avatarIcon,
  });
}

const List<_PractitionerItem> _samplePractitioners = [
  _PractitionerItem(
    name: "Dr. Sekuru M. Chimuka",
    specialization: "Traditional Botanical Formulations & Respiratory Care",
    yearsOfExperience: 22,
    location: "Harare, Zimbabwe",
    rating: 4.9,
    avatarIcon: Icons.person_rounded,
  ),
  _PractitionerItem(
    name: "Dr. Thandiwe Ndlovu",
    specialization: "Digestive & Immune Herbal Wellness",
    yearsOfExperience: 14,
    location: "Bulawayo, Zimbabwe",
    rating: 4.8,
    avatarIcon: Icons.person_outline_rounded,
  ),
  _PractitionerItem(
    name: "Dr. Farai Gumbo",
    specialization: "Holistic Herbal Preparations & Chronic Care",
    yearsOfExperience: 18,
    location: "Mutare, Zimbabwe",
    rating: 4.9,
    avatarIcon: Icons.person_rounded,
  ),
];

class TelemedicinePage extends StatelessWidget {
  final VoidCallback? onBack;
  const TelemedicinePage({super.key, this.onBack});

  void _showConsultationDialog(BuildContext context, String practitionerName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.calendar_month_rounded, color: Color(0xFF684B8A)),
            const SizedBox(width: 8),
            const Text('Book Consultation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Practitioner: $practitionerName', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text(
              'Online consultation scheduling with verified traditional herbalists will be fully available in the upcoming release. Your interest has been recorded.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ],
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF684B8A)),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rs = ResponsiveSize(context);
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: isDesktop
          ? null
          : AppPageAppBar(
              title: 'Telemedicine',
              onBack: onBack,
            ),
      body: SafeArea(
        child: Column(
          children: [
            AppPageHeader(
              title: 'Telemedicine & Practitioners',
              subtitle: 'Consult licensed herbal practitioners and access remote traditional wellness care',
              icon: Icons.medical_services_outlined,
              iconColor: const Color(0xFF684B8A),
              onBack: onBack,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(rs.defaultPadding),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hero Consultation Banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF684B8A), Color(0xFF50386C)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF684B8A).withValues(alpha: 0.28),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.video_camera_front_outlined,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Virtual Herbal Consultations',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Connect remotely with certified herbal practitioners for personalized traditional medicine advice.',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.85),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Section Header: Practitioners
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Verified Practitioners',
                              style: TextStyle(
                                fontSize: rs.titleFont * 1.05,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF684B8A).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Licensed Directory',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF684B8A),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Practitioners Cards List
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _samplePractitioners.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final practitioner = _samplePractitioners[index];
                            return Card(
                              color: Colors.white,
                              elevation: 1.5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                  color: theme.colorScheme.outline.withValues(alpha: 0.15),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 26,
                                      backgroundColor: const Color(0xFFF4EEF9),
                                      child: Icon(
                                        practitioner.avatarIcon,
                                        color: const Color(0xFF684B8A),
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  practitioner.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Color(0xFF1E293B),
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: const Color(0xFF16A34A).withValues(alpha: 0.35),
                                                  ),
                                                ),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.verified, size: 12, color: Color(0xFF16A34A)),
                                                    SizedBox(width: 3),
                                                    Text(
                                                      'Verified',
                                                      style: TextStyle(
                                                        color: Color(0xFF16A34A),
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            practitioner.specialization,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(
                                                practitioner.location,
                                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                              ),
                                              const SizedBox(width: 12),
                                              const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                                              const SizedBox(width: 2),
                                              Text(
                                                '${practitioner.rating} (${practitioner.yearsOfExperience} yrs exp)',
                                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    FilledButton.tonal(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: const Color(0xFFF4EEF9),
                                        foregroundColor: const Color(0xFF684B8A),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      onPressed: () => _showConsultationDialog(context, practitioner.name),
                                      child: const Text('Consult', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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

