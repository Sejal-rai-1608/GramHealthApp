import 'package:jitsi_meet_wrapper/jitsi_meet_wrapper.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';
import 'auth_service.dart';
import 'connectivity_service.dart';

class CallService {
  CallService._();

  /// Returns the deterministic room name shared by the patient and doctor.
  /// The consultation UUID keeps the room unique without needing a second
  /// meeting-record table in the backend.
  static String roomNameForConsultation(String consultationId) {
    final safeId = consultationId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return 'gramhealth_call_$safeId';
  }

  /// Joins a real Jitsi video or audio call for a consultation.
  /// Weak connectivity automatically starts an audio-only Jitsi meeting.
  static Future<JitsiMeetingResponse> startCall({
    required String consultationId,
    required bool audioOnly,
  }) async {
    final status = await ConnectivityService.instance.refresh();
    if (status == NetworkStatus.offline) {
      throw const CallServiceException(
        'No internet connection is available for a Jitsi call.',
      );
    }

    final user = await AuthService.getUser();
    final userName = user?['name'] as String? ?? 'GramHealth User';
    final userEmail = user?['email'] as String? ?? '';

    // Force audio-only mode on weak networks so the call can still proceed.
    final bool forceAudio = audioOnly || (status == NetworkStatus.weak);

    final options = JitsiMeetingOptions(
      roomNameOrUrl: roomNameForConsultation(consultationId),
      serverUrl: AppConfig.jitsiServerUrl,
      isAudioOnly: forceAudio,
      isAudioMuted: false,
      isVideoMuted: forceAudio,
      userDisplayName: userName,
      userEmail: userEmail,
    );

    try {
      return await JitsiMeetWrapper.joinMeeting(
        options: options,
        listener: JitsiMeetingListener(
          onConferenceWillJoin: (url) => debugPrint('Jitsi conference will join: $url'),
          onConferenceJoined: (url) => debugPrint('Jitsi conference joined: $url'),
          onConferenceTerminated: (url, error) => debugPrint(
            'Jitsi conference terminated: $url${error == null ? '' : ' ($error)'}',
          ),
          onClosed: () => debugPrint('Jitsi meeting closed'),
        ),
      );
    } catch (error) {
      debugPrint('Failed to start Jitsi call: $error');
      throw CallServiceException('Unable to start the consultation call. Please try again.');
    }
  }

  /// Opens the device's carrier dialer. This is the only reliable fallback
  /// when packet data is unavailable; it still requires cellular voice service.
  static Future<void> startPhoneCall(String phoneNumber) async {
    final normalized = phoneNumber.replaceAll(RegExp(r'[^0-9+#*]'), '');
    if (normalized.isEmpty) {
      throw const CallServiceException('No phone number is available for this consultation.');
    }

    final launched = await launchUrl(
      Uri(scheme: 'tel', path: normalized),
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      throw const CallServiceException('This device cannot place a phone call.');
    }
  }
}

class CallServiceException implements Exception {
  final String message;

  const CallServiceException(this.message);

  @override
  String toString() => message;
}
