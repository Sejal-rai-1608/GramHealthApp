import 'package:jitsi_meet_wrapper/jitsi_meet_wrapper.dart';
import 'auth_service.dart';
import 'connectivity_service.dart';

class CallService {
  CallService._();

  /// Joins a Jitsi video or audio call for a given consultation.
  /// Force falls back to audio-only if [audioOnly] is true.
  static Future<void> startCall({
    required String consultationId,
    required bool audioOnly,
  }) async {
    try {
      final status = ConnectivityService.instance.currentStatus;
      if (status == NetworkStatus.offline) {
        throw Exception("ERROR_OFFLINE");
      }

      final user = await AuthService.getUser();
      final userName = user?['name'] as String? ?? 'GramHealth User';
      final userEmail = user?['email'] as String? ?? '';

      // Force UI-level fallback if network is weak
      final bool forceAudio = audioOnly || (status == NetworkStatus.weak);

      final options = JitsiMeetingOptions(
        roomNameOrUrl: 'gramhealth_call_$consultationId',
        serverUrl: 'https://meet.ffmuc.net', // Open source Jitsi instance to bypass meet.jit.si auth restrictions
        isAudioOnly: forceAudio,
        isAudioMuted: false,
        isVideoMuted: forceAudio,
        userDisplayName: userName,
        userEmail: userEmail,
        featureFlags: {
          'lobby-mode.enabled': false,
          'meeting-password.enabled': false,
          'prejoinpage.enabled': false,
          'welcomepage.enabled': false,
          'invite.enabled': false,
        },
      );

      await JitsiMeetWrapper.joinMeeting(
        options: options,
      );
    } catch (e) {
      print('Failed to start call: $e');
      rethrow;
    }
  }
}
