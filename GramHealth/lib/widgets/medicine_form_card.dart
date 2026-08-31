import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class MedicineFormCard extends StatelessWidget {
  final int index;
  final Map<String, String> data;
  final ValueChanged<Map<String, String>> onChanged;
  final VoidCallback onRemove;

  const MedicineFormCard({
    required this.index,
    required this.data,
    required this.onChanged,
    required this.onRemove,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Medicine ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w600)),
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: onRemove,
                ),
              ],
            ),
            _field('Name', data['name'] ?? '', (v) => _update('name', v)),
            _field('Dosage', data['dosage'] ?? '', (v) => _update('dosage', v)),
            _field('Frequency', data['frequency'] ?? '', (v) => _update('frequency', v)),
            _field('Timing', data['timing'] ?? '', (v) => _update('timing', v)),
            _field('Duration', data['duration'] ?? '', (v) => _update('duration', v)),
            _field('Food Instruction', data['foodInstruction'] ?? '', (v) => _update('foodInstruction', v)),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, String initial, ValueChanged<String> onChanged) {
    return TextFormField(
      initialValue: initial,
      decoration: InputDecoration(labelText: label),
      onChanged: onChanged,
    );
  }

  void _update(String key, String value) {
    final newData = Map<String, String>.from(data);
    newData[key] = value;
    onChanged(newData);
  }
}
