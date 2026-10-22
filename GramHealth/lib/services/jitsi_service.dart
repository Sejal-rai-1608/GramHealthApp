import 'package:flutter/foundation.dart';
import 'package:jitsi_meet/jitsi_meet.dart';
import '../config/app_config.dart';
import '../services/api_client.dart';

class JitsiMeetingDetails {
  final String roomName;
  final String serverUrl;
  final String consultationType;
  final String consultationId;

  JitsiMeetingDetails({
    required this.roomName,
    required this.serverUrl,
    required this.consultationType,
    required this.consultationId,
  });

  factory JitsiMeetingDetails.fromJson(Map<String, dynamic> json) {
    return JitsiMeetingDetails(
      roomName: json['roomName'] as String,
      serverUrl: json['serverUrl'] as String,
      consultationType: json['consultationType'] as String,
      consultationId: json['consultationId'] as String,
    );
  }

  @override
  String toString() {
    return 'JitsiMeetingDetails(roomName: $roomName, serverUrl: $serverUrl, consultationType: $consultationType, consultationId: $consultationId)';
  }
}

class JitsiService {
  JitsiService._();

  /// Fetch Jitsi meeting details from backend
  static Future<JitsiMeetingDetails> fetchMeetingDetails(String consultationId) async {
    try {
      final response = await ApiClient.get('${AppConfig.apiConsultations}/$consultationId/jitsi');
      debugPrint('[JitsiService] Backend response: $response');
      final details = JitsiMeetingDetails.fromJson(response['data'] as Map<String, dynamic>);
      debugPrint('[JitsiService] Parsed meeting details: $details');
      return details;
    } catch (e) {
      debugPrint('[JitsiService] Failed to fetch meeting details: $e');
      rethrow;
    }
  }

  /// Join a Jitsi meeting
  static Future<JitsiMeetingResponse> joinMeeting({
    required String roomName,
    required String serverUrl,
    required String userDisplayName,
    required bool audioOnly,
    String? userEmail,
    JitsiMeetingListener? listener,
  }) async {
    try {
      debugPrint('[JitsiService] Joining meeting - roomName: $roomName, serverUrl: $serverUrl, userDisplayName: $userDisplayName, audioOnly: $audioOnly');

      final options = JitsiMeetingOptions(
        room: roomName,
        serverURL: serverUrl,
        userDisplayName: userDisplayName,
        userEmail: userEmail,
        audioOnly: audioOnly,
        audioMuted: false,
        videoMuted: audioOnly,
        // Disable Jitsi Meet lobby/password screens so participants join directly
        featureFlags: {
          FeatureFlagEnum.WELCOME_PAGE_ENABLED: false,
          FeatureFlagEnum.MEETING_PASSWORD_ENABLED: false,
          FeatureFlagEnum.CALENDAR_ENABLED: false,
          FeatureFlagEnum.CALL_INTEGRATION_ENABLED: false,
        },
      );

      final response = await JitsiMeet.joinMeeting(
        options: options,
        listener: listener,
      );
      debugPrint('[JitsiService] Joined meeting: $roomName, response: $response');
      return response;
    } catch (e) {
      debugPrint('[JitsiService] Join meeting error: $e');
      rethrow;
    }
  }

  /// Leave the current Jitsi meeting
  static Future<JitsiMeetingResponse> leaveMeeting() async {
    try {
      final response = await JitsiMeet.closeMeeting();
      debugPrint('[JitsiService] Left meeting, response: $response');
      return response;
    } catch (e) {
      debugPrint('[JitsiService] Leave meeting error: $e');
      rethrow;
    }
  }

  /// Toggle audio mute
  static Future<void> toggleAudioMute(bool mute) async {
    try {
      await JitsiMeet.executeCommand('toggleAudio', [mute.toString()]);
      debugPrint('[JitsiService] Audio mute toggled: $mute');
    } catch (e) {
      debugPrint('[JitsiService] Toggle audio mute error: $e');
      rethrow;
    }
  }

  /// Toggle video mute - requires native implementation
  static Future<void> toggleVideoMute(bool mute) async {
    debugPrint('[JitsiService] Video mute toggle requested: $mute (requires native implementation)');
  }

  /// Switch camera - requires native implementation
  static Future<void> switchCamera() async {
    debugPrint('[JitsiService] Switch camera requested (requires native implementation)');
  }
}
