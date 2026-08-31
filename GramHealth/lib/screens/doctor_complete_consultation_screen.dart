import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/primary_button.dart';
import '../widgets/medicine_form_card.dart';

class DoctorCompleteConsultationScreen extends StatefulWidget {
  const DoctorCompleteConsultationScreen({Key? key}) : super(key: key);

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

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      // In a real app, you would call the backend API here.
      debugPrint('Consultation submitted');
      debugPrint('Symptoms: ${_symptomsCtrl.text}');
      debugPrint('Diagnosis: ${_diagnosisCtrl.text}');
      debugPrint('Notes: ${_notesCtrl.text}');
      debugPrint('Follow-up: $_followUpDate');
      debugPrint('Medicines: $_medicines');
      Navigator.of(context).pop();
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
                title: 'SUBMIT PRESCRIPTION ',
                onPress: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
