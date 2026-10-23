import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/primary_button.dart';
import '../widgets/medicine_form_card.dart';
import '../services/consultation_service.dart';
import '../services/api_client.dart';
import '../services/prescription_service.dart';

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
  bool _isSubmitting = false;

  // List of medicine maps
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
    if (!(_formKey.currentState?.validate() ?? false) || _isSubmitting) return;

    if (_medicines.isNotEmpty) {
      for (var med in _medicines) {
        if ((med['name']?.trim().isEmpty ?? true) ||
            (med['dosage']?.trim().isEmpty ?? true) ||
            (med['frequency']?.trim().isEmpty ?? true) ||
            (med['duration']?.trim().isEmpty ?? true)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please fill all required medicine fields (Name, Dosage, Frequency, Duration)'), backgroundColor: Colors.red),
          );
          return;
        }
      }
    }

    final mappedMedicines = _medicines.map<Map<String, dynamic>>((m) {
      final timing = m['timing']?.trim() ?? '';
      final food = m['foodInstruction']?.trim() ?? '';
      final extras = [timing, food].where((e) => e.isNotEmpty).join(' - ');

      return {
        'name': m['name']?.trim() ?? '',
        'dosage': m['dosage']?.trim() ?? '',
        'frequency': m['frequency']?.trim() ?? '',
        'duration': m['duration']?.trim() ?? '',
        'timing': timing,
        'foodInstruction': food,
        'instructions': extras,
      };
    }).toList();

    setState(() => _isSubmitting = true);
    try {
      // Create the prescription first for compatibility with already deployed
      // backends. The current backend is idempotent and its completion
      // transaction reuses this prescription instead of duplicating it.
      if (mappedMedicines.isNotEmpty) {
        await PrescriptionService.createPrescription(
          consultationId: widget.consultationId,
          medicines: mappedMedicines,
          instructions: _notesCtrl.text.trim(),
          followUpDate: _followUpDate?.toUtc().toIso8601String(),
        );
      }

      await ConsultationService.completeConsultation(
        widget.consultationId,
        symptoms: _symptomsCtrl.text.trim(),
        notes: _diagnosisCtrl.text.trim(),
        riskLevel: 'LOW',
        medicines: mappedMedicines.isEmpty ? null : mappedMedicines,
        prescriptionInstructions: _notesCtrl.text.trim(),
        followUpDate: _followUpDate?.toUtc().toIso8601String(),
      );
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to complete consultation: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _symptomsCtrl.dispose();
    _diagnosisCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondaryBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Complete Consultation',
            style: TextStyle(color: AppColors.textDark)),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _symptomsCtrl,
                decoration: const InputDecoration(labelText: 'Symptoms'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter symptoms' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _diagnosisCtrl,
                decoration: const InputDecoration(labelText: 'Diagnosis'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter diagnosis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                    labelText: "Doctor's Observations / Notes"),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Follow-up Date'),
                subtitle: Text(_followUpDate == null
                    ? 'Not set'
                    : _followUpDate!.toLocal().toString().split(' ')[0]),
                trailing: const Icon(Icons.calendar_today),
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
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Medicines',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  TextButton.icon(
                    onPressed: _addMedicine,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Medicine'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._medicines.asMap().entries.map((e) => MedicineFormCard(
                    index: e.key,
                    data: e.value,
                    onChanged: (newData) =>
                        setState(() => _medicines[e.key] = newData),
                    onRemove: () => _removeMedicine(e.key),
                  )),
              const SizedBox(height: 24),
              PrimaryButton(
                title: _isSubmitting ? 'SAVING...' : 'SUBMIT PRESCRIPTION ',
                onPress: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
