import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import '../../l10n/app_language.dart';
import '../../theme/app_colors.dart';
import '../../widgets/dashboard_layout.dart';
import '../../widgets/care_card.dart';
import '../../services/consultation_service.dart';

/// Shows all PENDING consultation requests that the logged-in doctor can accept.
/// Includes both assigned (to this doctor) and unassigned (open pool) requests.
class DoctorRequestsScreen extends StatefulWidget {
  const DoctorRequestsScreen({super.key});

  @override
  State<DoctorRequestsScreen> createState() => _DoctorRequestsScreenState();
}

class _DoctorRequestsScreenState extends State<DoctorRequestsScreen> {
  bool _loading = true;
  List<ConsultationModel> _requests = [];
  String? _error;
  final Set<String> _accepting = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await ConsultationService.listDoctorConsultations(
        status: 'PENDING',
        limit: 100,
      );
      if (mounted) setState(() { _requests = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _accept(String id) async {
    setState(() => _accepting.add(id));
    try {
      await ConsultationService.acceptConsultation(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Consultation accepted! Status changed to ACTIVE.'),
          backgroundColor: AppColors.teal,
          behavior: SnackBarBehavior.floating,
        ));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to accept: $e'),
          backgroundColor: AppColors.emergency,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _accepting.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: context.tr('pending_requests'),
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 40, color: AppColors.emergency),
                      const SizedBox(height: 8),
                      Text('Could not load requests',
                          style: GoogleFonts.manrope(color: AppColors.emergency, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Retry'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                        ),
                        onPressed: _load,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.teal,
                  onRefresh: _load,
                  child: _requests.isEmpty
                      ? ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.55,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 72,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        color: AppColors.mint,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: AppColors.borderLight),
                                      ),
                                      child: const Icon(Icons.inbox_outlined, size: 32, color: AppColors.inkFaint),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No pending requests',
                                      style: GoogleFonts.manrope(
                                          fontSize: 16, color: AppColors.ink, fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'New patient requests will appear here',
                                      style: GoogleFonts.manrope(fontSize: 13, color: AppColors.inkFaint),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _requests.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) => _buildCard(_requests[i]),
                        ),
                ),
    );
  }

  Widget _buildCard(ConsultationModel c) {
    final patientInitial = (c.patientName?.isNotEmpty ?? false)
        ? c.patientName![0].toUpperCase()
        : '?';
    final isAccepting = _accepting.contains(c.id);

    return CareCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.mint,
                child: Text(
                  patientInitial,
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.teal,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.patientName ?? 'Patient',
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (c.doctorId == null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.amberWash,
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                          border: Border.all(color: AppColors.amberPale),
                        ),
                        child: Text(
                          'Open request · first-come-first-served',
                          style: GoogleFonts.manrope(fontSize: 10, color: AppColors.amberDark, fontWeight: FontWeight.w700),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.mint,
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                          border: Border.all(color: AppColors.tealPale),
                        ),
                        child: Text(
                          'Requested you directly',
                          style: GoogleFonts.manrope(fontSize: 10, color: AppColors.tealDeep, fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
              ),
              StatusChip(label: 'PENDING', dotColor: AppColors.amber, bg: AppColors.amberChipBg, fg: AppColors.amberDark),
            ],
          ),
          if (c.reason.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.notes_outlined, size: 16, color: AppColors.teal),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    c.reason,
                    style: GoogleFonts.manrope(fontSize: 13, color: AppColors.ink, height: 1.4),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if ((c.symptoms ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.sick_outlined, size: 16, color: AppColors.amberDeep),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    c.symptoms!,
                    style: GoogleFonts.manrope(fontSize: 12, color: AppColors.inkMuted, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (c.voiceNoteUrl != null && c.voiceNoteUrl!.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _playVoiceNote(context, c.voiceNoteUrl!),
                icon: const Icon(Icons.play_circle_fill, size: 18, color: AppColors.amberDeep),
                label: Text('Play Audio Symptoms',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: AppColors.amberDeep)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.amberPale),
                  backgroundColor: AppColors.amberWash,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isAccepting ? null : () => _accept(c.id),
              icon: isAccepting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_outline, size: 18),
              label: Text(isAccepting ? 'Accepting...' : 'Accept Consultation',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                disabledBackgroundColor: AppColors.teal.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
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
                title: Text('Patient Audio Symptoms', style: GoogleFonts.manrope(fontWeight: FontWeight.w800, color: AppColors.ink)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64, height: 64,
                      decoration: const BoxDecoration(color: AppColors.amberWash, shape: BoxShape.circle),
                      child: const Icon(Icons.mic, size: 32, color: AppColors.amberDeep),
                    ),
                    const SizedBox(height: 16),
                    Text('Listen to the offline voice note sent by the patient outlining their symptoms.',
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
}
