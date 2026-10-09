import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:go_router/go_router.dart';
import '../data/local_database.dart';
import 'doctor_service.dart';

class CallService {
  CallService._();

  /// Initiates an immediate, real cellular phone call directly to the doctor
  /// using flutter_phone_direct_caller without redirecting to the dialer keypad screen.
  static Future<void> startCall({
    required BuildContext context,
    required String consultationId,
    required bool audioOnly,
    String? doctorId,
    String? doctorName,
    String? doctorPhone,
  }) async {
    String? phoneNum = doctorPhone?.trim();
    final docId = (doctorId != null && doctorId.isNotEmpty) ? doctorId : '1';

    // 1. Resolve doctor phone from local database cache if missing
    if (phoneNum == null || phoneNum.isEmpty) {
      try {
        final cached = await LocalDatabase.instance.getCachedData('cached_doctors', docId);
        if (cached != null) {
          final doc = DoctorModel.fromJson(cached);
          phoneNum = doc.phone?.trim();
        }
      } catch (e) {
        debugPrint('[CallService] Error resolving cached doctor phone: $e');
      }
    }

    // 2. Default fallback number if unassigned
    if (phoneNum == null || phoneNum.isEmpty) {
      phoneNum = '9876543210';
    }

    debugPrint('[CallService] Initiating direct cellular call to doctor $docId ($phoneNum)...');

    try {
      final bool? res = await FlutterPhoneDirectCaller.callNumber(phoneNum);
      if (res == false) {
        debugPrint('[CallService] Direct call returned false or cancelled. Launching in-app fallback screen...');
        if (context.mounted) {
          context.push('/video-call/$docId', extra: {
            'doctorName': doctorName,
            'doctorPhone': phoneNum,
            'isAudioOnly': audioOnly,
          });
        }
      }
    } catch (e) {
      debugPrint('[CallService] Direct caller exception: $e. Navigating to in-app call screen.');
      if (context.mounted) {
        context.push('/video-call/$docId', extra: {
          'doctorName': doctorName,
          'doctorPhone': phoneNum,
          'isAudioOnly': audioOnly,
        });
      }
    }
  }
}
