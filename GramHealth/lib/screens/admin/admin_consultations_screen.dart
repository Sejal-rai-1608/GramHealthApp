import 'package:flutter/material.dart';
import '../../widgets/dashboard_layout.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/status_badge.dart';
import '../../services/admin_service.dart';

class AdminConsultationsScreen extends StatefulWidget {
  const AdminConsultationsScreen({super.key});

  @override
  State<AdminConsultationsScreen> createState() => _AdminConsultationsScreenState();
}

class _AdminConsultationsScreenState extends State<AdminConsultationsScreen> {
  late Future<List<Map<String, dynamic>>> _consultationsFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = '';

  @override
  void initState() {
    super.initState();
    _loadConsultations();
  }

  void _loadConsultations() {
    setState(() {
      _consultationsFuture = AdminService.getConsultations(search: _searchQuery, status: _statusFilter);
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
      title: 'Consultations Registry',
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
                    'Consultations Record',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'View past and active teleconsultation sessions',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                      hintText: 'Search consultations...',
                      hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                      prefixIcon: Icon(Icons.search, color: AppColors.textMuted, size: 20),
                      border: InputBorder.none,
                    ),
                    onChanged: (value) {
                      _searchQuery = value;
                      _loadConsultations();
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
                    value: _statusFilter.isEmpty ? null : _statusFilter,
                    hint: const Text('All Status', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                    icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textMuted),
                    items: const [
                      DropdownMenuItem(value: 'PENDING', child: Text('Pending')),
                      DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                      DropdownMenuItem(value: 'COMPLETED', child: Text('Completed')),
                      DropdownMenuItem(value: 'CANCELLED', child: Text('Cancelled')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _statusFilter = value ?? '';
                        _loadConsultations();
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _consultationsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.leafGreenPrimary),
                    );
                  }

                  if (snapshot.hasError) {
                    return _buildErrorState('Failed to load consultations');
                  }

                  final consultations = snapshot.data ?? [];

                  if (consultations.isEmpty) {
                    return _buildEmptyState('No consultations found');
                  }

                  return ListView.separated(
                    itemCount: consultations.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final cons = consultations[index];
                      final patient = cons['patient'] as Map<String, dynamic>? ?? {};
                      final doctor = cons['doctor'] as Map<String, dynamic>? ?? {};
                      final patientUser = patient['user'] as Map<String, dynamic>? ?? {};
                      final doctorUser = doctor['user'] as Map<String, dynamic>? ?? {};
                      
                      final patientName = patientUser['name'] ?? 'Unknown Patient';
                      final doctorName = doctorUser['name'] != null ? 'Dr. ${doctorUser['name']}' : 'Unassigned';
                      final type = cons['type'] ?? 'VIDEO';
                      final duration = cons['duration'] ?? '—';
                      final status = cons['status'] ?? 'PENDING';
                      final riskLevel = cons['riskLevel'] != null ? 'Risk: ${cons['riskLevel']}' : '';

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: AppColors.leafGreenPale,
                          child: const Icon(Icons.chat_bubble_outline, color: AppColors.leafGreenDeep),
                        ),
                        title: Text(
                          '$patientName with $doctorName',
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Type: $type • Duration: $duration',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                            if (riskLevel.isNotEmpty)
                              Text(
                                riskLevel,
                                style: const TextStyle(fontSize: 11, color: Colors.orange),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            StatusBadge(status: status),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.chevron_right, color: AppColors.textMuted),
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
          Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.textMuted.withValues(alpha: 0.5)),
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
            onPressed: _loadConsultations,
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