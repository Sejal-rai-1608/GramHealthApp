import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/app_config.dart';
import '../../services/admin_service.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/care_card.dart';
import '../../widgets/dashboard_layout.dart';
import '../../widgets/role_async_view.dart';
import '../../l10n/app_language.dart';

/// A medicine the pharmacy has listed.
class StockItem {
  final String id;
  final String name;
  final bool inStock;

  const StockItem({
    required this.id,
    required this.name,
    required this.inStock,
  });

  factory StockItem.fromJson(Map<String, dynamic> json) => StockItem(
        id: json['id']?.toString() ?? '',
        name: json['medicineName']?.toString() ?? 'Unnamed medicine',
        inStock: json['inStock'] == true,
      );
}

/// Lets a pharmacy mark medicines in or out of stock.
///
/// Writes go to `POST /api/pharmacy/inventory`, which the backend scopes to
/// the signed-in pharmacy.
class PharmacyStockScreen extends StatefulWidget {
  const PharmacyStockScreen({super.key});

  @override
  State<PharmacyStockScreen> createState() => _PharmacyStockScreenState();
}

class _PharmacyStockScreenState extends State<PharmacyStockScreen> {
  final _medicineCtrl = TextEditingController();
  String? _busyMedicine;

  @override
  void dispose() {
    _medicineCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggle(StockItem item, bool value) async {
    setState(() => _busyMedicine = item.name);
    try {
      await ApiClient.post(
        AppConfig.apiPharmacyInventory,
        {'medicineName': item.name, 'inStock': value},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${item.name} marked ${value ? 'in stock' : 'out of stock'}',
            ),
            backgroundColor: AppColors.ink,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save: $e'),
            backgroundColor: AppColors.emergency,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busyMedicine = null);
    }
  }

  Future<void> _add() async {
    final name = _medicineCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _busyMedicine = name);
    try {
      await ApiClient.post(
        AppConfig.apiPharmacyInventory,
        {'medicineName': name, 'inStock': true},
      );
      _medicineCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name added to your stock list'),
            backgroundColor: AppColors.ink,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not add: $e'),
            backgroundColor: AppColors.emergency,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busyMedicine = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: context.tr('console_stock_list'),
      child: RoleAsyncView<List<StockItem>>(
        loader: _loadStock,
        builder: (context, items) {
          final inStock = items.where((i) => i.inStock).length;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RoleSectionHeader(
                title: context.tr('console_stock_list'),
                subtitle:
                    '${items.length} listing(s) · $inStock in stock. Patients see this when they search for medicine.',
              ),

              CareCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('console_add_medicine'),
                        style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _medicineCtrl,
                            textCapitalization: TextCapitalization.words,
                            style: GoogleFonts.manrope(fontSize: 15),
                            decoration: InputDecoration(
                              hintText: 'e.g. Paracetamol 500mg',
                              hintStyle: GoogleFonts.manrope(
                                  fontSize: 14, color: AppColors.textPlaceholder),
                              filled: true,
                              fillColor: AppColors.surface,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadii.md),
                                borderSide: const BorderSide(
                                    color: AppColors.borderStrong),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadii.md),
                                borderSide: const BorderSide(
                                    color: AppColors.borderStrong),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadii.md),
                                borderSide: const BorderSide(
                                    color: AppColors.tealDeep, width: 2),
                              ),
                            ),
                            onSubmitted: (_) => _add(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 48,
                          child: FilledButton(
                            onPressed: _busyMedicine == null ? _add : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.teal,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadii.md)),
                            ),
                            child: const Icon(Icons.add_rounded,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              if (items.isEmpty)
                CareCard(
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined,
                          size: 20, color: AppColors.inkFaint),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'No medicines listed yet. Add one above.',
                          style: GoogleFonts.manrope(
                              fontSize: 13, color: AppColors.inkMuted),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: CareCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink),
                              ),
                            ),
                            if (_busyMedicine == item.name)
                              const Padding(
                                padding: EdgeInsets.only(right: 12),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.teal),
                                ),
                              )
                            else
                              Switch(
                                value: item.inStock,
                                onChanged: (v) => _toggle(item, v),
                                activeThumbColor: Colors.white,
                                activeTrackColor: AppColors.teal,
                                inactiveThumbColor: Colors.white,
                                inactiveTrackColor: AppColors.inkGhost,
                              ),
                          ],
                        ),
                      ),
                    )),
            ],
          );
        },
      ),
    );
  }

  static Future<List<StockItem>> _loadStock() async {
    final user = await AuthService.getUser();
    final userId = user?['id']?.toString();
    final all = await AdminService.getPharmacies();
    for (final p in all) {
      if (p.userId == userId) {
        final response =
            await ApiClient.get(AppConfig.apiPharmacyList);
        final data = response is Map && response['data'] is List
            ? response['data'] as List
            : const [];
        for (final row in data.whereType<Map<String, dynamic>>()) {
          if (row['id']?.toString() == p.id) {
            final inv = row['inventories'] as List<dynamic>? ?? const [];
            return inv
                .whereType<Map<String, dynamic>>()
                .map(StockItem.fromJson)
                .toList();
          }
        }
        return const [];
      }
    }
    return const [];
  }
}
