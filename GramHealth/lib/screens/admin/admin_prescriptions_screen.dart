import 'package:flutter/material.dart';
import '../../widgets/dashboard_layout.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../services/admin_service.dart';

class AdminPrescriptionsScreen extends StatefulWidget {
  const AdminPrescriptionsScreen({super.key});

  @override
  State<AdminPrescriptionsScreen> createState() => _AdminPrescriptionsScreenState();
}

class _AdminPrescriptionsScreenState extends State<AdminPrescriptionsScreen> {
  late Future<List<Map<String, dynamic>>> _prescriptionsFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
  }

  void _loadPrescriptions() {
    setState(() {
      _prescriptionsFuture = AdminService.getPrescriptions(search: _searchQuery);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: 'Prescriptions Directory',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Prescriptions Record',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 4),
          const Text(
            'Monitor all prescriptions issued in the system',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search prescriptions by patient or medicine...',
                        hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        prefixIcon: Icon(Icons.search, color: AppColors.textMuted, size: 20),
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        _searchQuery = value;
                        _loadPrescriptions();
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _prescriptionsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(color: AppColors.leafGreenPrimary),
                          );
                        }

                        if (snapshot.hasError) {
                          return _buildErrorState('Failed to load prescriptions');
                        }

                        final prescriptions = snapshot.data ?? [];

                        if (prescriptions.isEmpty) {
                          return _buildEmptyState('No prescriptions found');
                        }

                        return ListView.separated(
                          itemCount: prescriptions.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final pres = prescriptions[index];
                            final patient = pres['patient'] as Map? ?? {};
                            final doctor = pres['doctor'] as Map? ?? {};
                            final patientUser = patient['user'] as Map? ?? {};
                            final doctorUser = doctor['user'] as Map? ?? {};
                            final patientName = patientUser['name'] ?? 'Unknown Patient';
                            final doctorName = doctorUser['name'] ?? 'Unknown Doctor';
                            final medicines = pres['medicines'] as List? ?? [];
                            final medNames = medicines.map((m) => m['name'] ?? '').where((n) => n.isNotEmpty).join(', ');
                            final createdAt = pres['createdAt'] ?? '';

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(
                                backgroundColor: AppColors.leafGreenPale,
                                child: Icon(Icons.description_outlined, color: AppColors.leafGreenDeep),
                              ),
                              title: Text(
                                'Prescription for $patientName',
                                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
                              ),
                              subtitle: Text(
                                'Issued by: Dr. $doctorName | Date: ${_formatDate(createdAt)}\nMeds: ${medNames.isEmpty ? "N/A" : medNames}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                              isThreeLine: true,
                              trailing: IconButton(
                                icon: const Icon(Icons.download_outlined, color: AppColors.textMuted),
                                onPressed: () {},
                              ),
                            );
                          },
                        );
                      },
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

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return 'N/A';
    }
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 64, color: AppColors.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 16, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.red.shade700),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadPrescriptions,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.leafGreenPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}