import 'package:flutter/material.dart';
import '../l10n/app_language.dart';
import '../widgets/dashboard_layout.dart';
import '../widgets/glass_card.dart';
import '../widgets/empty_state.dart';
import '../theme/app_colors.dart';
import '../services/consultation_service.dart';

/// Shows unique patients the doctor has consultations with (ACCEPTED or COMPLETED).
class DoctorPatientsScreen extends StatefulWidget {
  const DoctorPatientsScreen({super.key});

  @override
  State<DoctorPatientsScreen> createState() => _DoctorPatientsScreenState();
}

class _DoctorPatientsScreenState extends State<DoctorPatientsScreen> {
  bool _loading = true;
  List<ConsultationModel> _consultations = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Get all consultations (accepted + completed = patients we've seen/are seeing)
      final all = await ConsultationService.listDoctorConsultations(limit: 100);
      if (mounted) {
        setState(() {
          _consultations = all
              .where((c) => ['ACTIVE', 'COMPLETED'].contains(c.status.toUpperCase()))
              .toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: context.tr('patients'),
      child: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.redAccent)))
                : _consultations.isEmpty
                    ? ListView(children: const [EmptyState(title: 'No Patients Yet', subtitle: 'Accepted consultations will appear here.')])
                    : ListView.builder(
                        itemCount: _consultations.length + 1,
                        itemBuilder: (context, i) {
                          if (i == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                context.tr('patients'),
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
                              ),
                            );
                          }
                          final c = _consultations[i - 1];
                          return _buildPatientCard(c);
                        },
                      ),
      ),
    );
  }

  Widget _buildPatientCard(ConsultationModel c) {
    final initial = c.reason.isNotEmpty ? c.reason[0].toUpperCase() : 'P';
    final label   = c.reason.isNotEmpty ? c.reason : 'General Consultation';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.leafGreenPale,
              child: Text(
                initial,
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.leafGreenPrimary, fontSize: 18),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                  ),
                  if (c.symptoms != null && c.symptoms!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(c.symptoms!, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  ],
                  if (c.scheduledTime != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.leafGreenPale,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        c.scheduledTime!,
                        style: const TextStyle(color: AppColors.leafGreenPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Chip(
                label: Text(
                  c.status.toUpperCase() == 'COMPLETED' ? 'Done' : 'Active',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
                backgroundColor: c.status.toUpperCase() == 'COMPLETED'
                    ? Colors.grey.shade200
                    : AppColors.leafGreenPale,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
