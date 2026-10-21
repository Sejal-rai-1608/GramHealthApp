import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_language.dart';
import '../../widgets/dashboard_layout.dart';
import '../../widgets/care_card.dart';
import '../../widgets/empty_state.dart';
import '../../theme/app_colors.dart';
import '../../services/consultation_service.dart';
import '../../services/call_service.dart';
import '../../services/medical_record_service.dart';
import '../../services/connectivity_service.dart';
import '../../models/medical_record.dart';
import '../../widgets/voice_note_dialog.dart';
import '../../widgets/voice_note_history_dialog.dart';
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
      final data = await ConsultationService.listDoctorConsultations(status: 'ACTIVE', limit: 50);
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
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.emergency),
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
        color: AppColors.teal,
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
            : _error != null
                ? Center(child: Text('Error: $_error', style: GoogleFonts.manrope(color: AppColors.emergency)))
                : _consultations.isEmpty
                    ? ListView(children: const [EmptyState(title: 'No Consultations', subtitle: 'Consultation requests from patients will appear here.')])
                    : ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _consultations.length + 1,
                        itemBuilder: (context, i) {
                          if (i == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                context.tr('consultations'),
                                style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: CareCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    c.reason.isNotEmpty ? c.reason : 'General Consultation',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.ink),
                  ),
                ),
                StatusChip(label: 'ACTIVE', dotColor: AppColors.teal, bg: AppColors.tealWash, fg: AppColors.tealDeep),
              ],
            ),
            if (c.symptoms != null && c.symptoms!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Symptoms: ${c.symptoms}', style: GoogleFonts.manrope(fontSize: 13, color: AppColors.inkSoft)),
            ],
            if (c.scheduledTime != null) ...[
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.access_time, size: 15, color: AppColors.teal),
                const SizedBox(width: 6),
                Text(c.scheduledTime!, style: GoogleFonts.manrope(fontSize: 13, color: AppColors.inkFaint)),
              ]),
            ],
            const SizedBox(height: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (c.voiceNotes.isNotEmpty || c.voiceNoteUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        if (c.voiceNoteUrl != null)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _playVoiceNote(context, c.voiceNoteUrl!),
                              icon: const Icon(Icons.play_circle_fill, size: 16, color: AppColors.amberDeep),
                              label: Text('Play Voice Note', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.amberDeep,
                                backgroundColor: AppColors.amberWash,
                                side: const BorderSide(color: AppColors.amberPale),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                        if (c.voiceNoteUrl != null) const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => VoiceNoteHistoryDialog(
                                  consultationId: c.id,
                                  patientName: c.patientName,
                                  voiceNotes: c.voiceNotes,
                                ),
                              );
                            },
                            icon: const Icon(Icons.history, size: 16),
                            label: Text('Voice History', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700)),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.mint,
                              foregroundColor: AppColors.tealDeep,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    if (ConnectivityService.instance.currentStatus == NetworkStatus.offline) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => VoiceNoteDialog(consultationId: c.id),
                            );
                          },
                          icon: const Icon(Icons.mic, size: 16, color: AppColors.amberDeep),
                          label: Text('Voice Note', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.amberDeep,
                            backgroundColor: AppColors.amberWash,
                            side: const BorderSide(color: AppColors.amberPale),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DoctorCompleteConsultationScreen(consultationId: c.id),
                              ),
                            );
                          },
                          icon: const Icon(Icons.call, size: 16),
                          label: Text('Call Patient', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 12)),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.mint,
                            foregroundColor: AppColors.tealDeep,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            CallService.startCall(
                              context: context,
                              consultationId: c.id,
                              audioOnly: c.type.toUpperCase() == 'AUDIO',
                            ).then((_) {
                              _complete(c.id);
                            });
                          },
                          icon: Icon(
                            c.type.toUpperCase() == 'AUDIO' ? Icons.call : Icons.videocam,
                            size: 16,
                          ),
                          label: Text(
                            c.type.toUpperCase() == 'AUDIO' ? 'Audio Call' : 'Join Call',
                            style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.teal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showPatientHistory(context, c),
                          icon: const Icon(Icons.history, size: 16, color: AppColors.teal),
                          label: Text('History', style: GoogleFonts.manrope(color: AppColors.teal, fontWeight: FontWeight.w700, fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.tealPale),
                            backgroundColor: AppColors.mintLight,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () => _complete(c.id),
                  icon: const Icon(Icons.done_all, size: 16),
                  label: Text('Complete Consultation', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 13)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
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
        builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.teal)),
      );
      final String base64Data = base64Url.split(',').last;
      final bytes = base64Decode(base64Data);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/temp_voice_note.m4a');
      await file.writeAsBytes(bytes);
      if (mounted) Navigator.pop(context);
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
                backgroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg)),
                title: Text('Patient Voice Request', style: GoogleFonts.manrope(fontWeight: FontWeight.w800, color: AppColors.ink)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64, height: 64,
                      decoration: const BoxDecoration(color: AppColors.amberWash, shape: BoxShape.circle),
                      child: const Icon(Icons.mic, size: 32, color: AppColors.amberDeep),
                    ),
                    const SizedBox(height: 16),
                    Text('Listen to the offline voice note sent by the patient.',
                        style: GoogleFonts.manrope(fontSize: 13, color: AppColors.inkSoft), textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          iconSize: 48,
                          color: AppColors.teal,
                          icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill),
                          onPressed: () {
                            if (isPlaying) { player.pause(); } else { player.resume(); }
                          },
                        ),
                        IconButton(
                          iconSize: 48,
                          color: AppColors.emergency,
                          icon: const Icon(Icons.stop_circle),
                          onPressed: () async { await player.stop(); },
                        )
                      ],
                    )
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () { player.dispose(); Navigator.pop(context); },
                    child: Text('Close', style: GoogleFonts.manrope(color: AppColors.teal, fontWeight: FontWeight.w700)),
                  )
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
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
      backgroundColor: AppColors.ground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.inkGhost, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text('Patient Health Vault', style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink)),
              const SizedBox(height: 6),
              Text('Fetching linked records securely...', style: GoogleFonts.manrope(color: AppColors.inkFaint, fontSize: 13)),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<MedicalRecord>>(
                  future: MedicalRecordService().getDoctorRecords(c.patientId!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.teal));
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}', style: GoogleFonts.manrope(color: AppColors.emergency)));
                    }
                    final records = snapshot.data ?? [];
                    if (records.isEmpty) {
                      return Center(child: Text('No medical records found in this vault.', style: GoogleFonts.manrope(color: AppColors.inkFaint)));
                    }
                    return ListView.builder(
                      itemCount: records.length,
                      itemBuilder: (context, index) {
                        final record = records[index];
                        final isAbha = record.source == 'ABHA';
                        return CareCard(
                          padding: const EdgeInsets.all(14),
                          borderColor: isAbha ? AppColors.tealPale : AppColors.borderLight,
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: isAbha ? AppColors.tealWash : AppColors.mint,
                                borderRadius: BorderRadius.circular(AppRadii.md),
                              ),
                              child: Icon(
                                record.documentType == 'X_RAY' ? Icons.image : Icons.description,
                                color: isAbha ? AppColors.teal : AppColors.tealDeep,
                                size: 20,
                              ),
                            ),
                            title: Text(record.title ?? 'Untitled', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.ink)),
                            subtitle: Text('${isAbha ? 'ABHA Vault' : 'Manual Upload'} \u2022 ${record.issuedDate?.toString().substring(0, 10) ?? '-'}',
                                style: GoogleFonts.manrope(fontSize: 12, color: AppColors.inkFaint)),
                            trailing: const Icon(Icons.remove_red_eye, color: AppColors.inkFaint, size: 18),
                            onTap: () {
                              if (record.fileUrl != null && record.fileUrl!.isNotEmpty) {
                                if (record.fileUrl!.startsWith('data:image')) {
                                  final base64String = record.fileUrl!.split(',').last;
                                  final bytes = base64Decode(base64String);
                                  showDialog(
                                    context: context,
                                    builder: (_) => Dialog(
                                      backgroundColor: AppColors.surface,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg)),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          AppBar(
                                            backgroundColor: AppColors.surface,
                                            elevation: 0,
                                            scrolledUnderElevation: 0,
                                            surfaceTintColor: Colors.transparent,
                                            title: Text('Document View', style: GoogleFonts.manrope(color: AppColors.ink, fontWeight: FontWeight.w700)),
                                            automaticallyImplyLeading: false,
                                            actions: const [CloseButton(color: AppColors.ink)],
                                          ),
                                          Flexible(child: InteractiveViewer(child: Image.memory(bytes))),
                                        ],
                                      ),
                                    ),
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
                      },
                    );
                  },
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
