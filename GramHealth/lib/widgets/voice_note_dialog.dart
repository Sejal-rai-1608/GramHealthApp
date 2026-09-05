import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_colors.dart';
import '../services/sync_service.dart';
import '../config/app_config.dart';

class VoiceNoteDialog extends StatefulWidget {
  final String consultationId;
  const VoiceNoteDialog({super.key, required this.consultationId});

  @override
  State<VoiceNoteDialog> createState() => _VoiceNoteDialogState();
}

class _VoiceNoteDialogState extends State<VoiceNoteDialog> {
  late final AudioRecorder _audioRecorder;
  bool _isRecording = false;
  String? _recordedFilePath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(
          const RecordConfig(),
          path: filePath,
        );
        setState(() {
          _isRecording = true;
          _recordedFilePath = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error starting record: $e')));
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _recordedFilePath = path;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error stopping record: $e')));
    }
  }

  Future<void> _submitVoiceNote() async {
    if (_recordedFilePath == null) return;
    setState(() => _isSaving = true);
    
    try {
      final bytes = await File(_recordedFilePath!).readAsBytes();
      final base64String = base64Encode(bytes);
      final payloadData = 'data:audio/m4a;base64,$base64String';

      // Queue the sync event to upload the voice note attached to this consultation
      await SyncService.instance.push(
        entityType: 'voice_note_${widget.consultationId}',
        operation: 'PATCH',
        endpoint: '${AppConfig.apiConsultations}/${widget.consultationId}/voicenote',
        payload: {
          'voiceNoteUrl': payloadData,
        },
      );

      if (mounted) {
        Navigator.pop(context, true); // true = success
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Voice Note queued for sync!')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to enqueue voice note: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Record Voice Note'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Network is unavailable. Please record your message, and it will sync automatically when you are back online.', style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 24),
          if (_isRecording) const Icon(Icons.mic, size: 48, color: Colors.redAccent),
          if (!_isRecording && _recordedFilePath == null) const Icon(Icons.mic_none, size: 48, color: Colors.grey),
          if (!_isRecording && _recordedFilePath != null) const Icon(Icons.check_circle, size: 48, color: AppColors.leafGreenPrimary),
          const SizedBox(height: 24),
          if (_recordedFilePath == null)
            ElevatedButton(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isRecording ? Colors.redAccent : Colors.orangeAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
            )
          else ...[
             const Text('Recording ready.', style: TextStyle(color: AppColors.leafGreenPrimary)),
             const SizedBox(height: 12),
             _isSaving 
               ? const CircularProgressIndicator()
               : ElevatedButton(
                  onPressed: _submitVoiceNote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAccent,
                    foregroundColor: AppColors.textDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Save & Queue Sync'),
                ),
             TextButton(
               onPressed: () => setState(() => _recordedFilePath = null),
               child: const Text('Discard & Retake', style: TextStyle(color: Colors.redAccent)),
             )
          ]
        ],
      ),
      actions: [
        if (!_isRecording)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          )
      ],
    );
  }
}
