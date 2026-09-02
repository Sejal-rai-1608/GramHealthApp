import 'package:jitsi_meet_wrapper/jitsi_meet_wrapper.dart';
import 'auth_service.dart';

class CallService {
  CallService._();

  /// Joins a Jitsi video or audio call for a given consultation.
  /// Force falls back to audio-only if [audioOnly] is true.
  static Future<void> startCall({
    required String consultationId,
    required bool audioOnly,
  }) async {
    try {
      final user = await AuthService.getUser();
      final userName = user?['name'] as String? ?? 'GramHealth User';
      final userEmail = user?['email'] as String? ?? '';

      final options = JitsiMeetingOptions(
        roomNameOrUrl: 'gramhealth-call-$consultationId',
        // Our adaptive low-bandwidth setup:
        isAudioOnly: audioOnly,
        isAudioMuted: false,
        isVideoMuted: audioOnly,
        userDisplayName: userName,
        userEmail: userEmail,
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
