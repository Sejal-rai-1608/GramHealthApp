import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_language.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';

class EmergencyHelpScreen extends StatelessWidget {
  const EmergencyHelpScreen({super.key});

  Future<void> _handleCall(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
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
                context.tr('emergency_subtitle'),
                style: TextStyle(fontSize: 14, color: AppColors.textDark.withValues(alpha: 0.6)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Big Pulsing Emergency Call Button
              GestureDetector(
                onTap: () => _handleCall('102'),
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.emergency.withValues(alpha: 0.1),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.emergency.withValues(alpha: 0.3),
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
                          const Icon(Icons.phone_in_talk, size: 40, color: Colors.white),
                          const SizedBox(height: 8),
                          Text(
                            context.tr('call_ambulance'),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 1),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '102',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 32),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Options Grid
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _handleCall('108'),
                      child: GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Icon(Icons.add_circle_outline, size: 28, color: AppColors.emergency),
                            const SizedBox(height: 8),
                            Text(
                              context.tr('emergency_response'),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '108',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.emergency),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _handleCall('102'),
                      child: GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 28, color: AppColors.textDark),
                            const SizedBox(height: 8),
                            Text(
                              context.tr('nearest_hospital'),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.tr('find_nearby_care'),
                              style: TextStyle(fontSize: 12, color: AppColors.textDark.withValues(alpha: 0.6)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Emergency Contacts
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  context.tr('emergency_contacts'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark),
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildContactItem('Village Sarpanch', 'Local Authority', '9999999999'),
                    const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0x0D000000)),
                    _buildContactItem('Ramesh (Son)', 'Family Member', '8888888888'),
                  ],
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
          Column(
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
