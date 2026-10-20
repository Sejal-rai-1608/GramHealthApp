import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_language.dart';
import '../../widgets/dashboard_layout.dart';
import '../../widgets/care_card.dart';
import '../../widgets/empty_state.dart';
import '../../theme/app_colors.dart';
import '../../services/consultation_service.dart';

/// Shows unique patients the doctor has consultations with (ACTIVE or COMPLETED).
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
      final all = await ConsultationService.listDoctorConsultations(limit: 100);
      if (mounted) {
        setState(() {
          _consultations = all.where((c) => ['ACTIVE', 'COMPLETED'].contains(c.status.toUpperCase())).toList();
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
        color: AppColors.teal,
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
            : _error != null
                ? Center(child: Text('Error: $_error', style: GoogleFonts.manrope(color: AppColors.emergency)))
                : _consultations.isEmpty
                    ? ListView(children: const [EmptyState(title: 'No Patients Yet', subtitle: 'Accepted consultations will appear here.')])
                    : ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _consultations.length + 1,
                        itemBuilder: (context, i) {
                          if (i == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                context.tr('patients'),
                                style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink),
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
    final label = c.reason.isNotEmpty ? c.reason : 'General Consultation';
    final isDone = c.status.toUpperCase() == 'COMPLETED';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: CareCard(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.mint,
              child: Text(
                initial,
                style: GoogleFonts.manrope(fontWeight: FontWeight.w800, color: AppColors.teal, fontSize: 18),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.ink)),
                  if (c.symptoms != null && c.symptoms!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(c.symptoms!, style: GoogleFonts.manrope(color: AppColors.inkMuted, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                  if (c.scheduledTime != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.mint,
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                        border: Border.all(color: AppColors.tealPale),
                      ),
                      child: Text(
                        c.scheduledTime!,
                        style: GoogleFonts.manrope(color: AppColors.tealDeep, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: StatusChip(
                label: isDone ? 'Done' : 'Active',
                dotColor: isDone ? AppColors.inkFaint : AppColors.teal,
                bg: isDone ? AppColors.surfaceDim : AppColors.tealWash,
                fg: isDone ? AppColors.inkMuted : AppColors.tealDeep,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
