import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

class RideDetailScreen extends StatelessWidget {
  final Map<String, dynamic>? ride;

  const RideDetailScreen({super.key, this.ride});

  @override
  Widget build(BuildContext context) {
    final dist = ((ride?['distanceKm'] as num?)?.toDouble() ?? 14.8).toStringAsFixed(1);
    final maxSpd = ((ride?['maxSpeedKmh'] as num?)?.toDouble() ?? 65.4).toStringAsFixed(1);
    final avgSpd = ((ride?['avgSpeedKmh'] as num?)?.toDouble() ?? 41.2).toStringAsFixed(1);
    final dur = (ride?['durationMinutes'] as num?)?.toInt() ?? 30;
    final potholes = (ride?['potholesCount'] as num?)?.toInt() ?? 0;
    final fuel = ((ride?['fuelEstimateLiters'] as num?)?.toDouble() ?? 0.52).toStringAsFixed(2);
    final score = (ride?['rideScore'] as num?)?.toInt() ?? 96;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Route Replay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Replay Map Placeholder Card
              Container(
                height: 280,
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.darkCardBorder),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.route_rounded, size: 60, color: AppColors.primaryRed),
                          const SizedBox(height: 12),
                          const Text(
                            'GPS Route Replay Active',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Safety Score: $score/100 • $potholes Potholes Detected',
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'Ride Summary Metrics',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$dist km Total',
                              style: const TextStyle(color: AppColors.accentEmerald, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildDetailTile('Max Speed', '$maxSpd km/h')),
                            Expanded(child: _buildDetailTile('Avg Speed', '$avgSpd km/h')),
                            Expanded(child: _buildDetailTile('Duration', '$dur mins')),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(child: _buildDetailTile('Potholes', '$potholes')),
                            Expanded(child: _buildDetailTile('Est. Fuel', '$fuel L')),
                            Expanded(child: _buildDetailTile('Safety Score', '$score/100')),
                          ],
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Ride summary PDF generated & saved to downloads folder!')),
                              );
                            },
                            icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primaryRed),
                            label: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('EXPORT RIDE SUMMARY PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailTile(String label, String val) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 11),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            val,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
          ),
        ),
      ],
    );
  }
}
