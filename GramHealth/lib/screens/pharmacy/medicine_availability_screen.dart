import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_language.dart';
import '../../theme/app_colors.dart';
import '../../widgets/care_card.dart';
import '../../widgets/care_icon_button.dart';
import '../../widgets/empty_state.dart';
import '../../services/pharmacy_service.dart';

class MedicineAvailabilityScreen extends StatefulWidget {
  final String? medicineQuery;
  const MedicineAvailabilityScreen({this.medicineQuery, super.key});

  @override
  State<MedicineAvailabilityScreen> createState() => _MedicineAvailabilityScreenState();
}

class _MedicineAvailabilityScreenState extends State<MedicineAvailabilityScreen> {
  final _searchCtrl = TextEditingController();
  List<PharmacySearchResult> _pharmacies = [];
  bool _isLoading = false;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _initLocationAndSearch();
  }

  Future<void> _initLocationAndSearch() async {
    setState(() => _isLoading = true);
    try {
      if (await Geolocator.isLocationServiceEnabled()) {
        var perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
          _currentPosition = await Geolocator.getCurrentPosition();
        }
      }
    } catch (_) {}
    if (widget.medicineQuery != null && widget.medicineQuery!.isNotEmpty) {
      _searchCtrl.text = widget.medicineQuery!;
      _performSearch();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _performSearch() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) {
      setState(() => _pharmacies = []);
      return;
    }
    setState(() => _isLoading = true);
    final lat = _currentPosition?.latitude ?? 22.7196;
    final lon = _currentPosition?.longitude ?? 75.8577;
    final results = await PharmacyService.searchPharmaciesLocal(query, lat, lon);
    if (mounted) setState(() { _pharmacies = results; _isLoading = false; });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openNavigation(double lat, double lon) async {
    final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lon');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!await launchUrl(url, mode: LaunchMode.inAppWebView) && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open maps')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: CareIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => context.pop(),
            tooltip: 'Back',
            iconSize: 18,
            size: 44,
          ),
        ),
        leadingWidth: 56,
        title: Text(context.tr('medicine_availability'), style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onSubmitted: (_) => _performSearch(),
                    style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink),
                    decoration: InputDecoration(
                      hintText: context.tr('search_medicine'),
                      hintStyle: GoogleFonts.manrope(fontSize: 12, color: AppColors.inkFaint),
                      prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.inkMuted),
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md), borderSide: const BorderSide(color: AppColors.borderLight)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md), borderSide: const BorderSide(color: AppColors.borderLight)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md), borderSide: const BorderSide(color: AppColors.tealDeep, width: 1.5)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: _performSearch,
                    style: FilledButton.styleFrom(backgroundColor: AppColors.teal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)), elevation: 0),
                    child: Text('Search', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
          // Map
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              child: SizedBox(
                height: 160,
                child: FlutterMap(
                  options: MapOptions(initialCenter: LatLng(_currentPosition?.latitude ?? 22.7196, _currentPosition?.longitude ?? 75.8577), initialZoom: 13.5),
                  children: [
                    TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.ruralcare.app'),
                    MarkerLayer(
                      markers: _pharmacies.map((res) {
                        final p = res.pharmacy;
                        return Marker(
                          point: LatLng(p.latitude, p.longitude),
                          width: 44,
                          height: 44,
                          child: Container(
                            alignment: Alignment.center,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: res.isAvailable ? AppColors.teal : AppColors.inkFaint,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.surface, width: 2),
                              ),
                              child: const Icon(Icons.local_pharmacy_rounded, color: AppColors.surface, size: 14),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(context.tr('nearby_pharmacies'), style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink)),
                const Spacer(),
                if (_isLoading) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _isLoading
                ? const SizedBox.shrink()
                : _pharmacies.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: EmptyState(
                          icon: Icons.search_off_rounded,
                          title: _searchCtrl.text.isEmpty ? 'Search for a medicine' : 'No pharmacies found',
                          subtitle: _searchCtrl.text.isEmpty ? 'Enter a medicine name above to check nearby availability.' : 'Try another medicine or check your connection and sync.',
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _pharmacies.length,
                        itemBuilder: (_, i) {
                          final res = _pharmacies[i];
                          final p = res.pharmacy;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: CareCard(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(child: Text(p.name, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink))),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                              decoration: BoxDecoration(color: res.isAvailable ? AppColors.mint : AppColors.groundAlt, borderRadius: BorderRadius.circular(6)),
                                              child: Text(res.isAvailable ? context.tr('available') : context.tr('out_of_stock'), style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: res.isAvailable ? AppColors.tealDeep : AppColors.inkMuted)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(p.address, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.inkMuted)),
                                        const SizedBox(height: 6),
                                        Row(children: [
                                          const Icon(Icons.location_on_outlined, size: 12, color: AppColors.inkFaint),
                                          const SizedBox(width: 4),
                                          Text('${res.distanceKm.toStringAsFixed(1)} km ${context.tr('away')}', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.inkFaint)),
                                        ]),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  GestureDetector(
                                    onTap: () => _openNavigation(p.latitude, p.longitude),
                                    child: Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 18)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
