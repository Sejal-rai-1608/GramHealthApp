import 'dart:convert';
import '../config/app_config.dart';
import 'api_client.dart';
import '../data/local_database.dart';
import 'dart:math' show cos, sqrt, asin;

class PharmacyModel {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String address;
  final List<dynamic> inventories;

  PharmacyModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.inventories,
  });

  factory PharmacyModel.fromJson(Map<String, dynamic> json) {
    return PharmacyModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      address: json['address'] ?? '',
      inventories: json['inventories'] ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'inventories': inventories,
      };

  bool hasMedicine(String medicineName) {
    final lowerMed = medicineName.toLowerCase();
    for (var inv in inventories) {
      if ((inv['medicineName'] as String).toLowerCase().contains(lowerMed)) {
        return inv['inStock'] == true;
      }
    }
    return false;
  }
}

class PharmacySearchResult {
  final PharmacyModel pharmacy;
  final double distanceKm;
  final bool isAvailable;

  PharmacySearchResult(this.pharmacy, this.distanceKm, this.isAvailable);
}

class PharmacyService {
  PharmacyService._();

  static Future<List<PharmacyModel>> syncPharmacies() async {
    try {
      final response = await ApiClient.get('${AppConfig.apiPharmacy}/list');
      final data = response['data'] as List<dynamic>;
      
      final pharmacies = data.map((e) => PharmacyModel.fromJson(e)).toList();
      
      for (var p in pharmacies) {
        await LocalDatabase.instance.cacheData('cached_pharmacies', p.id, p.toJson());
      }
      return pharmacies;
    } catch (e) {
      print('Sync Pharmacies failed: $e');
      throw e;
    }
  }

  static Future<void> updateInventory(String medicineName, bool inStock) async {
    await ApiClient.post('${AppConfig.apiPharmacy}/inventory', {
      'medicineName': medicineName,
      'inStock': inStock,
    });
  }

  static Future<List<PharmacySearchResult>> searchPharmaciesLocal(String medicine, double userLat, double userLon) async {
    final cached = await LocalDatabase.instance.getAllCachedData('cached_pharmacies');
    final pharmacies = cached.map((e) => PharmacyModel.fromJson(e)).toList();

    List<PharmacySearchResult> results = [];
    for (var p in pharmacies) {
      final hasMed = p.hasMedicine(medicine);
      final dist = _calculateDistance(userLat, userLon, p.latitude, p.longitude);
      results.add(PharmacySearchResult(p, dist, hasMed));
    }

    results.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return results;
  }

  /// Calculates distance in km between two lat/lon points using the Haversine formula
  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295; // Math.PI / 180
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }
}
