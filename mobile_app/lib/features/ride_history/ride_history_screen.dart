import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/api_client.dart';
import '../../core/constants/api_constants.dart';

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _rides = [];

  @override
  void initState() {
    super.initState();
    _fetchRideHistory();
  }

  Future<void> _fetchRideHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiClient.get(ApiConstants.rideHistory);
      if (response is Map<String, dynamic> && response['success'] == true) {
        final list = response['rides'];
        if (list is List) {
          setState(() {
            _rides = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
            _isLoading = false;
          });
          return;
        }
      }

      setState(() {
        _errorMessage = response is Map<String, dynamic>
            ? (response['message'] ?? 'Failed to load ride history')
            : 'Server communication error';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Network connection failed: $e';
        _isLoading = false;
      });
    }
  }

  String _formatDate(dynamic dateVal) {
    if (dateVal == null) return 'Recent Ride';
    try {
      final dt = DateTime.parse(dateVal.toString()).toLocal();
      final now = DateTime.now();
      final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      if (isToday) {
        return 'Today, $hour:$minute';
      }
      return '${dt.day}/${dt.month}/${dt.year}, $hour:$minute';
    } catch (_) {
      return dateVal.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride History & Replay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: _fetchRideHistory,
          ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryRed),
      );
    }

    if (_errorMessage != null && _rides.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 56, color: Colors.white38),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _fetchRideHistory,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                label: const Text('Retry', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_rides.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchRideHistory,
        color: AppColors.primaryRed,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(32),
          children: const [
            SizedBox(height: 120),
            Icon(Icons.two_wheeler_rounded, size: 68, color: Colors.white24),
            SizedBox(height: 20),
            Text(
              'No rides recorded yet',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Start a ride monitor from the Dashboard to track your journey, GPS distance, and potholes.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchRideHistory,
      color: AppColors.primaryRed,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _rides.length,
        itemBuilder: (context, index) {
          final r = _rides[index];
          final dateStr = _formatDate(r['startTime'] ?? r['createdAt']);
          final distStr = '${((r['distanceKm'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(1)} km';
          final durStr = '${(r['durationMinutes'] as num?)?.toInt() ?? 0} mins';
          final avgSpeedStr = '${((r['avgSpeedKmh'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(1)} km/h';
          final maxSpeedStr = '${((r['maxSpeedKmh'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(1)} km/h';
          final potholes = (r['potholesCount'] as num?)?.toInt() ?? 0;
          final fuelStr = '${((r['fuelEstimateLiters'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)} L';
          final score = (r['rideScore'] as num?)?.toInt() ?? 100;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          dateStr,
                          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accentEmerald.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Score: $score/100',
                          style: const TextStyle(color: AppColors.accentEmerald, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(child: _buildStatCol('Distance', distStr)),
                      Expanded(child: _buildStatCol('Duration', durStr)),
                      Expanded(child: _buildStatCol('Avg Speed', avgSpeedStr)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildStatCol('Max Speed', maxSpeedStr)),
                      Expanded(child: _buildStatCol('Potholes', '$potholes')),
                      Expanded(child: _buildStatCol('Est. Fuel', fuelStr)),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryRed,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => context.push('/ride-detail', extra: r),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Replay Map', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCol(String title, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white38, fontSize: 10),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            val,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
