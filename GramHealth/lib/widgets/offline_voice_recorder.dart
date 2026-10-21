import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';

class OfflineVoiceRecorder extends StatefulWidget {
  final Function(String base64String) onRecordingComplete;
  final String? doctorPhone;
  final String? doctorName;

  const OfflineVoiceRecorder({
    Key? key,
    required this.onRecordingComplete,
    this.doctorPhone,
    this.doctorName,
  }) : super(key: key);

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

        final bytes = await File(path).readAsBytes();
        final base64Audio = base64Encode(bytes);
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
      widget.onRecordingComplete("");
    }
  }

  Future<void> _makeDirectPhoneCall() async {
    final rawPhone = widget.doctorPhone?.trim();
    final phoneNum = (rawPhone != null && rawPhone.isNotEmpty) ? rawPhone : '108';
    final Uri phoneUri = Uri.parse('tel:$phoneNum');

    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(phoneUri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Initiating direct phone call to $phoneNum..."),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // 🎙 Audio Recording Button
            Expanded(
              child: GestureDetector(
                onTap: _isRecording ? _stopRecording : _startRecording,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                  decoration: BoxDecoration(
                    color: _isRecording ? Colors.redAccent.withValues(alpha: 0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isRecording ? Colors.redAccent : const Color(0xFFEEEEEE),
                    ),
                    boxShadow: const [
                      BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2))
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isRecording ? Icons.stop_circle : Icons.mic,
                        color: _isRecording ? Colors.redAccent : Colors.blueAccent,
                        size: 22,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _isRecording ? "Stop & Save" : "Voice Note",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _isRecording ? Colors.redAccent : Colors.blueAccent,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_isRecording) ...[
                        const SizedBox(width: 6),
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent),
                        )
                      ]
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // 📞 Direct Phone Call Button (Works Offline via Cellular)
            Expanded(
              child: GestureDetector(
                onTap: _makeDirectPhoneCall,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF25D366),
                    ),
                    boxShadow: const [
                      BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2))
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.phone_in_talk,
                        color: Color(0xFF1E8E3E),
                        size: 22,
                      ),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          "Call Doctor",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E8E3E),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        if (_audioPath != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    "Voice note recorded securely.",
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                  onPressed: _deleteRecording,
                )
              ],
            ),
          ),
        ]
      ],
    );
  }
}
