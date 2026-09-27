import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_language.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';

class EmergencyHelpScreen extends StatefulWidget {
  const EmergencyHelpScreen({super.key});

  @override
  State<EmergencyHelpScreen> createState() => _EmergencyHelpScreenState();
}

class _EmergencyHelpScreenState extends State<EmergencyHelpScreen> {
  List<Map<String, String>> _contacts = [];
  bool _isLocating = false;

  final List<Map<String, String>> _firstAidGuides = [
    {
      'title': 'Snakebite',
      'icon': '🐍',
      'content': '1. Keep victim calm and still.\n2. Do NOT cut or suck the wound.\n3. Wash with soap or water.\n4. Apply restrictive bandage above the bite limit venom flow.\n5. Seek hospital immediately (SOS).'
    },
    {
      'title': 'Severe Burns',
      'icon': '🔥',
      'content': '1. Remove from heat source.\n2. Cool with mild running water for 20 mins.\n3. Do NOT apply ice, creams, or oils.\n4. Cover loosely with sterile film or clean cloth.\n5. Call emergency line.'
    },
    {
      'title': 'CPR',
      'icon': '❤️',
      'content': '1. Check responsiveness and breathing.\n2. Call SOS/Ambulance.\n3. Push hard and fast in center of chest (100-120 beats/min).\n4. Allow chest to rise completely between compressions.'
    },
    {
      'title': 'Poisoning',
      'icon': '☠️',
      'content': '1. Move person to fresh air if inhaled.\n2. Do NOT induce vomiting unless told to do so.\n3. If swallowed, call poison control immediately.\n4. Keep poison container nearby for doctors.'
    }
  ];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('ice_contacts');
    if (data != null) {
      List<dynamic> json = jsonDecode(data);
      _contacts = json.map((e) => Map<String, String>.from(e)).toList();
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
    try {
      await launchUrl(uri);
    } catch (_) {}
  }

  Future<void> _triggerSOS() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location is disabled');
      }
      LocationPermission p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
        if (p == LocationPermission.denied || p == LocationPermission.deniedForever) {
          throw Exception('Permission denied');
        }
      }
      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      final mapsLink = "https://www.google.com/maps/search/?api=1&query=${pos.latitude},${pos.longitude}";
      final message = Uri.encodeComponent("EMERGENCY! I need immediate help. I am at this location: $mapsLink");

      // Extract custom contacts, or fallback to 102/108
      String phones = _contacts.map((c) => c['phone']).join(',');
      final uri = Uri.parse("sms:$phones?body=$message");
      await launchUrl(uri);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to trigger SOS: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _routeToNearestPHC() async {
    final uri = Uri.parse("https://www.google.com/maps/search/?api=1&query=hospital+clinic+PHC");
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showAddContactDialog() {
    final nameCtrl = TextEditingController();
    final relCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Emergency Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name (e.g., Son)')),
            TextField(controller: relCtrl, decoration: const InputDecoration(labelText: 'Relationship')),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number'), keyboardType: TextInputType.phone),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && phoneCtrl.text.isNotEmpty) {
                _saveContact(nameCtrl.text, relCtrl.text, phoneCtrl.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save Contact'),
          )
        ],
      ),
    );
  }

  void _showFirstAidDialog(Map<String, String> guide) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Text(guide['icon']!, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(guide['title']!),
          ],
        ),
        content: Text(guide['content']!, style: const TextStyle(fontSize: 15, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: AppColors.primaryAccent),
            child: const Text('Understood'),
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
          child: Column(
            children: [
              // Top Bar
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.secondaryBg,
                      ),
                      child: const Icon(Icons.arrow_back, color: AppColors.textDark, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Header
              const Icon(Icons.error_outline, size: 48, color: AppColors.emergency),
              const SizedBox(height: 12),
              Text(
                context.tr('emergency_help'),
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.emergency),
              ),
              const SizedBox(height: 6),
              Text(
                'One-tap lifeline features and offline emergency guides.',
                style: TextStyle(fontSize: 14, color: AppColors.textDark.withOpacity(0.6)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // SOS SMS Module
              GestureDetector(
                onTap: _isLocating ? null : _triggerSOS,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.emergency.withOpacity(0.1),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.emergency.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.emergency,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _isLocating 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Icon(Icons.emergency_share, size: 40, color: Colors.white),
                          const SizedBox(height: 8),
                          const Text(
                            'SEND SOS\n+ GPS',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: 1),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Offline First-Aid Section
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Offline First-Aid Guides',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _firstAidGuides.length,
                  itemBuilder: (context, index) {
                    final guide = _firstAidGuides[index];
                    return GestureDetector(
                      onTap: () => _showFirstAidDialog(guide),
                      child: Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primaryAccent.withOpacity(0.3))
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(guide['icon']!, style: const TextStyle(fontSize: 32)),
                            const SizedBox(height: 8),
                            Text(guide['title']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),

              // Options Grid (Call & Route)
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _handleCall('108'),
                      child: GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Icon(Icons.medical_services, size: 28, color: AppColors.emergency),
                            const SizedBox(height: 8),
                            Text(
                              context.tr('emergency_response'),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: _routeToNearestPHC,
                      child: GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Icon(Icons.location_on, size: 28, color: AppColors.primaryAccent),
                            const SizedBox(height: 8),
                            const Text(
                              'Nearest\nPHC',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Dynamic Emergency Contacts
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr('emergency_contacts'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark),
                  ),
                  TextButton.icon(
                    onPressed: _showAddContactDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add ICE'),
                  )
                ],
              ),
              const SizedBox(height: 12),
              GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: _contacts.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final contact = entry.value;
                    return Column(
                      children: [
                        _buildContactItem(contact['name'] ?? '', contact['relation'] ?? '', contact['phone'] ?? ''),
                        if (idx < _contacts.length - 1)
                          const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0x0D000000)),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactItem(String name, String relation, String phone) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark),
                ),
                Text(
                  relation,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _handleCall(phone),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondaryBg,
              ),
              child: const Icon(Icons.phone, size: 18, color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }
}
