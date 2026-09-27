import 'package:flutter/material.dart';
import '../l10n/app_language.dart';
import '../widgets/dashboard_layout.dart';
import '../widgets/empty_state.dart';
import '../theme/app_colors.dart';
import '../services/prescription_service.dart';
import 'prescription_list_screen.dart';

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
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.redAccent)))
                : _buildPrescriptionsList(),
      ),
    );
  }

  Widget _buildPrescriptionsList() {
    if (_prescriptions.isEmpty) {
      return ListView(
        children: const [
          EmptyState(title: 'No Prescriptions', subtitle: 'Prescriptions you write will appear here.')
        ]
      );
    }
    
    final Map<String, List<PrescriptionModel>> grouped = {};
    for (var p in _prescriptions) {
      grouped.putIfAbsent(p.patientName, () => []).add(p);
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: grouped.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16, top: 16),
            child: Text(
              context.tr('prescriptions'),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
          );
        }
        
        final patientName = grouped.keys.elementAt(index - 1);
        final pList = grouped[patientName]!;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            leading: const CircleAvatar(
              backgroundColor: AppColors.primaryAccent,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text(patientName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${pList.length} prescription(s) provided'),
            children: pList.map((p) => ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
              title: Text('Diagnosis: ${p.diagnosis}', style: const TextStyle(fontSize: 14)),
              subtitle: Text('Date: ${p.date}', style: const TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, size: 16),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => PrescriptionDetailScreen(prescription: p.toDisplayMap()),
                ));
              },
            )).toList(),
          ),
        );
      },
    );
  }
}
