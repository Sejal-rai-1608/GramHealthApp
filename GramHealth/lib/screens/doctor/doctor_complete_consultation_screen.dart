import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/care_card.dart';
import '../../widgets/medicine_form_card.dart';
import '../../services/consultation_service.dart';
import '../../services/prescription_service.dart';

class DoctorCompleteConsultationScreen extends StatefulWidget {
  final String consultationId;
  const DoctorCompleteConsultationScreen({Key? key, required this.consultationId}) : super(key: key);

  @override
  State<DoctorCompleteConsultationScreen> createState() =>
      _DoctorCompleteConsultationScreenState();
}

class _DoctorCompleteConsultationScreenState
    extends State<DoctorCompleteConsultationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _symptomsCtrl = TextEditingController();
  final TextEditingController _diagnosisCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  DateTime? _followUpDate;

  final List<Map<String, String>> _medicines = [];

  void _addMedicine() {
    setState(() {
      _medicines.add({
        'name': '',
        'dosage': '',
        'frequency': '',
        'timing': '',
        'duration': '',
        'foodInstruction': '',
      });
    });
  }

  void _removeMedicine(int index) {
    setState(() {
      _medicines.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      for (var med in _medicines) {
        if ((med['name']?.trim().isEmpty ?? true) ||
            (med['dosage']?.trim().isEmpty ?? true) ||
            (med['frequency']?.trim().isEmpty ?? true) ||
            (med['duration']?.trim().isEmpty ?? true)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please fill all required medicine fields (Name, Dosage, Frequency, Duration)'), backgroundColor: AppColors.emergency),
          );
          return;
        }
      }

      final mappedMedicines = _medicines.map((m) {
        final timing = m['timing']?.trim() ?? '';
        final food = m['foodInstruction']?.trim() ?? '';
        final extras = [timing, food].where((e) => e.isNotEmpty).join(' - ');
        return {
          'name': m['name']?.trim(),
          'dosage': m['dosage']?.trim(),
          'frequency': m['frequency']?.trim(),
          'duration': m['duration']?.trim(),
          'instructions': extras.isNotEmpty ? extras : '',
        };
      }).toList();

      await PrescriptionService.createPrescription(
        consultationId: widget.consultationId,
        medicines: mappedMedicines,
        instructions: _notesCtrl.text,
      );

      await ConsultationService.completeConsultation(
        widget.consultationId,
        notes: _diagnosisCtrl.text,
        riskLevel: 'LOW',
      );
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _symptomsCtrl.dispose();
    _diagnosisCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: GoogleFonts.manrope(color: AppColors.inkMuted, fontWeight: FontWeight.w600, fontSize: 13),
      hintStyle: GoogleFonts.manrope(color: AppColors.inkFaint, fontSize: 13),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md), borderSide: const BorderSide(color: AppColors.borderLight)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md), borderSide: const BorderSide(color: AppColors.borderLight)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md), borderSide: const BorderSide(color: AppColors.teal, width: 1.4)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text('Complete Consultation',
            style: GoogleFonts.manrope(color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 17)),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.borderLight),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CareCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Clinical Details', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _symptomsCtrl,
                      style: GoogleFonts.manrope(fontSize: 14, color: AppColors.ink),
                      decoration: _dec('Symptoms', hint: 'Enter observed symptoms'),
                      validator: (v) => v == null || v.isEmpty ? 'Enter symptoms' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _diagnosisCtrl,
                      style: GoogleFonts.manrope(fontSize: 14, color: AppColors.ink),
                      decoration: _dec('Diagnosis', hint: 'Enter diagnosis'),
                      validator: (v) => v == null || v.isEmpty ? 'Enter diagnosis' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _notesCtrl,
                      style: GoogleFonts.manrope(fontSize: 14, color: AppColors.ink),
                      decoration: _dec("Doctor's Observations / Notes", hint: 'Add notes for the patient record'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.mintLight,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: ListTile(
                        title: Text('Follow-up Date', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
                        subtitle: Text(_followUpDate == null
                            ? 'Not set'
                            : _followUpDate!.toLocal().toString().split(' ')[0],
                            style: GoogleFonts.manrope(fontSize: 13, color: AppColors.inkMuted)),
                        trailing: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.borderLight)),
                          child: const Icon(Icons.calendar_today, size: 18, color: AppColors.teal),
                        ),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(const Duration(days: 1)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() => _followUpDate = picked);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Medicines',
                      style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
                  FilledButton.icon(
                    onPressed: _addMedicine,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text('Add Medicine', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 13)),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.mint,
                      foregroundColor: AppColors.tealDeep,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.pill)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._medicines.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: MedicineFormCard(
                      index: e.key,
                      data: e.value,
                      onChanged: (newData) => setState(() => _medicines[e.key] = newData),
                      onRemove: () => _removeMedicine(e.key),
                    ),
                  )),
              const SizedBox(height: 8),
              PrimaryButton(
                title: 'SUBMIT PRESCRIPTION',
                onPress: _submit,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
