import 'package:flutter/material.dart';
import '../services/call_service.dart';
import '../services/consultation_service.dart';
import '../services/connectivity_service.dart';
import '../widgets/dashboard_layout.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_badge.dart';
import '../widgets/voice_note_dialog.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  State<DoctorAppointmentsScreen> createState() => _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> {
  bool _loading = true;
  String? _error;
  List<ConsultationModel> _appointments = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final consultations = await ConsultationService.listDoctorConsultations(limit: 100);
      if (!mounted) return;
      setState(() {
        _appointments = consultations
            .where((consultation) => consultation.scheduledAt != null || consultation.scheduledTime != null)
            .toList()
          ..sort((a, b) {
            final aDate = a.scheduledAt == null ? null : DateTime.tryParse(a.scheduledAt!);
            final bDate = b.scheduledAt == null ? null : DateTime.tryParse(b.scheduledAt!);
            if (aDate == null || bDate == null) return 0;
            return aDate.compareTo(bDate);
          });
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _accept(ConsultationModel consultation) async {
    try {
      await ConsultationService.acceptConsultation(consultation.id);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to accept appointment: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _join(ConsultationModel consultation) async {
    var carrierAttempted = false;
    try {
      final status = await ConnectivityService.instance.refresh();
      if (status == NetworkStatus.offline || consultation.type.toUpperCase() == 'OFFLINE') {
        final phone = consultation.patientPhone;
        if (phone != null && phone.trim().isNotEmpty) {
          carrierAttempted = true;
          await CallService.startPhoneCall(phone);
        } else if (mounted) {
          await showDialog(
            context: context,
            builder: (context) => VoiceNoteDialog(consultationId: consultation.id),
          );
        }
        return;
      }

      await CallService.startCall(
        consultationId: consultation.id,
        audioOnly: consultation.type.toUpperCase() == 'AUDIO',
      );
    } on CallServiceException catch (e) {
      final phone = consultation.patientPhone;
      if (!carrierAttempted && phone != null && phone.trim().isNotEmpty) {
        try {
          await CallService.startPhoneCall(phone);
          return;
        } catch (_) {
          // Fall through to the visible error below when carrier calling is
          // unavailable on this device.
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to join appointment: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: 'Doctor Appointments',
      child: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(children: [Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))])
                : _appointments.isEmpty
                    ? ListView(children: const [EmptyState(title: 'No scheduled appointments', subtitle: 'Accepted appointments with a selected date will appear here.')])
                    : ListView.builder(
                        itemCount: _appointments.length,
                        itemBuilder: (context, index) {
                          final appointment = _appointments[index];
                          final status = appointment.status.toUpperCase();
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          appointment.reason.isNotEmpty ? appointment.reason : 'Consultation',
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      StatusBadge(status: appointment.status),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Patient: ${appointment.patientName ?? 'Patient'}'),
                                  const SizedBox(height: 4),
                                  Text('Scheduled: ${appointment.scheduledTime ?? 'Time not set'}'),
                                  const SizedBox(height: 12),
                                  if (status == 'PENDING')
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () => _accept(appointment),
                                        icon: const Icon(Icons.check),
                                        label: const Text('Accept appointment'),
                                      ),
                                    )
                                  else if (status == 'ACTIVE')
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () => _join(appointment),
                                        icon: Icon(appointment.type.toUpperCase() == 'AUDIO' ? Icons.call : Icons.videocam),
                                        label: Text(appointment.type.toUpperCase() == 'AUDIO' ? 'Start audio call' : 'Start video call'),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
