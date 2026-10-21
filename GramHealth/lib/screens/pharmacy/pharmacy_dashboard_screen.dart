import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/care_card.dart';
import '../../widgets/dashboard_layout.dart';
import '../../widgets/role_async_view.dart';
import '../../l10n/app_language.dart';

/// A pharmacy's own console.
///
/// `GET /api/pharmacy/list` returns every registered outlet, so the pharmacy
/// profile is resolved by matching the signed-in user id.
class PharmacyDashboardScreen extends StatelessWidget {
  const PharmacyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: context.tr('nav_dashboard'),
      child: RoleAsyncView<_PharmacyState>(
        loader: () => _load(),
        builder: (context, state) {
          final mine = state.mine;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RoleSectionHeader(
                title: context.tr('console_your_outlet'),
                subtitle: context.tr('console_your_outlet_sub'),
              ),

              if (mine == null)
                CareCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              size: 20, color: AppColors.amberDeep),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(context.tr('console_profile_not_found'),
                                style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your account is not linked to a pharmacy profile yet. '
                        'Register the outlet with a full address so it can be located, '
                        'then reload this page.',
                        style: GoogleFonts.manrope(
                            fontSize: 13,
                            color: AppColors.inkMuted,
                            height: 1.45),
                      ),
                    ],
                  ),
                )
              else ...[
                CareCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppColors.mint,
                              borderRadius: BorderRadius.circular(AppRadii.md),
                            ),
                            child: const Icon(Icons.local_pharmacy_rounded,
                                size: 22, color: AppColors.teal),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  mine.name,
                                  style: GoogleFonts.manrope(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.ink),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  mine.address,
                                  style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      color: AppColors.inkMuted,
                                      height: 1.35),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _stat(context, '${mine.medicineCount}',
                                'Medicines listed', AppColors.teal),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _stat(context, '${mine.inStockCount}',
                                'In stock now', AppColors.amberDeep),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _stat(context, '${state.all.length}',
                                'Outlets nearby', AppColors.coralDeep),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                RoleSectionHeader(
                  title: context.tr('console_manage'),
                  subtitle: context.tr('console_stock_list_sub'),
                ),

                _action(context, Icons.inventory_2_outlined,
                    context.tr('console_update_stock'),
                    context.tr('console_update_stock_sub'),
                    () => context.go('/pharmacy/stock')),
                const SizedBox(height: 10),
                _action(context, Icons.map_outlined, context.tr('console_nearby_outlets'),
                    context.tr('console_nearby_outlets_sub'),
                    () => context.go('/pharmacy/nearby')),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _stat(BuildContext context, String value, String label, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.groundAlt,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: GoogleFonts.manrope(
                  fontSize: 20, fontWeight: FontWeight.w800, color: accent)),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.manrope(
                  fontSize: 11, color: AppColors.inkMuted, height: 1.3)),
        ],
      ),
    );
  }

  Widget _action(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return CareCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Icon(icon, size: 20, color: AppColors.teal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: GoogleFonts.manrope(
                        fontSize: 12, color: AppColors.inkMuted, height: 1.4)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              size: 20, color: AppColors.inkFaint),
        ],
      ),
    );
  }

  static Future<_PharmacyState> _load() async {
    final user = await AuthService.getUser();
    final userId = user?['id']?.toString();
    final all = await AdminService.getPharmacies();
    AdminPharmacy? mine;
    for (final p in all) {
      if (p.userId == userId) {
        mine = p;
        break;
      }
    }
    return _PharmacyState(mine, all);
  }
}

class _PharmacyState {
  final AdminPharmacy? mine;
  final List<AdminPharmacy> all;
  const _PharmacyState(this.mine, this.all);
}

/// Distance helper shared by the pharmacy screens.
double distanceKm(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371.0;
  double dLat = _rad(lat2 - lat1);
  double dLon = _rad(lon2 - lon1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_rad(lat1)) *
          math.cos(_rad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

double _rad(double deg) => deg * math.pi / 180;
