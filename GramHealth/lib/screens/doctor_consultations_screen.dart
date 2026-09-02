import 'package:flutter/material.dart';
import '../l10n/app_language.dart';
import '../widgets/dashboard_layout.dart';
import '../widgets/glass_card.dart';
import '../widgets/status_badge.dart';
import '../widgets/empty_state.dart';
import '../theme/app_colors.dart';
import '../services/consultation_service.dart';
import '../services/call_service.dart';

class DoctorConsultationsScreen extends StatefulWidget {
  const DoctorConsultationsScreen({super.key});

  @override
  State<DoctorConsultationsScreen> createState() => _DoctorConsultationsScreenState();
}

class _DoctorConsultationsScreenState extends State<DoctorConsultationsScreen> {
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
      final data = await ConsultationService.listDoctorConsultations(limit: 50);
      if (mounted) setState(() { _consultations = data; _loading = false; });
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

  Future<void> _complete(String id) async {
    try {
      await ConsultationService.completeConsultation(id);
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
    return DashboardLayout(
      title: context.tr('consultations'),
      child: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.redAccent)))
                : _consultations.isEmpty
                    ? ListView(children: const [EmptyState(title: 'No Consultations', subtitle: 'Consultation requests from patients will appear here.')])
                    : ListView.builder(
                        itemCount: _consultations.length + 1,
                        itemBuilder: (context, i) {
                          if (i == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                context.tr('consultations'),
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
                              ),
                            );
                          }
                          final c = _consultations[i - 1];
                          return _buildCard(c);
                        },
                      ),
      ),
    );
  }

  Widget _buildCard(ConsultationModel c) {
    final isPending  = c.status.toUpperCase() == 'PENDING';
    final isAccepted = c.status.toUpperCase() == 'ACTIVE';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
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
                    c.reason.isNotEmpty ? c.reason : 'General Consultation',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                  ),
                ),
                StatusBadge(status: c.status),
              ],
            ),
            if (c.symptoms != null && c.symptoms!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Symptoms: ${c.symptoms}', style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
            ],
            if (c.scheduledTime != null) ...[
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.access_time, size: 15, color: AppColors.leafGreenPrimary),
                const SizedBox(width: 6),
                Text(c.scheduledTime!, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
              ]),
            ],
            if (isPending || isAccepted) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (isPending)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _accept(c.id),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Accept'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.leafGreenPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  if (isAccepted) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => CallService.startCall(
                          consultationId: c.id,
                          audioOnly: c.type.toUpperCase() == 'AUDIO',
                        ),
                        icon: Icon(c.type.toUpperCase() == 'AUDIO' ? Icons.call : Icons.videocam, size: 16),
                        label: Text(c.type.toUpperCase() == 'AUDIO' ? 'Audio Call' : 'Join Call'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _complete(c.id),
                        icon: const Icon(Icons.done_all, size: 16),
                        label: const Text('Complete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryAccent,
                          foregroundColor: AppColors.textDark,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
