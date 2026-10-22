import 'package:flutter/material.dart';
import '../../widgets/dashboard_layout.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/status_badge.dart';
import '../../services/admin_service.dart';

class AdminFacilitiesScreen extends StatefulWidget {
  const AdminFacilitiesScreen({super.key});

  @override
  State<AdminFacilitiesScreen> createState() => _AdminFacilitiesScreenState();
}

class _AdminFacilitiesScreenState extends State<AdminFacilitiesScreen> {
  late Future<List<Map<String, dynamic>>> _facilitiesFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedType = '';

  @override
  void initState() {
    super.initState();
    _loadFacilities();
  }

  void _loadFacilities() {
    setState(() {
      _facilitiesFuture = AdminService.getFacilities(
        search: _searchQuery,
        type: _selectedType.isEmpty ? null : _selectedType,
      );
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
      title: 'Facility Management',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Healthcare Facilities',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Manage hospitals, PHCs, CHCs, and clinics',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Facility'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.leafGreenPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Search facilities by name or location...',
                              hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                              prefixIcon: Icon(Icons.search, color: AppColors.textMuted, size: 20),
                              border: InputBorder.none,
                            ),
                            onChanged: (value) {
                              _searchQuery = value;
                              _loadFacilities();
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedType.isEmpty ? null : _selectedType,
                            hint: const Text('All Types', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                            icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textMuted),
                            items: const [
                              DropdownMenuItem(value: 'HOSPITAL', child: Text('Hospital')),
                              DropdownMenuItem(value: 'PHC', child: Text('Primary Health Centre')),
                              DropdownMenuItem(value: 'CHC', child: Text('Community Health Centre')),
                              DropdownMenuItem(value: 'CLINIC', child: Text('Clinic')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedType = value ?? '';
                                _loadFacilities();
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _facilitiesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(color: AppColors.leafGreenPrimary),
                          );
                        }

                        if (snapshot.hasError) {
                          return _buildErrorState('Failed to load facilities');
                        }

                        final facilities = snapshot.data ?? [];

                        if (facilities.isEmpty) {
                          return _buildEmptyState('No facilities found');
                        }

                        return ListView.separated(
                          itemCount: facilities.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final fac = facilities[index];
                            final name = fac['name'] ?? 'Unknown Facility';
                            final type = fac['type'] ?? 'Unknown';
                            final address = fac['address'] ?? 'N/A';
                            final phone = fac['phone'] ?? 'N/A';
                            final isActive = fac['isActive'] == true;

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: AppColors.leafGreenPale,
                                child: const Icon(Icons.local_hospital, color: AppColors.leafGreenDeep),
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$type | Location: $address',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                  ),
                                  Text(
                                    'Contact: $phone',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  StatusBadge(status: isActive ? 'Active' : 'Inactive'),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: AppColors.textMuted),
                                    onPressed: () {},
                                  ),
                                ],
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

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_hospital_outlined, size: 64, color: AppColors.textMuted.withValues(alpha: 0.5)),
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
            onPressed: _loadFacilities,
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