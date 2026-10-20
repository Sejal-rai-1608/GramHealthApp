import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../l10n/app_language.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/care_card.dart';
import '../../widgets/dashboard_layout.dart';
import '../../widgets/role_async_view.dart';
import 'pharmacy_dashboard_screen.dart' show distanceKm;

/// Every registered pharmacy outlet, with distance from the signed-in one.
class PharmacyNearbyScreen extends StatelessWidget {
  const PharmacyNearbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: context.tr('nav_nearby_outlets'),
      child: RoleAsyncView<List<AdminPharmacy>>(
        loader: AdminService.getPharmacies,
        builder: (context, items) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RoleSectionHeader(
                title: 'Registered outlets',
                subtitle: '${items.length} pharmacy(s) on the platform.',
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
                FutureBuilder<AdminPharmacy?>(
                  future: _myPharmacy(),
                  builder: (context, snap) {
                    final mine = snap.data;
                    final rows = items
                        .map((p) {
                          final d = (mine == null)
                              ? null
                              : distanceKm(mine.latitude, mine.longitude,
                                  p.latitude, p.longitude);
                          return (p, d);
                        })
                        .toList()
                      ..sort((a, b) {
                        final da = a.$2 ?? double.maxFinite;
                        final db = b.$2 ?? double.maxFinite;
                        return da.compareTo(db);
                      });

                    return Column(
                      children: rows
                          .map((row) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: RoleListRow(
                                  initials: _initials(row.$1.name),
                                  title: row.$1.name,
                                  subtitle:
                                      '${row.$1.address} · ${row.$1.medicineCount} listing(s)',
                                  trailing: row.$2 == null
                                      ? null
                                      : '${row.$2!.toStringAsFixed(1)} km',
                                  trailingIcon: row.$1.id == mine?.id
                                      ? Icons.check_circle_rounded
                                      : null,
                                ),
                              ))
                          .toList(),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  static Future<AdminPharmacy?> _myPharmacy() async {
    final user = await AuthService.getUser();
    final userId = user?['id']?.toString();
    final all = await AdminService.getPharmacies();
    for (final p in all) {
      if (p.userId == userId) return p;
    }
    return null;
  }

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
