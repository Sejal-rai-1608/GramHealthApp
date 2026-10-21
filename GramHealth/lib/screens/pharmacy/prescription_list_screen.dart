import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/prescription_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/care_icon_button.dart';
import '../../widgets/care_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/medication_schedule.dart';

class PrescriptionListScreen extends StatefulWidget {
  const PrescriptionListScreen({super.key});

  @override
  State<PrescriptionListScreen> createState() => _PrescriptionListScreenState();
}

class _PrescriptionListScreenState extends State<PrescriptionListScreen> {
  List<PrescriptionModel> _prescriptions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
  }

  Future<void> _loadPrescriptions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final role = await AuthService.getCurrentRole();
      final data = role == 'doctor'
          ? await PrescriptionService.getDoctorPrescriptions()
          : await PrescriptionService.getPrescriptions();
      if (mounted)
        setState(() {
          _prescriptions = data;
          _isLoading = false;
        });
    } on ApiException catch (e) {
      if (mounted)
        setState(() {
          _error = e.message;
          _isLoading = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _error = 'Failed to load prescriptions.';
          _isLoading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: CareIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.of(context).canPop()
                ? Navigator.of(context).pop()
                : context.go('/main/home'),
            tooltip: 'Back',
            iconSize: 18,
            size: 44,
          ),
        ),
        leadingWidth: 56,
        title: Text('Prescriptions',
            style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.ink)),
        centerTitle: false,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColors.ink),
              onPressed: _loadPrescriptions),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading
          ? const LoadingState(message: 'Loading prescriptions…')
          : _error != null
              ? EmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: 'Unable to load',
                  subtitle: _error!,
                  actionLabel: 'Retry',
                  onAction: _loadPrescriptions)
              : _prescriptions.isEmpty
                  ? const EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No prescriptions yet',
                      subtitle:
                          'Your prescriptions from consultations will appear here.')
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      itemCount: _prescriptions.length,
                      itemBuilder: (_, i) {
                        final pres = _prescriptions[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: CareCard(
                            onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => PrescriptionDetailScreen(
                                        prescription: pres.toDisplayMap()))),
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                        color: AppColors.mint,
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: const Icon(
                                        Icons.receipt_long_rounded,
                                        size: 18,
                                        color: AppColors.teal)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(pres.doctorName,
                                          style: GoogleFonts.manrope(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.ink)),
                                      const SizedBox(height: 2),
                                      Text(
                                          '${pres.specialization}  •  ${pres.date}',
                                          style: GoogleFonts.manrope(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.inkMuted)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded,
                                    size: 18, color: AppColors.inkFaint),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

class PrescriptionDetailScreen extends StatelessWidget {
  final Map<String, dynamic> prescription;
  const PrescriptionDetailScreen({required this.prescription, super.key});

  @override
  Widget build(BuildContext context) {
    final medicines = prescription['medicines'] as List<dynamic>;
    return Scaffold(
      backgroundColor: AppColors.ground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Prescription',
            style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.ink)),
        centerTitle: false,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
            onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CareCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (prescription['patientName'] != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('Patient: ${prescription['patientName']}',
                          style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.teal)),
                    ),
                  _kv('Doctor', prescription['doctorName']?.toString() ?? '—'),
                  const SizedBox(height: 6),
                  _kv('Specialization',
                      prescription['specialization']?.toString() ?? '—'),
                  const SizedBox(height: 6),
                  _kv('Date', prescription['date']?.toString() ?? '—'),
                  const SizedBox(height: 6),
                  _kv('Diagnosis',
                      prescription['diagnosis']?.toString() ?? '—'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Medicines',
                style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink)),
            const SizedBox(height: 10),
            ...medicines.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: MedicationScheduleCard(medication: m))),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 110,
              child: Text(k,
                  style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkFaint))),
          Expanded(
              child: Text(v,
                  style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink))),
        ],
      );
}
