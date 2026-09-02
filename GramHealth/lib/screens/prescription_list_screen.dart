import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/prescription_service.dart';
import '../theme/app_colors.dart';
import '../widgets/medication_schedule.dart';

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
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await PrescriptionService.getPrescriptions();
      if (mounted) setState(() { _prescriptions = data; _isLoading = false; });
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Failed to load prescriptions.'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Prescriptions'),
        backgroundColor: AppColors.primaryAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPrescriptions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off, color: Colors.grey, size: 48),
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: const TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: _loadPrescriptions,
                          child: const Text('Retry')),
                    ],
                  ),
                )
              : _prescriptions.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              color: Colors.grey, size: 48),
                          SizedBox(height: 12),
                          Text('No prescriptions found.',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _prescriptions.length,
                      itemBuilder: (context, index) {
                        final pres = _prescriptions[index];
                        return Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(pres.doctorName),
                            subtitle:
                                Text('${pres.specialization} • ${pres.date}'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => PrescriptionDetailScreen(
                                    prescription: pres.toDisplayMap()),
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
  const PrescriptionDetailScreen(
      {required this.prescription, super.key});

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
            Text('Doctor: ${prescription['doctorName']}',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Specialization: ${prescription['specialization']}'),
            const SizedBox(height: 8),
            Text('Date: ${prescription['date']}'),
            const SizedBox(height: 8),
            Text('Diagnosis: ${prescription['diagnosis']}'),
            const Divider(height: 32),
            const Text('Medicines',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ...medicines
                .map((m) => MedicationScheduleCard(medication: m)),
          ],
        ),
      ),
    );
  }
}
