import 'package:flutter/material.dart';
import '../l10n/app_language.dart';
import '../widgets/dashboard_layout.dart';
import '../widgets/glass_card.dart';
import '../widgets/status_badge.dart';
import '../widgets/empty_state.dart';
import '../theme/app_colors.dart';
import '../services/consultation_service.dart';
import '../services/call_service.dart';
import '../services/medical_record_service.dart';
import '../services/connectivity_service.dart';
import '../services/connectivity_service.dart';
import '../models/medical_record.dart';
import '../widgets/voice_note_dialog.dart';
import 'doctor_complete_consultation_screen.dart';
import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

class DoctorConsultationsScreen extends StatefulWidget {
  const DoctorConsultationsScreen({super.key});

  @override
  State<DoctorConsultationsScreen> createState() => _DoctorConsultationsScreenState();
}

class _DoctorConsultationsScreenState extends State<DoctorConsultationsScreen> {
  bool _loading = true;
  List<ConsultationModel> _consultations = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ConsultationService.listDoctorConsultations(limit: 50);
      if (mounted) setState(() { _consultations = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _accept(String id) async {
    try {
      await ConsultationService.acceptConsultation(id);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _complete(String id) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DoctorCompleteConsultationScreen(consultationId: id),
      ),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: context.tr('consultations'),
      child: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.redAccent)))
                : _consultations.isEmpty
                    ? ListView(children: const [EmptyState(title: 'No Consultations', subtitle: 'Consultation requests from patients will appear here.')])
                    : ListView.builder(
                        itemCount: _consultations.length + 1,
                        itemBuilder: (context, i) {
                          if (i == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                context.tr('consultations'),
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
                              ),
                            );
                          }
                          final c = _consultations[i - 1];
                          return _buildCard(c);
                        },
                      ),
      ),
    );
  }

  Widget _buildCard(ConsultationModel c) {
    final isPending  = c.status.toUpperCase() == 'PENDING';
    final isAccepted = c.status.toUpperCase() == 'ACTIVE';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    c.reason.isNotEmpty ? c.reason : 'General Consultation',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                  ),
                ),
                StatusBadge(status: c.status),
              ],
            ),
            if (c.symptoms != null && c.symptoms!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Symptoms: ${c.symptoms}', style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
            ],
            if (c.scheduledTime != null) ...[
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.access_time, size: 15, color: AppColors.leafGreenPrimary),
                const SizedBox(width: 6),
                Text(c.scheduledTime!, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
              ]),
            ],
            if (isPending || isAccepted) ...[
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (c.voiceNoteUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: ElevatedButton.icon(
                        onPressed: () => _playVoiceNote(context, c.voiceNoteUrl!),
                        icon: const Icon(Icons.play_circle_fill, size: 16),
                        label: const Text('Play Voice Note'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  if (isPending)
                    ElevatedButton.icon(
                      onPressed: () => _accept(c.id),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.leafGreenPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  if (isAccepted) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                               if (ConnectivityService.instance.currentStatus == NetworkStatus.offline) {
                                   showDialog(
                                     context: context,
                                     builder: (context) => VoiceNoteDialog(consultationId: c.id),
                                   );
                               } else {
                                   CallService.startCall(
                                     consultationId: c.id,
                                     audioOnly: c.type.toUpperCase() == 'AUDIO',
                                   );
                               }
                            },
                            icon: Icon(
                              ConnectivityService.instance.currentStatus == NetworkStatus.offline
                                  ? Icons.mic
                                  : (c.type.toUpperCase() == 'AUDIO' ? Icons.call : Icons.videocam),
                              size: 16,
                            ),
                            label: Text(
                              ConnectivityService.instance.currentStatus == NetworkStatus.offline
                                  ? 'Voice Note'
                                  : (c.type.toUpperCase() == 'AUDIO' ? 'Audio Call' : 'Join Call'),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ConnectivityService.instance.currentStatus == NetworkStatus.offline
                                  ? Colors.orangeAccent
                                  : Colors.blueAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showPatientHistory(context, c),
                            icon: const Icon(Icons.history, size: 16, color: Colors.blueAccent),
                            label: const Text('History', style: TextStyle(color: Colors.blueAccent)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.blueAccent),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => _complete(c.id),
                      icon: const Icon(Icons.done_all, size: 16),
                      label: const Text('Complete Consultation'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryAccent,
                        foregroundColor: AppColors.textDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _playVoiceNote(BuildContext context, String base64Url) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      final String base64Data = base64Url.split(',').last;
      final bytes = base64Decode(base64Data);
      
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/temp_voice_note.m4a');
      await file.writeAsBytes(bytes);
      
      if (mounted) Navigator.pop(context); // Close loading

      showDialog(
        context: context,
        builder: (context) {
          final player = AudioPlayer();
          bool isPlaying = false;
          player.play(DeviceFileSource(file.path));

          return StatefulBuilder(
            builder: (context, setState) {
              player.onPlayerStateChanged.listen((state) {
                if (mounted) {
                  setState(() => isPlaying = state == PlayerState.playing);
                }
              });

              return AlertDialog(
                title: const Text('Patient Voice Request'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.mic, size: 48, color: Colors.orangeAccent),
                    const SizedBox(height: 16),
                    const Text('Listen to the offline voice note sent by the patient.'),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          iconSize: 48,
                          color: Colors.blueAccent,
                          icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill),
                          onPressed: () {
                            if (isPlaying) {
                              player.pause();
                            } else {
                              player.resume();
                            }
                          },
                        ),
                        IconButton(
                          iconSize: 48,
                          color: Colors.redAccent,
                          icon: const Icon(Icons.stop_circle),
                          onPressed: () async {
                            await player.stop();
                          },
                        )
                      ],
                    )
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      player.dispose();
                      Navigator.pop(context);
                    },
                    child: const Text('Close'),
                  )
                ],
              );
            }
          );
        }
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loader
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load voice note.')));
      }
    }
  }

  void _showPatientHistory(BuildContext context, ConsultationModel c) {
    if (c.patientId == null || c.patientId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No patient ID assigned.')));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Patient Health Vault', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Fetching linked records securely...', style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<MedicalRecord>>(
                  future: MedicalRecordService().getDoctorRecords(c.patientId!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                    }
                    final records = snapshot.data ?? [];
                    if (records.isEmpty) {
                      return const Center(child: Text('No medical records found in this vault.', style: TextStyle(color: Colors.grey)));
                    }
                    return ListView.builder(
                      itemCount: records.length,
                      itemBuilder: (context, index) {
                        final record = records[index];
                        final isAbha = record.source == 'ABHA';
                        return Card(
                          elevation: isAbha ? 3 : 1,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            side: isAbha ? BorderSide(color: Colors.blue.shade200, width: 2) : BorderSide.none,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: Icon(
                              record.documentType == 'X_RAY' ? Icons.image : Icons.description,
                              color: isAbha ? Colors.blue : AppColors.leafGreenPrimary,
                            ),
                            title: Text(record.title ?? 'Untitled'),
                            subtitle: Text('${isAbha ? 'ABHA Vault' : 'Manual Upload'} \u2022 ${record.issuedDate?.toString().substring(0, 10) ?? '-'}'),
                            trailing: const Icon(Icons.remove_red_eye),
                            onTap: () {
                              if (record.fileUrl != null && record.fileUrl!.isNotEmpty) {
                                if (record.fileUrl!.startsWith('data:image')) {
                                  final base64String = record.fileUrl!.split(',').last;
                                  final bytes = base64Decode(base64String);
                                  showDialog(
                                    context: context,
                                    builder: (_) => Dialog(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          AppBar(
                                            title: const Text('Document View'), 
                                            automaticallyImplyLeading: false,
                                            actions: const [CloseButton()],
                                          ),
                                          Flexible(child: InteractiveViewer(child: Image.memory(bytes))),
                                        ]
                                      )
                                    )
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Simulating external PDF link...")));
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No document attachment found.")));
                              }
                            },
                          ),
                        );
                      }
                    );
                  }
                ),
              )
            ],
          ),
        );
      }
    );
  }
}
