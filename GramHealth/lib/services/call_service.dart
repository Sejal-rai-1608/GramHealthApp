import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class CallService {
  CallService._();

  /// Initiates a Jitsi Meet consultation call (audio or video)
  /// Replaces the old cellular call implementation
  static Future<void> startCall({
    required BuildContext context,
    required String consultationId,
    required bool audioOnly,
    String? doctorId,
    String? doctorName,
    String? doctorPhone,
    String? patientName,
    String? userRole, // 'patient' or 'doctor'
  }) async {
    debugPrint('[CallService] Starting Jitsi consultation for $consultationId (audioOnly: $audioOnly)');

    try {
      // Navigate to Jitsi meeting screen
      if (context.mounted) {
        context.push(
          '/jitsi-meeting/$consultationId',
          extra: {
            'participantName': userRole == 'doctor' ? doctorName : patientName,
            'participantRole': userRole,
            'audioOnly': audioOnly,
          },
        );
      }
    } catch (e) {
      debugPrint('[CallService] Jitsi call error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start consultation: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Convenience method to start an audio‑only Jitsi call
  static Future<void> startAudioCall({
    required BuildContext context,
    required String consultationId,
    String? doctorId,
    String? doctorName,
    String? doctorPhone,
    String? patientName,
    String? userRole,
  }) async {
    await startCall(
      context: context,
      consultationId: consultationId,
      audioOnly: true,
      doctorId: doctorId,
      doctorName: doctorName,
      doctorPhone: doctorPhone,
      patientName: patientName,
      userRole: userRole,
    );
  }

  /// Convenience method to start a video Jitsi call
  static Future<void> startVideoCall({
    required BuildContext context,
    required String consultationId,
    String? doctorId,
    String? doctorName,
    String? doctorPhone,
    String? patientName,
    String? userRole,
  }) async {
    await startCall(
      context: context,
      consultationId: consultationId,
      audioOnly: false,
      doctorId: doctorId,
      doctorName: doctorName,
      doctorPhone: doctorPhone,
      patientName: patientName,
      userRole: userRole,
    );
  }

  /// Direct cellular call fallback when offline
  static Future<void> startCellularCall({
    required BuildContext context,
    required String phoneNumber,
  }) async {
    try {
      await FlutterPhoneDirectCaller.callNumber(phoneNumber);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start cellular call: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Starts a Jitsi call with network fallback. If offline, uses cellular call.
  static Future<void> startCallWithFallback({
    required BuildContext context,
    required String consultationId,
    required bool audioOnly,
    String? doctorId,
    String? doctorName,
    String? doctorPhone,
    String? patientName,
    String? userRole,
  }) async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        // No internet, fallback to cellular call using doctor's phone if available
        if (doctorPhone != null && doctorPhone.isNotEmpty) {
          await startCellularCall(context: context, phoneNumber: doctorPhone);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('No internet and no phone number for fallback.'),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } else {
        // Online, start normal Jitsi call
        await startCall(
          context: context,
          consultationId: consultationId,
          audioOnly: audioOnly,
          doctorId: doctorId,
          doctorName: doctorName,
          doctorPhone: doctorPhone,
          patientName: patientName,
          userRole: userRole,
        );
      }
    } catch (e) {
      debugPrint('[CallService] startCallWithFallback error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initiate call: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
