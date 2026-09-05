import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../l10n/app_language.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';

import '../services/pharmacy_service.dart';

// No longer using hardcoded kPharmacies

class MedicineAvailabilityScreen extends StatefulWidget {
  final String? medicineQuery;
  const MedicineAvailabilityScreen({this.medicineQuery, super.key});

  @override
  State<MedicineAvailabilityScreen> createState() => _MedicineAvailabilityScreenState();
}

class _MedicineAvailabilityScreenState extends State<MedicineAvailabilityScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<PharmacySearchResult> _pharmacies = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.medicineQuery != null && widget.medicineQuery!.isNotEmpty) {
      _searchCtrl.text = widget.medicineQuery!;
      _performSearch();
    }
  }

  Future<void> _performSearch() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) {
      setState(() {
        _pharmacies = [];
      });
      return;
    }

    setState(() => _isLoading = true);
    // Hardcoded user mock coordinates for Indore
    final results = await PharmacyService.searchPharmaciesLocal(query, 22.7196, 75.8577);
    if (mounted) {
      setState(() {
        _pharmacies = results;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondaryBg,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.secondaryBg,
                        ),
                        child: const Icon(Icons.arrow_back, color: AppColors.textDark, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      context.tr('medicine_availability'),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textDark),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Color(0xFF666666), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          onSubmitted: (_) => _performSearch(),
                          decoration: InputDecoration(
                            hintText: context.tr('search_medicine'),
                            hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
                            border: InputBorder.none,
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      GestureDetector(
                        onTap: _performSearch,
                        child: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.primaryAccent),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              children: [
                // Map Preview
                Container(
                  height: 160,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Color(0x0F000000), blurRadius: 6, offset: Offset(0, 2)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: FlutterMap(
                      options: const MapOptions(
                        initialCenter: LatLng(22.7196, 75.8577),
                        initialZoom: 13.5,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.ruralcare.app',
                        ),
                        MarkerLayer(
                          markers: _pharmacies.map((res) {
                            final p = res.pharmacy;
                            return Marker(
                              point: LatLng(p.latitude, p.longitude),
                              width: 36,
                              height: 36,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: res.isAvailable ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black26, blurRadius: 4),
                                  ],
                                ),
                                child: const Icon(Icons.local_pharmacy, color: Colors.white, size: 18),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.tr('nearby_pharmacies'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark),
                    ),
                    if (_isLoading)
                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  ],
                ),
                const SizedBox(height: 12),

                if (!_isLoading && _pharmacies.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        _searchCtrl.text.isEmpty
                            ? 'Search for a medicine to see availability.'
                            : 'No pharmacies configured or synced nearby.',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),

                // Pharmacy Cards
                ..._pharmacies.map((res) {
                  final p = res.pharmacy;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        p.name,
                                        style: const TextStyle(
                                            fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: res.isAvailable ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        res.isAvailable ? context.tr('available') : context.tr('out_of_stock'),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: res.isAvailable ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  p.address,
                                  style: TextStyle(
                                      fontSize: 12, color: AppColors.textDark.withValues(alpha: 0.6)),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF666666)),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${res.distanceKm.toStringAsFixed(1)} km ${context.tr('away')}',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primaryAccent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.navigation_outlined, color: AppColors.textDark, size: 20),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
