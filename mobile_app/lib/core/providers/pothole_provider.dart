import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';

class PotholeModel {
  final String id;
  final String reporterName;
  final double latitude;
  final double longitude;
  final String address;
  final String photoUrl;
  final String severity; // LOW, MEDIUM, HIGH
  final String roadType;
  final String description;
  final int upvotes;
  final String status;

  PotholeModel({
    required this.id,
    required this.reporterName,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.photoUrl,
    required this.severity,
    required this.roadType,
    required this.description,
    required this.upvotes,
    required this.status,
  });

  factory PotholeModel.fromJson(Map<String, dynamic> json) {
    return PotholeModel(
      id: json['_id'] ?? json['id'] ?? '',
      reporterName: json['reporterName'] ?? 'Rider',
      latitude: (json['latitude'] ?? 37.7749).toDouble(),
      longitude: (json['longitude'] ?? -122.4194).toDouble(),
      address: json['address'] ?? 'Street Road',
      photoUrl: json['photoUrl'] ?? 'https://images.unsplash.com/photo-1515162816999-a0c47dc192f7?w=400',
      severity: json['severity'] ?? 'MEDIUM',
      roadType: json['roadType'] ?? 'City Street',
      description: json['description'] ?? 'Deep pothole',
      upvotes: json['upvotes'] ?? 1,
      status: json['status'] ?? 'ACTIVE',
    );
  }
}

class PotholeState {
  final bool isLoading;
  final List<PotholeModel> potholes;

  PotholeState({this.isLoading = false, this.potholes = const []});
}

class PotholeNotifier extends StateNotifier<PotholeState> {
  PotholeNotifier() : super(PotholeState()) {
    fetchPotholes();
  }

  Future<void> fetchPotholes() async {
    state = PotholeState(isLoading: true, potholes: state.potholes);
    final res = await ApiClient.get('/potholes');

    if (res['success'] == true && res['potholes'] != null) {
      final list = (res['potholes'] as List).map((x) => PotholeModel.fromJson(x)).toList();
      state = PotholeState(isLoading: false, potholes: list);
    } else {
      // Fallback sample data
      state = PotholeState(isLoading: false, potholes: [
        PotholeModel(
          id: '1',
          reporterName: 'Alex Rider',
          latitude: 37.7769,
          longitude: -122.4164,
          address: 'Oakland Ave & 4th St',
          photoUrl: 'https://images.unsplash.com/photo-1515162816999-a0c47dc192f7?w=400',
          severity: 'HIGH',
          roadType: 'City Street',
          description: 'Deep 8-inch severe pothole right in center lane!',
          upvotes: 14,
          status: 'ACTIVE',
        ),
        PotholeModel(
          id: '2',
          reporterName: 'Carlos M.',
          latitude: 37.7709,
          longitude: -122.4214,
          address: 'Expressway Service Lane',
          photoUrl: 'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=400',
          severity: 'MEDIUM',
          roadType: 'Highway',
          description: 'Cracked asphalt erosion causing rim damage.',
          upvotes: 8,
          status: 'ACTIVE',
        ),
      ]);
    }
  }

  Future<bool> reportPothole({
    required double latitude,
    required double longitude,
    required String severity,
    required String roadType,
    required String description,
  }) async {
    final res = await ApiClient.post('/potholes', {
      'latitude': latitude,
      'longitude': longitude,
      'severity': severity,
      'roadType': roadType,
      'description': description,
    });

    await fetchPotholes();
    return res['success'] == true;
  }

  Future<void> upvotePothole(String id) async {
    await ApiClient.post('/potholes/$id/upvote', {});
    await fetchPotholes();
  }
}

final potholeProvider = StateNotifierProvider<PotholeNotifier, PotholeState>((ref) {
  return PotholeNotifier();
});
