import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_language.dart';
import '../../widgets/dashboard_layout.dart';
import '../../widgets/care_card.dart';
import '../../widgets/empty_state.dart';
import '../../theme/app_colors.dart';
import '../../services/prescription_service.dart';
import '../pharmacy/prescription_list_screen.dart';

class DoctorPrescriptionsScreen extends StatefulWidget {
  const DoctorPrescriptionsScreen({super.key});

  @override
  State<DoctorPrescriptionsScreen> createState() => _DoctorPrescriptionsScreenState();
}

class _DoctorPrescriptionsScreenState extends State<DoctorPrescriptionsScreen> {
  bool _loading = true;
  List<PrescriptionModel> _prescriptions = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await PrescriptionService.getDoctorPrescriptions(limit: 50);
      if (mounted) setState(() { _prescriptions = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: context.tr('prescriptions'),
      child: RefreshIndicator(
        color: AppColors.teal,
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
            : _error != null
                ? Center(child: Text('Error: $_error', style: GoogleFonts.manrope(color: AppColors.emergency)))
                : _buildPrescriptionsList(),
      ),
    );
  }

  Widget _buildPrescriptionsList() {
    if (_prescriptions.isEmpty) {
      return ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          EmptyState(title: 'No Prescriptions', subtitle: 'Prescriptions you write will appear here.')
        ],
      );
    }

    final Map<String, List<PrescriptionModel>> grouped = {};
    for (var p in _prescriptions) {
      grouped.putIfAbsent(p.patientName, () => []).add(p);
    }

    return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      itemCount: grouped.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16, top: 4),
            child: Text(
              context.tr('prescriptions'),
              style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
          );
        }

        final patientName = grouped.keys.elementAt(index - 1);
        final pList = grouped[patientName]!;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CareCard(
            padding: EdgeInsets.zero,
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                childrenPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.mint,
                  child: const Icon(Icons.person, color: AppColors.teal, size: 20),
                ),
                title: Text(patientName, style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.ink)),
                subtitle: Text('${pList.length} prescription(s) provided',
                    style: GoogleFonts.manrope(fontSize: 12, color: AppColors.inkMuted)),
                iconColor: AppColors.teal,
                collapsedIconColor: AppColors.inkFaint,
                children: [
                  const Divider(height: 1, color: AppColors.borderLight),
                  ...pList.map((p) => ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        title: Text('Diagnosis: ${p.diagnosis}',
                            style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
                        subtitle: Text('Date: ${p.date}', style: GoogleFonts.manrope(fontSize: 12, color: AppColors.inkMuted)),
                        trailing: Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(color: AppColors.mintLight, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.chevron_right, size: 16, color: AppColors.teal),
                        ),
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => PrescriptionDetailScreen(prescription: p.toDisplayMap()),
                          ));
                        },
                      )),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
