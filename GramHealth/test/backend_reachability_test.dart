import 'package:flutter_test/flutter_test.dart';
import 'package:ruralcare_flutter/config/app_config.dart';
import 'package:ruralcare_flutter/services/connectivity_service.dart';

void main() {
  group('Backend Reachability & Configuration Tests', () {
    test('AppConfig baseUrl reflects LocalBackendMode correctly', () {
      // Default: adbReverse
      AppConfig.localBackendMode = LocalBackendMode.adbReverse;
      AppConfig.useProduction = false;
      expect(AppConfig.baseUrl, 'http://127.0.0.1:3000');
      expect(AppConfig.apiHealth, 'http://127.0.0.1:3000/api/health');

      // LAN mode
      AppConfig.localBackendMode = LocalBackendMode.lan;
      expect(AppConfig.baseUrl, 'http://192.168.0.102:3000');
      expect(AppConfig.apiHealth, 'http://192.168.0.102:3000/api/health');

      // Custom LAN mode
      AppConfig.lanBackendUrl = 'http://192.168.0.104:3000';
      expect(AppConfig.baseUrl, 'http://192.168.0.104:3000');

      // Production mode
      AppConfig.useProduction = true;
      expect(AppConfig.baseUrl, 'https://gramhealthapp.onrender.com');
      expect(AppConfig.apiHealth, 'https://gramhealthapp.onrender.com/api/health');

      // Reset
      AppConfig.useProduction = false;
      AppConfig.localBackendMode = LocalBackendMode.adbReverse;
      expect(AppConfig.baseUrl, 'http://127.0.0.1:3000');
    });

    test('ConnectivityService state defaults', () {
      final service = ConnectivityService.instance;
      expect(service.isOnline, isNotNull);
      expect(service.currentStatus, isNotNull);
      expect(service.statusStream, isNotNull);
    });
  });
}
