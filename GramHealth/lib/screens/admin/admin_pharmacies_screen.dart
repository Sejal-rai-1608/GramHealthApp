import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/admin_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/care_card.dart';
import '../../widgets/dashboard_layout.dart';
import '../../widgets/role_async_view.dart';
import '../../l10n/app_language.dart';

/// Registered pharmacy outlets, from `GET /api/pharmacy/list`.
class AdminPharmaciesScreen extends StatelessWidget {
  const AdminPharmaciesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: context.tr('nav_pharmacies'),
      child: RoleAsyncView<List<AdminPharmacy>>(
        loader: AdminService.getPharmacies,
        builder: (context, items) {
          final stocked = items.where((p) => p.inStockCount > 0).length;
          final medicines = items.fold<int>(0, (sum, p) => sum + p.medicineCount);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RoleSectionHeader(
                title: context.tr('console_pharmacy_network'),
                subtitle:
                    '${items.length} outlet(s) · $stocked stocked · $medicines medicine listing(s)',
              ),
              if (items.isEmpty)
                CareCard(
                  child: Row(
                    children: [
                      const Icon(Icons.local_pharmacy_outlined,
                          size: 20, color: AppColors.inkFaint),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('No pharmacies registered yet.',
                            style: GoogleFonts.manrope(
                                fontSize: 13, color: AppColors.inkMuted)),
                      ),
                    ],
                  ),
                )
              else
                ...items.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: RoleListRow(
                        initials: _initials(p.name),
                        title: p.name,
                        subtitle: p.address,
                        trailing: p.medicineCount == 0
                            ? 'No listings'
                            : '${p.inStockCount}/${p.medicineCount} in stock',
                      ),
                    )),
            ],
          );
        },
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
