import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/admin_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/care_card.dart';
import '../../widgets/dashboard_layout.dart';
import '../../widgets/role_async_view.dart';
import '../../widgets/status_badge.dart';
import '../../l10n/app_language.dart';

/// Every consultation on the platform, from `GET /api/consultations`.
class AdminConsultationsScreen extends StatefulWidget {
  const AdminConsultationsScreen({super.key});

  @override
  State<AdminConsultationsScreen> createState() => _AdminConsultationsScreenState();
}

class _AdminConsultationsScreenState extends State<AdminConsultationsScreen> {
  String _status = 'ALL';

  static final _statuses = [
    ('ALL', 'All'),
    ('PENDING', 'Pending'),
    ('ACTIVE', 'Active'),
    ('COMPLETED', 'Completed'),
    ('CANCELLED', 'Cancelled'),
  ];

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: context.tr('nav_consultations'),
      child: RoleAsyncView<List<AdminConsultation>>(
        loader: () => AdminService.getConsultations(
          status: _status == 'ALL' ? null : _status,
        ),
        builder: (context, items) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RoleSectionHeader(
                title: context.tr('nav_consultations'),
                subtitle: '${items.length} record(s) match this filter.',
              ),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _statuses.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final s = _statuses[i];
                    final selected = _status == s.$1;
                    return GestureDetector(
                      onTap: () => setState(() => _status = s.$1),
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.mint : AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                          border: Border.all(
                            color: selected ? AppColors.tealPale : AppColors.borderLight,
                          ),
                        ),
                        child: Text(
                          s.$2,
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: selected ? AppColors.tealDeep : AppColors.inkSoft,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                CareCard(
                  child: Row(
                    children: [
                      const Icon(Icons.event_note_outlined,
                          size: 20, color: AppColors.inkFaint),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _status == 'ALL'
                              ? 'No consultations on the platform yet.'
                              : 'No $_status consultations.',
                          style: GoogleFonts.manrope(
                              fontSize: 13, color: AppColors.inkMuted),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...items.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: RoleListRow(
                        initials: c.patientInitials,
                        title: c.patientName ?? 'Unknown patient',
                        subtitle: [
                          c.type,
                          if (c.hasDoctor)
                            c.doctorName ?? 'Assigned doctor'
                          else
                            'Unassigned',
                          if (c.symptoms != null && c.symptoms!.isNotEmpty)
                            c.symptoms!,
                        ].join(' · '),
                        trailingWidget: StatusBadge(status: c.status),
                      ),
                    )),
            ],
          );
        },
      ),
    );
  }
}
