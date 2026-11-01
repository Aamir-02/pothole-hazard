import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/ride_provider.dart';
import '../../../core/demo/demo_mode_controller.dart';

class SpeedometerWidget extends ConsumerWidget {
  const SpeedometerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rideState = ref.watch(rideProvider);
    final demoState = ref.watch(demoControllerProvider);

    final isDemo = demoState.isDemoActive;
    final currentSpeed = isDemo ? demoState.currentSpeedKmh : rideState.currentSpeedKmh;
    final maxSpeed = isDemo ? demoState.maxSpeedKmh : rideState.maxSpeedKmh;
    final distance = isDemo ? demoState.distanceKm : rideState.distanceKm;
    final accel = isDemo ? demoState.totalAccelMs2 : rideState.totalAccelMs2;
    final gyro = isDemo ? demoState.gyroRadSec : rideState.gyroRadSec;
    final lat = isDemo ? demoState.latitude : rideState.latitude;
    final lng = isDemo ? demoState.longitude : rideState.longitude;
    final statusMsg = isDemo ? demoState.statusMessage : rideState.statusMessage;
    final potholeCount = isDemo ? demoState.potholeCount : rideState.potholeCount;
    final statusColor = isDemo ? Colors.orange : _getStatusColor(statusMsg);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          children: [
            // Status Header Badge with Flexible containment
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        isDemo ? Icons.science_rounded : Icons.shield_outlined,
                        color: isDemo ? Colors.orange : Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isDemo ? 'DEMO SENSORS:' : 'RIDE STATUS:',
                        style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: statusColor, width: 1),
                          ),
                          child: Text(
                            statusMsg.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Potholes: $potholeCount',
                  style: const TextStyle(color: AppColors.accentAmber, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                // Circular Speed Display with responsive dimension
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isDemo
                        ? const LinearGradient(
                            colors: [Colors.deepOrange, Colors.orange],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : AppColors.brandGradient,
                    boxShadow: [
                      BoxShadow(
                        color: (isDemo ? Colors.orange : AppColors.primaryRed).withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${currentSpeed.round()}',
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, height: 1),
                        ),
                        const Text('KM/H', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Riding Telemetry Metrics Grid (Responsive with Expanded items)
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricItem(
                              'Acceleration',
                              '${accel.toStringAsFixed(1)} m/s²',
                              Icons.speed_rounded,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMetricItem(
                              'Gyroscope',
                              '${gyro.toStringAsFixed(2)} rad/s',
                              Icons.screen_rotation_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricItem(
                              'Max Speed',
                              '${maxSpeed.round()} km/h',
                              Icons.shutter_speed_rounded,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMetricItem(
                              'Distance',
                              '${distance.toStringAsFixed(2)} km',
                              Icons.straighten_rounded,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(color: AppColors.darkCardBorder),
            const SizedBox(height: 8),

            // Live GPS Location Row
            Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  color: isDemo ? Colors.orange : AppColors.accentEmerald,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  isDemo ? 'Current GPS:' : 'Current GPS:',
                  style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    lat == 0.0 && lng == 0.0
                        ? 'Acquiring GPS fix...'
                        : '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'monitoring':
        return AppColors.accentBlue;
      case 'safe':
        return AppColors.accentEmerald;
      case 'pothole detected':
        return AppColors.accentAmber;
      case 'crash detected':
        return AppColors.primaryRed;
      default:
        return Colors.white;
    }
  }

  Widget _buildMetricItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: AppColors.primaryRed),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}
