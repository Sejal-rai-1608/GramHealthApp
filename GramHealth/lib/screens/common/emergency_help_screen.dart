import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_language.dart';
import '../../theme/app_colors.dart';
import '../../widgets/care_card.dart';
import '../../widgets/care_icon_button.dart';

class EmergencyHelpScreen extends StatefulWidget {
  const EmergencyHelpScreen({super.key});

  @override
  State<EmergencyHelpScreen> createState() => _EmergencyHelpScreenState();
}

class _EmergencyHelpScreenState extends State<EmergencyHelpScreen> {
  List<Map<String, String>> _contacts = [];
  bool _isLocating = false;

  final List<Map<String, dynamic>> _firstAidGuides = [
    {
      'title': 'Snakebite',
      'icon': Icons.warning_amber_rounded,
      'content': '1. Keep victim calm and still.\n2. Do NOT cut or suck the wound.\n3. Wash with soap or water.\n4. Apply restrictive bandage above the bite to limit venom flow.\n5. Seek hospital immediately (SOS).',
    },
    {
      'title': 'Severe Burns',
      'icon': Icons.local_fire_department_rounded,
      'content': '1. Remove from heat source.\n2. Cool with mild running water for 20 mins.\n3. Do NOT apply ice, creams, or oils.\n4. Cover loosely with sterile film or clean cloth.\n5. Call emergency line.',
    },
    {
      'title': 'CPR',
      'icon': Icons.monitor_heart_rounded,
      'content': '1. Check responsiveness and breathing.\n2. Call SOS/Ambulance.\n3. Push hard and fast in center of chest (100–120/min).\n4. Allow chest to rise completely between compressions.',
    },
    {
      'title': 'Poisoning',
      'icon': Icons.science_rounded,
      'content': '1. Move person to fresh air if inhaled.\n2. Do NOT induce vomiting unless told to.\n3. If swallowed, call poison control immediately.\n4. Keep poison container nearby for doctors.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('ice_contacts');
    if (data != null) {
      final list = jsonDecode(data) as List;
      _contacts = list.map((e) => Map<String, String>.from(e as Map)).toList();
    } else {
      _contacts = [
        {'name': 'Ambulance', 'relation': 'Emergency Response', 'phone': '102'},
        {'name': 'Dispatch Line', 'relation': 'Medical Hotline', 'phone': '108'},
      ];
    }
    if (mounted) setState(() {});
  }

  Future<void> _saveContact(String name, String relation, String phone) async {
    _contacts.add({'name': name, 'relation': relation, 'phone': phone});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ice_contacts', jsonEncode(_contacts));
    if (mounted) setState(() {});
  }

  Future<void> _handleCall(String number) async {
    final uri = Uri.parse('tel:$number');
    try { await launchUrl(uri); } catch (_) {}
  }

  Future<void> _triggerSOS() async {
    setState(() => _isLocating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) throw Exception('Location is disabled');
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
        if (p == LocationPermission.denied || p == LocationPermission.deniedForever) throw Exception('Permission denied');
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      final mapsLink = "https://www.google.com/maps/search/?api=1&query=${pos.latitude},${pos.longitude}";
      final msg = Uri.encodeComponent("EMERGENCY! I need immediate help. I am at: $mapsLink");
      final phones = _contacts.map((c) => c['phone']).join(',');
      await launchUrl(Uri.parse("sms:$phones?body=$msg"));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to trigger SOS: $e')));
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _routeToNearestPHC() async {
    await launchUrl(Uri.parse("https://www.google.com/maps/search/?api=1&query=hospital+clinic+PHC"), mode: LaunchMode.externalApplication);
  }

  void _showAddContactDialog() {
    final nameCtrl = TextEditingController();
    final relCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg)),
        title: Text('Add emergency contact', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: _inputDeco('Name')),
            const SizedBox(height: 10),
            TextField(controller: relCtrl, decoration: _inputDeco('Relationship')),
            const SizedBox(height: 10),
            TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: _inputDeco('Phone number')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.manrope(color: AppColors.inkMuted))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && phoneCtrl.text.isNotEmpty) {
                _saveContact(nameCtrl.text, relCtrl.text, phoneCtrl.text);
                Navigator.pop(ctx);
              }
            },
            child: Text('Save', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String label) => InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.manrope(fontSize: 12, color: AppColors.inkMuted),
        filled: true,
        fillColor: AppColors.groundAlt,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderLight)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderLight)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.tealDeep, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      );

  void _showFirstAidDialog(Map<String, dynamic> guide) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg)),
        title: Row(children: [
          Icon(guide['icon'] as IconData, size: 20, color: AppColors.teal),
          const SizedBox(width: 8),
          Text(guide['title'] as String, style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
        ]),
        content: Text(guide['content'] as String, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.inkSoft, height: 1.6)),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
            onPressed: () => Navigator.pop(ctx),
            child: Text('Understood', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
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
        title: Text('Emergency help', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.emergency)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          children: [
            // SOS — one dominant emergency signal
            GestureDetector(
              onTap: _isLocating ? null : _triggerSOS,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.emergencyWash,
                  border: Border.all(color: AppColors.emergencyPale, width: 1),
                ),
                child: Center(
                  child: Container(
                    width: 156,
                    height: 156,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.emergency),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isLocating)
                          const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        else
                          const Icon(Icons.emergency_share_rounded, size: 32, color: Colors.white),
                        const SizedBox(height: 8),
                        Text('SEND SOS\n+ GPS', textAlign: TextAlign.center, style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2, letterSpacing: 0.6)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text('Shares your live location via SMS to your emergency contacts.',
                textAlign: TextAlign.center, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.inkMuted, height: 1.4)),
            const SizedBox(height: 22),
            // First-aid
            Align(alignment: Alignment.centerLeft, child: Text('First-aid guides — works offline', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink))),
            const SizedBox(height: 10),
            SizedBox(
              height: 96,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _firstAidGuides.length,
                itemBuilder: (_, i) {
                  final g = _firstAidGuides[i];
                  return GestureDetector(
                    onTap: () => _showFirstAidDialog(g),
                    child: Container(
                      width: 112,
                      margin: EdgeInsets.only(right: i == _firstAidGuides.length - 1 ? 0 : 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(color: AppColors.mintLight, borderRadius: BorderRadius.circular(10)),
                          child: Icon(g['icon'] as IconData, size: 20, color: AppColors.teal),
                        ),
                        const SizedBox(height: 8),
                        Text(g['title'] as String, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ink)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: CareCard(
                    onTap: () => _handleCall('108'),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(color: AppColors.emergencyWash, borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.medical_services_outlined, size: 18, color: AppColors.emergency),
                        ),
                        const SizedBox(height: 8),
                        Text(context.tr('emergency_response'),
                            textAlign: TextAlign.center, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ink, height: 1.25)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CareCard(
                    onTap: _routeToNearestPHC,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.location_on_outlined, size: 18, color: AppColors.teal),
                        ),
                        const SizedBox(height: 8),
                        Text('Nearest PHC', textAlign: TextAlign.center, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ink, height: 1.25)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(context.tr('emergency_contacts'), style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink)),
                const Spacer(),
                GestureDetector(
                  onTap: _showAddContactDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(AppRadii.pill)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text('Add contact', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            CareCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: _contacts.asMap().entries.map((e) {
                  final idx = e.key;
                  final c = e.value;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(color: AppColors.groundAlt, borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.person_outline_rounded, size: 16, color: AppColors.inkMuted),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c['name'] ?? '', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
                                  Text(c['relation'] ?? '', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.inkMuted)),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _handleCall(c['phone'] ?? ''),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.call_rounded, size: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (idx < _contacts.length - 1) const Divider(height: 1, indent: 14, endIndent: 14, color: AppColors.borderLight),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
