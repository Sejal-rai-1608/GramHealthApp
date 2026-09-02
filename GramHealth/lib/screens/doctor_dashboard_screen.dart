import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/dashboard_layout.dart';
import '../widgets/stat_card.dart';
import '../widgets/status_badge.dart';
import '../widgets/glass_card.dart';
import '../l10n/app_language.dart';
import '../services/consultation_service.dart';
import '../services/auth_service.dart';

/// Doctor Dashboard – shows live KPI cards and a list of today's pending requests.
class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  bool _loading = true;
  String _doctorName = '';
  List<ConsultationModel> _all = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final user = await AuthService.getUser();
      final consultations = await ConsultationService.listDoctorConsultations(limit: 100);
      if (mounted) {
        setState(() {
          _doctorName = user?['name'] as String? ?? '';
          _all = consultations;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _accept(String id) async {
    try {
      await ConsultationService.acceptConsultation(id);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = _all.where((c) => c.status.toUpperCase() == 'PENDING').toList();
    final accepted = _all.where((c) => c.status.toUpperCase() == 'ACTIVE').toList();
    final completed = _all.where((c) => c.status.toUpperCase() == 'COMPLETED').toList();

    final kpiData = [
      {'icon': Icons.pending_actions, 'label': context.tr('pending_requests'),          'value': '${pending.length}'},
      {'icon': Icons.event_available,  'label': context.tr('today_appointments'),        'value': '${accepted.length}'},
      {'icon': Icons.people,           'label': context.tr('total_patients'),            'value': '${_all.length}'},
      {'icon': Icons.check_circle,     'label': context.tr('completed_consultations'),   'value': '${completed.length}'},
    ];

    return DashboardLayout(
      title: context.tr('doctor_dashboard'),
      child: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              Text(
                _doctorName.isNotEmpty
                    ? '${context.tr('good_morning_doctor')}, Dr. $_doctorName 👋'
                    : context.tr('good_morning_doctor'),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr('dashboard_subtitle'),
                style: const TextStyle(fontSize: 15, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // KPI cards
              if (_loading)
                const Center(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(),
                ))
              else if (_error != null)
                Center(child: Text('Error loading data', style: TextStyle(color: Colors.redAccent)))
              else
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: kpiData.map((d) => StatCard(
                    icon: d['icon'] as IconData,
                    label: d['label'] as String,
                    value: d['value'] as String,
                  )).toList(),
                ),

              const SizedBox(height: 32),

              // Pending requests
              Text(
                context.tr('pending_requests'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (pending.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('No pending requests', style: TextStyle(color: Colors.grey))),
                )
              else
                ...pending.map((c) => _PendingCard(consultation: c, onAccept: () => _accept(c.id))),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  final ConsultationModel consultation;
  final VoidCallback onAccept;
  const _PendingCard({required this.consultation, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    consultation.reason.isNotEmpty ? consultation.reason : 'General Consultation',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                  ),
                ),
                StatusBadge(status: consultation.status),
              ],
            ),
            if (consultation.symptoms != null && consultation.symptoms!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Symptoms: ${consultation.symptoms}',
                style: const TextStyle(fontSize: 13, color: AppColors.textDark),
              ),
            ],
            if (consultation.scheduledTime != null) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.access_time, size: 14, color: AppColors.leafGreenPrimary),
                const SizedBox(width: 4),
                Text(consultation.scheduledTime!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ]),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAccept,
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Accept'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.leafGreenPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
