import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/medication_schedule.dart';

class PrescriptionListScreen extends StatelessWidget {
  const PrescriptionListScreen({super.key});

  // Mock prescription data
  final List<Map<String, dynamic>> prescriptions = const [
    {
      'id': 'p1',
      'doctorName': 'Dr. Anita Joshi',
      'specialization': 'General Physician',
      'date': '2024-09-12',
      'diagnosis': 'Common Cold',
      'medicines': [
        {
          'name': 'Paracetamol',
          'dosage': '500 mg',
          'frequency': '2 times a day',
          'timing': 'Morning & Night',
          'duration': '5 days',
          'foodInstruction': 'After food',
        },
        {
          'name': 'Cetirizine',
          'dosage': '10 mg',
          'frequency': 'Once a day',
          'timing': 'Morning',
          'duration': '7 days',
          'foodInstruction': 'Before food',
        },
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Prescriptions'),
        backgroundColor: AppColors.primaryAccent,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: prescriptions.length,
        itemBuilder: (context, index) {
          final pres = prescriptions[index];
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text(pres['doctorName']),
              subtitle: Text("${pres['specialization']} • ${pres['date']}") ,
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => PrescriptionDetailScreen(prescription: pres),
                ));
              },
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
      appBar: AppBar(
        title: const Text('Prescription Details'),
        backgroundColor: AppColors.primaryAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Doctor: ${prescription['doctorName']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Specialization: ${prescription['specialization']}'),
            const SizedBox(height: 8),
            Text('Date: ${prescription['date']}'),
            const SizedBox(height: 8),
            Text('Diagnosis: ${prescription['diagnosis']}'),
            const Divider(height: 32),
            const Text('Medicines', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ...medicines.map((m) => MedicationScheduleCard(medication: m)),
          ],
        ),
      ),
    );
  }
}
