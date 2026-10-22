import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/app_config.dart';

/// Service to handle Socket.IO communication for real‑time call signaling.
///
/// The backend expects the JWT token in the `auth` payload during the
/// Socket.IO handshake (see `src/socket/authSocket.js`). This service
/// retrieves the token from secure storage, establishes a connection, and
/// provides convenience methods for the call workflow used by the Flutter
/// client.
class CallSocketService {
  CallSocketService._();

  static const _storage = FlutterSecureStorage();
  static IO.Socket? _socket;

  /// Initializes the Socket.IO connection. Must be called before any other
  /// method. Returns a Future that completes when the connection is
  /// established or throws on error.
  static Future<void> init() async {
    // Retrieve JWT token; the key is defined in AppConfig.
    final token = await _storage.read(key: AppConfig.tokenKey);
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found in secure storage');
    }

    // Convert HTTP base URL to WS for Socket.IO.
    // uri.port is always non-null in Dart (defaults to 80/443), so a hosted
    // backend like Render (https://gramhealthapp.onrender.com) resolves to
    // wss://gramhealthapp.onrender.com:443, which is valid.
    final uri = Uri.parse(AppConfig.baseUrl);
    final socketUrl = '${uri.scheme == 'https' ? 'wss' : 'ws'}://${uri.host}:${uri.port}';

    _socket = IO.io(
      socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket']) // Use WebSocket transport.
          .enableForceNew()
          .disableAutoConnect()
          .setExtraHeaders({})
          .setAuth({'token': token})
          .build(),
    );

    // Attach generic error handling.
    _socket!.on('connect_error', (data) {
      // Propagate the error to callers via a stream or log.
      print('[CallSocketService] Connection error: $data');
    });

    // Connect now.
    _socket!.connect();
    // Listen for connection event
    _socket!.on('connect', (_) => print('[CallSocketService] Connected'));
  }

  /// Joins a private consultation room to receive signalling events.
  static Future<void> joinRoom(String consultationId) async {
    _ensureConnected();
    _socket!.emit('joinRoom', {'consultationId': consultationId});
  }

  /// Patient invites the doctor to start a call.
  static Future<void> sendInvite(String consultationId) async {
    _ensureConnected();
    _socket!.emit('callInvite', {'consultationId': consultationId});
  }

  /// Doctor accepts an incoming call.
  static Future<void> acceptCall(String consultationId) async {
    _ensureConnected();
    _socket!.emit('callAccept', {'consultationId': consultationId});
  }

  /// Doctor rejects an incoming call.
  static Future<void> rejectCall(String consultationId) async {
    _ensureConnected();
    _socket!.emit('callReject', {'consultationId': consultationId});
  }

  /// Either participant cancels a pending call.
  static Future<void> cancelCall(String consultationId) async {
    _ensureConnected();
    _socket!.emit('callCancel', {'consultationId': consultationId});
  }

  /// Register a listener for a specific event. The callback receives the
  /// decoded JSON payload.
  static void on(String event, void Function(dynamic) callback) {
    _ensureConnected();
    _socket!.on(event, (data) => callback(data));
  }

  /// Remove a listener for an event.
  static void off(String event) {
    _socket?.off(event);
  }

  /// Clean up the socket connection.
  static void dispose() {
    _socket?.disconnect();
    _socket?.close();
    _socket = null;
  }

  static void _ensureConnected() {
    if (_socket == null) {
      throw Exception('CallSocketService not initialized. Call init() first.');
    }
  }
}
