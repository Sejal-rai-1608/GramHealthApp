import "dart:async";

import "package:flutter/material.dart";
import "package:go_router/go_router.dart";

import "package:jitsi_meet_wrapper/jitsi_meet_wrapper.dart";
import "package:ruralcare_flutter/services/jitsi_service.dart";
import "../../config/app_config.dart";
import "../../theme/app_colors.dart";

enum MeetingState { initializing, connecting, waitingForHost, connected, reconnecting, disconnected, error }

class JitsiMeetingDetails {
  final String roomName;
  final String serverUrl;
  final String consultationType;
  final String consultationId;

  const JitsiMeetingDetails({
    required this.roomName,
    required this.serverUrl,
    required this.consultationType,
    required this.consultationId,
  });
}

class JitsiMeetingScreen extends StatefulWidget {
  final String consultationId;
  final String? participantName;
  final String? participantRole;
  final String? roomName;
  final String? serverUrl;
  const JitsiMeetingScreen({super.key, required this.consultationId, this.participantName, this.participantRole, this.roomName, this.serverUrl});
  @override
  State<JitsiMeetingScreen> createState() => _JitsiMeetingScreenState();
}

class _JitsiMeetingScreenState extends State<JitsiMeetingScreen> with WidgetsBindingObserver {
  MeetingState _meetingState = MeetingState.initializing;
  String? _errorMessage;
  String? _errorCode;
  Timer? _durationTimer;
  Timer? _retryTimer;
  int _callDuration = 0;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  JitsiMeetingDetails? _meetingDetails;
  bool _isAudioMuted = false;
  bool _isVideoMuted = false;
  bool _isSpeakerOn = true;
  int _participantCount = 1;
  final String _connectionQuality = "good";
  bool _isNativeViewVisible = false;

  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasInitialized) return;
    _hasInitialized = true;

    // Now context is safe to use for inherited widget lookups
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    if (extra != null && extra['roomName'] != null && extra['serverUrl'] != null) {
      _meetingDetails = JitsiMeetingDetails(
        roomName: extra['roomName'] as String,
        serverUrl: extra['serverUrl'] as String,
        consultationType: (extra['audioOnly'] == true) ? 'AUDIO' : 'VIDEO',
        consultationId: widget.consultationId,
      );
      debugPrint('[JitsiMeetingScreen] Using meeting details from extras: ${_meetingDetails!.roomName}');
      _joinMeeting();
    } else {
      _initializeAndJoin();
    }
  }
  // Removed stray call

  // Directly join meeting using pre-fetched details
  Future<void> _joinMeeting() async {
    final listener = JitsiMeetingListener(
      onConferenceWillJoin: (url) {
        debugPrint('[JitsiMeetingScreen] Conference will join: $url');
        _setState(MeetingState.connecting);
      },
      onConferenceJoined: (url) {
        debugPrint('[JitsiMeetingScreen] Conference joined successfully: $url');
        _isNativeViewVisible = true;
        _setState(MeetingState.connected);
        _startDurationTimer();
        _retryCount = 0;
      },
      onConferenceTerminated: (url, error) {
        debugPrint('[JitsiMeetingScreen] Conference terminated: $url, error: $error');
        _isNativeViewVisible = false;
        if (error != null) {
          final errorStr = error.toString();
          if (errorStr.contains('97') || errorStr.contains('connection')) {
            _handleConnectionError('Unable to connect to meeting server. Please check your internet connection.', '97');
          } else if (errorStr.contains('password') || errorStr.contains('auth')) {
            _handleConnectionError('Meeting authentication failed. Please try again.', 'AUTH');
          } else {
            _handleConnectionError('Meeting ended unexpectedly: $errorStr', 'TERMINATED');
          }
        } else {
          _onMeetingEnded();
        }
      },
      onAudioMutedChanged: (isMuted) {
        if (mounted) setState(() => _isAudioMuted = isMuted);
      },
      onVideoMutedChanged: (isMuted) {
        if (mounted) setState(() => _isVideoMuted = isMuted);
      },
      onParticipantJoined: (email, name, role, participantId) {
        if (mounted) setState(() => _participantCount++);
      },
      onParticipantLeft: (participantId) {
        if (mounted) setState(() => _participantCount = (_participantCount - 1).clamp(1, 100));
      },
      onClosed: () {
        _isNativeViewVisible = false;
        if (mounted && _meetingState == MeetingState.connected) _onMeetingEnded();
      },
    );
    try {
      _setState(MeetingState.connecting);
      await JitsiService.joinMeeting(
        roomName: _meetingDetails!.roomName,
        serverUrl: _meetingDetails!.serverUrl,
        userDisplayName: widget.participantName ?? 'User',
        audioOnly: _meetingDetails!.consultationType == 'AUDIO',
        listener: listener,
      );
    } catch (e, stackTrace) {
      debugPrint('[JitsiMeetingScreen] Join meeting error: $e');
      debugPrint('[JitsiMeetingScreen] Stack trace: $stackTrace');
      // Fallback to a temporary room and retry once
      final fallbackRoom = "room_${widget.consultationId}_${DateTime.now().millisecondsSinceEpoch}";
      _meetingDetails = JitsiMeetingDetails(
        roomName: fallbackRoom,
        serverUrl: AppConfig.jitsiServerUrl,
        consultationType: 'VIDEO',
        consultationId: widget.consultationId,
      );
      try {
        await JitsiService.joinMeeting(
          roomName: _meetingDetails!.roomName,
          serverUrl: _meetingDetails!.serverUrl,
          userDisplayName: widget.participantName ?? 'User',
          audioOnly: _meetingDetails!.consultationType == 'AUDIO',
          listener: listener,
        );
      } catch (retryError) {
        debugPrint('[JitsiMeetingScreen] Fallback join failed: $retryError');
        _errorMessage = 'Could not join meeting: $e';
        _errorCode = 'JOIN_FAILED';
        _setState(MeetingState.error);
      }
    }
  }
  

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _durationTimer?.cancel();
    _retryTimer?.cancel();
    _leaveMeeting();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _meetingState == MeetingState.connected) {
      debugPrint("[JitsiMeetingScreen] App paused during meeting");
    } else if (state == AppLifecycleState.resumed) {
      debugPrint("[JitsiMeetingScreen] App resumed");
    }
  }

  Future<void> _leaveMeeting() async {
    try {
      await JitsiService.leaveMeeting();
    } catch (e) {
      debugPrint("[JitsiMeetingScreen] Leave meeting error: $e");
    }
  }

  Future<void> _initializeAndJoin() async {
    _setState(MeetingState.initializing);
    try {
      debugPrint("[JitsiMeetingScreen] Fetching meeting details for consultation: ${widget.consultationId}");
      final meetingDetails = await JitsiService.fetchMeetingDetails(widget.consultationId);
      _meetingDetails = JitsiMeetingDetails(
        roomName: meetingDetails.roomName,
        serverUrl: meetingDetails.serverUrl,
        consultationType: meetingDetails.consultationType,
        consultationId: meetingDetails.consultationId,
      );
      debugPrint("[JitsiMeetingScreen] Got meeting details: ${_meetingDetails.toString()}");
      if (_meetingDetails!.roomName.isEmpty) throw Exception("Invalid room name received from server");
      if (_meetingDetails!.serverUrl.isEmpty) throw Exception("Invalid server URL received from server");
      final userName = widget.participantName ?? "User";
      final audioOnly = _meetingDetails!.consultationType == "AUDIO";
      final listener = JitsiMeetingListener(
        onConferenceWillJoin: (url) {
          debugPrint("[JitsiMeetingScreen] Conference will join: $url");
          _setState(MeetingState.connecting);
        },
        onConferenceJoined: (url) {
          debugPrint("[JitsiMeetingScreen] Conference joined successfully: $url");
          _isNativeViewVisible = true;
          _setState(MeetingState.connected);
          _startDurationTimer();
          _retryCount = 0;
        },
        onConferenceTerminated: (url, error) {
          debugPrint("[JitsiMeetingScreen] Conference terminated: $url, error: $error");
          _isNativeViewVisible = false;
          if (error != null) {
            final errorStr = error.toString();
            if (errorStr.contains("97") || errorStr.contains("connection")) {
              _handleConnectionError("Unable to connect to meeting server. Please check your internet connection.", "97");
            } else if (errorStr.contains("password") || errorStr.contains("auth")) {
              _handleConnectionError("Meeting authentication failed. Please try again.", "AUTH");
            } else {
              _handleConnectionError("Meeting ended unexpectedly: $errorStr", "TERMINATED");
            }
          } else {
            _onMeetingEnded();
          }
        },
        onAudioMutedChanged: (isMuted) {
          if (mounted) setState(() => _isAudioMuted = isMuted);
        },
        onVideoMutedChanged: (isMuted) {
          if (mounted) setState(() => _isVideoMuted = isMuted);
        },
        onParticipantJoined: (email, name, role, participantId) {
          if (mounted) setState(() => _participantCount++);
        },
        onParticipantLeft: (participantId) {
          if (mounted) setState(() => _participantCount = (_participantCount - 1).clamp(1, 100));
        },
        onClosed: () {
          _isNativeViewVisible = false;
          if (mounted && _meetingState == MeetingState.connected) _onMeetingEnded();
        },
      );
      _setState(MeetingState.connecting);
      await JitsiService.joinMeeting(
        roomName: _meetingDetails!.roomName,
        serverUrl: _meetingDetails!.serverUrl,
        userDisplayName: widget.participantName ?? "User",
        audioOnly: _meetingDetails!.consultationType == "AUDIO",
        listener: listener,
      );
    } catch (e, stackTrace) {
      debugPrint("[JitsiMeetingScreen] Initialize and join error: $e");
      debugPrint("[JitsiMeetingScreen] Stack trace: $stackTrace");
      // Show error state instead of silently failing
      final errorMsg = e.toString();
      if (errorMsg.contains('Doctor must accept first') || errorMsg.contains('not initialized')) {
        _errorMessage = 'The doctor has not accepted this consultation yet. Please wait for the doctor to accept before joining.';
      } else {
        _errorMessage = 'Could not join meeting: $errorMsg';
      }
      _errorCode = 'INIT_FAILED';
      _setState(MeetingState.error);
    }
  }


  void _setState(MeetingState newState) {
    if (mounted) setState(() => _meetingState = newState);
  }

  void _handleConnectionError(String message, String code) {
    debugPrint("[JitsiMeetingScreen] Connection error [$code]: $message");
    if (_retryCount < _maxRetries && _meetingState != MeetingState.error) {
      _retryCount++;
      _setState(MeetingState.reconnecting);
      _errorMessage = message;
      _errorCode = code;
      _retryTimer?.cancel();
      _retryTimer = Timer(Duration(seconds: _retryCount * 3), () {
        if (mounted) _initializeAndJoin();
      });
    } else {
      _setState(MeetingState.error);
      _errorMessage = message;
      _errorCode = code;
    }
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _meetingState == MeetingState.connected) {
        setState(() => _callDuration++);
      } else {
        timer.cancel();
      }
    });
  }

  void _onMeetingEnded() {
    _durationTimer?.cancel();
    _retryTimer?.cancel();
    if (mounted) context.pop();
  }

  String _formatTime(int sec) {
    final mins = sec ~/ 60;
    final s = sec % 60;
    return "${mins.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  Future<void> _toggleAudio() async {
    final newMuteState = !_isAudioMuted;
    try {
      await JitsiService.toggleAudioMute(newMuteState);
      if (mounted) setState(() => _isAudioMuted = newMuteState);
    } catch (e) {
      debugPrint("[JitsiMeetingScreen] Toggle audio error: $e");
    }
  }

  Future<void> _toggleSpeaker() async {
    if (mounted) setState(() => _isSpeakerOn = !_isSpeakerOn);
  }

  Future<void> _switchCamera() async {
    debugPrint("[JitsiMeetingScreen] Switch camera requested");
  }

  Future<void> _endMeeting() async {
    await _leaveMeeting();
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isAudioOnly = _meetingDetails?.consultationType == "AUDIO";
    final isConnecting = _meetingState == MeetingState.connecting || _meetingState == MeetingState.initializing;
    final isReconnecting = _meetingState == MeetingState.reconnecting;
    final isError = _meetingState == MeetingState.error;
    final isConnected = _meetingState == MeetingState.connected;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) await _endMeeting();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(
                color: Colors.black,
                child: _buildBackgroundContent(isConnecting, _meetingState == MeetingState.reconnecting, isError, isConnected, isAudioOnly),
              ),
            ),
            if (!isConnecting || _meetingState == MeetingState.reconnecting) SafeArea(child: _buildTopBar()),
            if (_meetingState == MeetingState.connected && !_isNativeViewVisible)
              SafeArea(
                bottom: true,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: _buildBottomControls(),
                ),
              ),
            if (_meetingState == MeetingState.reconnecting) _buildReconnectingOverlay(),
            if (_meetingState == MeetingState.error) _buildErrorOverlay(),
            if (_meetingState == MeetingState.waitingForHost) _buildWaitingForHostOverlay(),
          ],
        ),
      ),
    );
  }

  // Helper methods (class-level)
  Widget _buildBackgroundContent(bool isConnecting, bool isReconnecting, bool isError, bool isConnected, bool isAudioOnly) {
    if (isError || (isConnecting && _meetingState != MeetingState.reconnecting)) {
      if (isError) return _buildErrorWidget(_errorMessage ?? "Unknown error", _errorCode ?? "ERROR");
      return _buildConnectingWidget();
    }
    if (isConnected) {
      return Stack(
        children: [
          Container(color: Colors.black),
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            right: 16,
            child: _buildConnectionQualityIndicator(),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            left: 16,
            child: _buildParticipantCount(),
          ),
        ],
      );
    }
    return Container(color: Colors.black);
  }

  Widget _buildConnectingWidget() => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildConnectingAnimation(),
          const SizedBox(height: 32),
          Text(_getConnectingMessage(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text("Meeting ID: ${_meetingDetails?.roomName ?? 'Loading...'}", style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13, fontFamily: "monospace"), textAlign: TextAlign.center),
        ],
      ),
    ),
  );

  Widget _buildConnectingAnimation() => Column(
    children: [
      Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.2), width: 3)),
          ),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [AppColors.primaryAccent.withValues(alpha: 0.3), AppColors.primaryAccent.withValues(alpha: 0.05)])),
          ),
          const Icon(Icons.videocam, size: 48, color: Colors.white),
        ],
      ),
      const SizedBox(height: 24),
      Stack(
        alignment: Alignment.center,
        children: List.generate(
          3,
              (index) => TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 1500 + index * 300),
            curve: Curves.easeOut,
            builder: (context, value, child) => Transform.scale(
              scale: 1.0 + value * 0.5,
              child: Opacity(
                opacity: (1.0 - value).clamp(0.0, 1.0),
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.3 * (1 - value)), width: 2)),
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );

  String _getConnectingMessage() {
    switch (_meetingState) {
      case MeetingState.initializing:
        return "Preparing meeting...";
      case MeetingState.connecting:
        return "Connecting to meeting...";
      case MeetingState.waitingForHost:
        return "Waiting for host to start...";
      default:
        return "Connecting...";
    }
  }

  Widget _buildErrorWidget(String message, String code) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red.withValues(alpha: 0.1), border: Border.all(color: Colors.red.withValues(alpha: 0.3), width: 2)),
            child: const Icon(Icons.wifi_off, size: 48, color: Colors.red),
          ),
          const SizedBox(height: 24),
          Text("Connection Failed", style: TextStyle(color: Colors.red.shade300, fontSize: 24, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 15), textAlign: TextAlign.center),
          if (code != "ERROR") ...[const SizedBox(height: 4), Text("Error code: $code", style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, fontFamily: "monospace"))],
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  _retryCount = 0;
                  _initializeAndJoin();
                },
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text("Retry"),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _endMeeting(),
                icon: const Icon(Icons.call_end, size: 20),
                label: const Text("Leave"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _buildTopBar() {
    final isAudioOnly = _meetingDetails?.consultationType == "AUDIO";
    final isConnected = _meetingState == MeetingState.connected;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _endMeeting(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.participantName ?? "Consultation", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600, shadows: [Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1))]), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(width: 7, height: 7, decoration: BoxDecoration(color: _meetingState == MeetingState.reconnecting ? Colors.orange : (isConnected ? const Color(0xFF4CAF50) : Colors.white54), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(
                      _meetingState == MeetingState.reconnecting ? "Reconnecting... (attempt $_retryCount/$_maxRetries)" : (isConnected ? "Connected • ${_formatTime(_callDuration)}" : _getConnectingMessage()),
                      style: TextStyle(color: _meetingState == MeetingState.reconnecting ? Colors.orange : Colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!isAudioOnly && isConnected) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.blue.shade400.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.blue.shade400.withValues(alpha: 0.5))),
                        child: const Text("VIDEO", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.blueAccent)),
                      ),
                    ] else ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.orange.withValues(alpha: 0.5))),
                        child: const Text("AUDIO", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.orange)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: const Icon(Icons.more_vert, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    final isAudioOnly = _meetingDetails?.consultationType == "AUDIO";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withValues(alpha: 0.9)])),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(icon: _isAudioMuted ? Icons.mic_off_rounded : Icons.mic_rounded, label: _isAudioMuted ? "Unmute" : "Mute", color: _isAudioMuted ? Colors.red.shade400 : Colors.white, backgroundColor: _isAudioMuted ? Colors.red.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.2), onTap: _toggleAudio),
          if (!isAudioOnly)
            _buildControlButton(icon: _isVideoMuted ? Icons.videocam_off_rounded : Icons.videocam_rounded, label: _isVideoMuted ? "Start Video" : "Stop Video", color: _isVideoMuted ? Colors.red.shade400 : Colors.white, backgroundColor: _isVideoMuted ? Colors.red.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.2), onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Use native Jitsi controls to toggle video"), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating, duration: Duration(seconds: 2))))
          else
            _buildControlButton(icon: Icons.videocam_off_rounded, label: "Audio Only", color: Colors.white54, backgroundColor: Colors.white.withValues(alpha: 0.1), onTap: null),
          GestureDetector(
            onTap: () => _endMeeting(),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.red.shade400, Colors.red.shade600]), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 2)]),
              child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 30),
            ),
          ),
          _buildControlButton(icon: _isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_off_rounded, label: _isSpeakerOn ? "Speaker" : "Earpiece", color: Colors.white, backgroundColor: Colors.white.withValues(alpha: 0.2), onTap: _toggleSpeaker),
          _buildControlButton(icon: Icons.switch_camera_rounded, label: "Flip Camera", color: Colors.white, backgroundColor: Colors.white.withValues(alpha: 0.2), onTap: _switchCamera),
        ],
      ),
    );
  }

  Widget _buildControlButton({required IconData icon, required String label, required Color color, required Color backgroundColor, VoidCallback? onTap}) => GestureDetector(
    onTap: onTap,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
          child: Icon(icon, color: onTap != null ? color : color.withValues(alpha: 0.4), size: 26),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(color: onTap != null ? color : color.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.w500)),
      ],
    ),
  );

  Widget _buildConnectionQualityIndicator() {
    IconData icon;
    Color color;
    switch (_connectionQuality) {
      case "excellent":
        icon = Icons.signal_cellular_4_bar;
        color = Colors.green;
        break;
      case "good":
        icon = Icons.signal_cellular_alt;
        color = Colors.green.shade300;
        break;
      case "poor":
        icon = Icons.signal_cellular_alt_1_bar;
        color = Colors.orange;
        break;
      default:
        icon = Icons.signal_cellular_connected_no_internet_4_bar;
        color = Colors.red;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.5))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(_connectionQuality.capitalize(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildParticipantCount() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.2))),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.person, size: 14, color: Colors.blue.shade300),
        const SizedBox(width: 4),
        Text("$_participantCount", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    ),
  );

  Widget _buildReconnectingOverlay() => Positioned.fill(
    child: Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.orange, strokeWidth: 3),
            const SizedBox(height: 24),
            const Text("Reconnecting...", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text("Attempt $_retryCount of $_maxRetries", style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
            const SizedBox(height: 8),
            Text("Please check your internet connection", style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
          ],
        ),
      ),
    ),
  );

  Widget _buildErrorOverlay() => Positioned.fill(
    child: Container(
      color: Colors.black.withValues(alpha: 0.95),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red.withValues(alpha: 0.1), border: Border.all(color: Colors.red.withValues(alpha: 0.3), width: 2)),
                child: const Icon(Icons.wifi_off, size: 48, color: Colors.red),
              ),
              const SizedBox(height: 24),
              Text("Connection Failed", style: TextStyle(color: Colors.red.shade300, fontSize: 24, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(_errorMessage ?? "Unable to connect to the meeting", style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 15), textAlign: TextAlign.center),
              if (_errorCode != null) ...[const SizedBox(height: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text("Error: $_errorCode", style: TextStyle(color: Colors.red.shade300, fontSize: 12, fontFamily: "monospace")))],
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      _retryCount = 0;
                      _initializeAndJoin();
                    },
                    icon: const Icon(Icons.refresh, size: 20),
                    label: const Text("Retry"),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white), padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => _endMeeting(),
                    icon: const Icon(Icons.call_end, size: 20),
                    label: const Text("Leave Meeting"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _buildWaitingForHostOverlay() => Positioned.fill(
    child: Container(
      color: Colors.black.withValues(alpha: 0.9),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withValues(alpha: 0.1), border: Border.all(color: Colors.blue.withValues(alpha: 0.3), width: 2)),
                child: const Icon(Icons.person_outline, size: 48, color: Colors.blue),
              ),
              const SizedBox(height: 24),
              const Text("Waiting for Host", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text("The doctor will start the meeting shortly", style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 15), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Text("Meeting ID: ${_meetingDetails?.roomName ?? ""}", style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13, fontFamily: "monospace")),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: () => _endMeeting(),
                icon: const Icon(Icons.call_end, size: 20),
                label: const Text("Leave"),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white), padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ],
          ),
        ),
      ),
    ),
  );

}

extension StringExtension on String {
  String capitalize() => isEmpty ? this : "${this[0].toUpperCase()}${substring(1)}";
}
