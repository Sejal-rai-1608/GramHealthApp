import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../l10n/app_language.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';

class Pharmacy {
  final String id;
  final String name;
  final String distance;
  final bool available;
  final String address;
  final double latitude;
  final double longitude;

  const Pharmacy({
    required this.id,
    required this.name,
    required this.distance,
    required this.available,
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}

const List<Pharmacy> kPharmacies = [
  Pharmacy(
    id: '1',
    name: 'Village Health Pharmacy',
    distance: '1.2 km',
    available: true,
    address: 'Near Bus Stand, Village Road',
    latitude: 22.7196,
    longitude: 75.8577,
  ),
  Pharmacy(
    id: '2',
    name: 'City Medicos',
    distance: '5.5 km',
    available: true,
    address: 'Main Market, District Center',
    latitude: 22.7250,
    longitude: 75.8650,
  ),
  Pharmacy(
    id: '3',
    name: 'Rural Care Point',
    distance: '0.8 km',
    available: false,
    address: 'Opposite Government School',
    latitude: 22.7150,
    longitude: 75.8520,
  ),
];

class MedicineAvailabilityScreen extends StatefulWidget {
  const MedicineAvailabilityScreen({super.key});

  @override
  State<MedicineAvailabilityScreen> createState() => _MedicineAvailabilityScreenState();
}

class _MedicineAvailabilityScreenState extends State<MedicineAvailabilityScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

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
                          decoration: InputDecoration(
                            hintText: context.tr('search_medicine'),
                            hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
                            border: InputBorder.none,
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
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
                          markers: kPharmacies.map((p) {
                            return Marker(
                              point: LatLng(p.latitude, p.longitude),
                              width: 36,
                              height: 36,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: p.available ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
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

                Text(
                  context.tr('nearby_pharmacies'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark),
                ),
                const SizedBox(height: 12),

                // Pharmacy Cards
                ...kPharmacies.map((p) {
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
                                        color: p.available ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        p.available ? context.tr('available') : context.tr('out_of_stock'),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: p.available ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
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
                                      '${p.distance} ${context.tr('away')}',
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
