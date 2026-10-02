import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class OfflineVoiceRecorder extends StatefulWidget {
  final Function(String base64String) onRecordingComplete;

  const OfflineVoiceRecorder({Key? key, required this.onRecordingComplete}) : super(key: key);

  @override
  _OfflineVoiceRecorderState createState() => _OfflineVoiceRecorderState();
}

class _OfflineVoiceRecorderState extends State<OfflineVoiceRecorder> {
  late final AudioRecorder _audioRecorder;
  bool _isRecording = false;
  String? _audioPath;

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
        final dir = await getApplicationDocumentsDirectory();
        final path = '${dir.path}/voicenote_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
          path: path,
        );

        setState(() {
          _isRecording = true;
          _audioPath = null;
        });
      }
    } catch (e) {
      debugPrint("Error starting recording: $e");
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      if (path != null) {
        setState(() {
          _isRecording = false;
          _audioPath = path;
        });

        // Convert file to Base64 to bypass missing local upload files if deleted later
        final bytes = await File(path).readAsBytes();
        final base64Audio = base64Encode(bytes);
        
        // Pass base64 back with a fake MIME prefix for URL parsing consistency
        widget.onRecordingComplete("data:audio/m4a;base64,$base64Audio");
      }
    } catch (e) {
      debugPrint("Error stopping recording: $e");
    }
  }

  Future<void> _deleteRecording() async {
    if (_audioPath != null) {
      try {
        await File(_audioPath!).delete();
      } catch (e) {}
      setState(() {
        _audioPath = null;
      });
      widget.onRecordingComplete(""); // Clear
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_audioPath != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            const Expanded(child: Text("Voice note recorded securely.", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: _deleteRecording,
            )
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _isRecording ? _stopRecording : _startRecording,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _isRecording ? Colors.redAccent.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isRecording ? Colors.redAccent : const Color(0xFFEEEEEE),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isRecording ? Icons.stop_circle : Icons.mic,
              color: _isRecording ? Colors.redAccent : Colors.blueAccent,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              _isRecording ? "Tap to Stop & Save" : "Tap to Record Voice Note",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: _isRecording ? Colors.redAccent : Colors.blueAccent,
              ),
            ),
            if (_isRecording) ...[
              const SizedBox(width: 12),
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent),
              )
            ]
          ],
        ),
      ),
    );
  }
}
