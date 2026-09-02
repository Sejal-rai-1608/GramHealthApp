import 'package:flutter/material.dart';
import '../l10n/app_language.dart';
import '../theme/app_colors.dart';
import '../widgets/dashboard_layout.dart';
import '../widgets/glass_card.dart';
import '../services/consultation_service.dart';

/// Shows all PENDING consultation requests that the logged-in doctor can accept.
/// Includes both assigned (to this doctor) and unassigned (open pool) requests.
class DoctorRequestsScreen extends StatefulWidget {
  const DoctorRequestsScreen({super.key});

  @override
  State<DoctorRequestsScreen> createState() => _DoctorRequestsScreenState();
}

class _DoctorRequestsScreenState extends State<DoctorRequestsScreen> {
  bool _loading = true;
  List<ConsultationModel> _requests = [];
  String? _error;
  // Track which IDs are being accepted to avoid double-tap
  final Set<String> _accepting = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Fetch PENDING only — the backend now returns unassigned + assigned-to-me
      final list = await ConsultationService.listDoctorConsultations(
        status: 'PENDING',
        limit: 100,
      );
      if (mounted) setState(() { _requests = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _accept(String id) async {
    setState(() => _accepting.add(id));
    try {
      await ConsultationService.acceptConsultation(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Consultation accepted! Status changed to ACTIVE.'),
          backgroundColor: AppColors.leafGreenPrimary,
          behavior: SnackBarBehavior.floating,
        ));
        _load(); // Refresh — the accepted one will disappear from PENDING list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to accept: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _accepting.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: context.tr('pending_requests'),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
                      const SizedBox(height: 8),
                      Text('Could not load requests', style: const TextStyle(color: Colors.redAccent)),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        onPressed: _load,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _requests.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.55,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.inbox_outlined, size: 56, color: Colors.grey[350]),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No pending requests',
                                      style: TextStyle(fontSize: 16, color: Colors.grey[500], fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'New patient requests will appear here',
                                      style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _requests.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) => _buildCard(_requests[i]),
                        ),
                ),
    );
  }

  Widget _buildCard(ConsultationModel c) {
    final patientInitial = (c.patientName?.isNotEmpty ?? false)
        ? c.patientName![0].toUpperCase()
        : '?';
    final isAccepting = _accepting.contains(c.id);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient info row
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.leafGreenPale,
                child: Text(
                  patientInitial,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.leafGreenPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.patientName ?? 'Patient',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Unassigned badge
                    if (c.doctorId == null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Open request · first-come-first-served',
                          style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.w600),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.leafGreenPrimary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Requested you directly',
                          style: TextStyle(fontSize: 10, color: AppColors.leafGreenPrimary, fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ),
              // PENDING chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'PENDING',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.amber),
                ),
              ),
            ],
          ),

          // Reason / notes
          if (c.reason.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.notes_outlined, size: 16, color: AppColors.leafGreenPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    c.reason,
                    style: const TextStyle(fontSize: 13, color: AppColors.textDark),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          // Symptoms
          if ((c.symptoms ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.sick_outlined, size: 16, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    c.symptoms!,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 14),

          // Accept button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isAccepting ? null : () => _accept(c.id),
              icon: isAccepting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_outline, size: 18),
              label: Text(isAccepting ? 'Accepting...' : 'Accept Consultation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.leafGreenPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                disabledBackgroundColor: AppColors.leafGreenPrimary.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
