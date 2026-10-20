import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_language.dart';
import '../../theme/app_colors.dart';
import '../../widgets/care_card.dart';

class MedicalRecordModel {
  final String id;
  final String date;
  final String doctor;
  final String illness;
  final String diagnosis;
  final String prescription;

  MedicalRecordModel({
    required this.id,
    required this.date,
    required this.doctor,
    required this.illness,
    required this.diagnosis,
    required this.prescription,
  });
}

class HealthRecordsScreen extends StatefulWidget {
  const HealthRecordsScreen({super.key});

  @override
  State<HealthRecordsScreen> createState() => _HealthRecordsScreenState();
}

class _HealthRecordsScreenState extends State<HealthRecordsScreen> {
  List<MedicalRecordModel> _records = [];
  bool _showAddModal = false;
  final _doctorCtrl = TextEditingController();
  final _illnessCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final records = <MedicalRecordModel>[];
    if (mounted) setState(() => _records = records);
  }

  void _addRecord() {
    final newRecord = MedicalRecordModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: _dateCtrl.text.isEmpty ? 'Today' : _dateCtrl.text,
      doctor: _doctorCtrl.text,
      illness: _illnessCtrl.text,
      diagnosis: _illnessCtrl.text,
      prescription: 'Prescribed by ${_doctorCtrl.text}',
    );
    setState(() {
      _records = [newRecord, ..._records];
      _showAddModal = false;
      _doctorCtrl.clear();
      _illnessCtrl.clear();
      _dateCtrl.clear();
      _timeCtrl.clear();
    });
  }

  @override
  void dispose() {
    _doctorCtrl.dispose();
    _illnessCtrl.dispose();
    _dateCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mock-only timeline — real ABDM vault lives in the Records tab (PatientRecordsScreen).
          // This screen is intentionally separate to avoid confusion with the vault.
          Text('Visit timeline (mock)', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
            Text('Demo only — use Records tab for ABDM vault',
                style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.inkMuted)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => setState(() => _showAddModal = true),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              // Progress tracker
              CareCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mock progress — scoped to this demo timeline, not the vault.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Demo progress',
                            style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(6)),
                          child: Text('60%', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.teal)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const LinearProgressIndicator(
                        value: 0.6,
                        minHeight: 6,
                        backgroundColor: AppColors.borderLight,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.teal),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Illustrative only',
                        style: GoogleFonts.manrope(fontSize: 11, color: AppColors.inkFaint)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (_records.isEmpty)
                CareCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(color: AppColors.groundAlt, shape: BoxShape.circle, border: Border.all(color: AppColors.borderLight)),
                        child: const Icon(Icons.folder_open_rounded, size: 24, color: AppColors.inkFaint),
                      ),
                      const SizedBox(height: 12),
                       Text('No timeline records', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
                       const SizedBox(height: 6),
                       Text('Add a demo visit here, or open the Records tab for real ABDM vault documents.',
                           textAlign: TextAlign.center,
                           style: GoogleFonts.manrope(fontSize: 12, color: AppColors.inkMuted, height: 1.5)),
                    ],
                  ),
                )
              else
                ...List.generate(_records.length, (i) => _buildRecordRow(i)),
            ],
          ),
          if (_showAddModal)
            GestureDetector(
              onTap: () => setState(() => _showAddModal = false),
              child: Container(
                color: Colors.black54,
                alignment: Alignment.center,
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    child: CareCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.tr('add_new_record'),
                              style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
                          const SizedBox(height: 16),
                          _formField(context.tr('doctor_name'), 'e.g. Dr. Rajesh', _doctorCtrl),
                          _formField(context.tr('illness_reason'), 'e.g. Fever', _illnessCtrl),
                          Row(
                            children: [
                              Expanded(child: _formField(context.tr('date'), 'Oct 15', _dateCtrl)),
                              const SizedBox(width: 10),
                              Expanded(child: _formField(context.tr('time'), '10:00 AM', _timeCtrl)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => setState(() => _showAddModal = false),
                                child: Text(context.tr('cancel'), style: GoogleFonts.manrope(fontSize: 13, color: AppColors.inkMuted, fontWeight: FontWeight.w700)),
                              ),
                              const SizedBox(width: 8),
                              FilledButton(
                                onPressed: _addRecord,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.teal,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                                  elevation: 0,
                                ),
                                child: Text(context.tr('save_record'), style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecordRow(int i) {
    final record = _records[i];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CareCard(
        onTap: () => context.push('/health-overview'),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(record.date, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.inkFaint)),
                const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.inkFaint),
              ],
            ),
            const SizedBox(height: 4),
            Text(record.doctor, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.groundAlt, borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('diagnosis'), style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.inkFaint)),
                  const SizedBox(height: 2),
                  Text(record.diagnosis, style: GoogleFonts.manrope(fontSize: 13, color: AppColors.ink)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.description_outlined, size: 14, color: AppColors.teal),
                const SizedBox(width: 6),
                Expanded(child: Text(record.prescription, style: GoogleFonts.manrope(fontSize: 12, color: AppColors.inkMuted))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _formField(String label, String hint, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.inkSoft)),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            style: GoogleFonts.manrope(fontSize: 14, color: AppColors.ink),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.manrope(color: AppColors.inkFaint, fontSize: 13),
              filled: true,
              fillColor: AppColors.groundAlt,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md), borderSide: const BorderSide(color: AppColors.borderLight)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md), borderSide: const BorderSide(color: AppColors.borderLight)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md), borderSide: const BorderSide(color: AppColors.tealDeep, width: 1.4)),
            ),
          ),
        ],
      ),
    );
  }
}
