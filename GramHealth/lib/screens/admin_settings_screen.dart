import 'package:flutter/material.dart';
import '../widgets/dashboard_layout.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _maintenanceMode = false;
  bool _autoApproveDoctors = false;
  bool _smsAlerts = true;

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: 'Admin Settings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Configuration',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 4),
          const Text(
            'Configure global telemedicine parameters and system features',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  SwitchListTile(
                    title: const Text('Maintenance Mode', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark)),
                    subtitle: const Text('Restrict standard user access during system updates', style: TextStyle(fontSize: 12)),
                    value: _maintenanceMode,
                    activeColor: AppColors.leafGreenPrimary,
                    onChanged: (val) {
                      setState(() {
                        _maintenanceMode = val;
                      });
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Auto-Approve Doctors', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark)),
                    subtitle: const Text('Automatically verify doctor accounts upon registration', style: TextStyle(fontSize: 12)),
                    value: _autoApproveDoctors,
                    activeColor: AppColors.leafGreenPrimary,
                    onChanged: (val) {
                      setState(() {
                        _autoApproveDoctors = val;
                      });
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('SMS / WhatsApp Alerts', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark)),
                    subtitle: const Text('Send mobile reminders for scheduled appointments to patients', style: TextStyle(fontSize: 12)),
                    value: _smsAlerts,
                    activeColor: AppColors.leafGreenPrimary,
                    onChanged: (val) {
                      setState(() {
                        _smsAlerts = val;
                      });
                    },
                  ),
                  const Divider(),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Settings saved successfully')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.leafGreenPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Save Settings', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
