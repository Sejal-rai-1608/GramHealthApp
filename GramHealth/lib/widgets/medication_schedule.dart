import 'package:flutter/material.dart';

class MedicationScheduleCard extends StatelessWidget {
  final Map<String, dynamic> medication;
  const MedicationScheduleCard({required this.medication, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(medication['name'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Dosage: ${medication['dosage'] ?? ''}'),
            Text('Frequency: ${medication['frequency'] ?? ''}'),
            Text('Timing: ${medication['timing'] ?? ''}'),
            Text('Duration: ${medication['duration'] ?? ''}'),
            Text('Food: ${medication['foodInstruction'] ?? ''}'),
          ],
        ),
      ),
    );
  }
}
