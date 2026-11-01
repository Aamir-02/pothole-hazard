import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/ride_provider.dart';
import '../../../core/demo/demo_mode_controller.dart';

class RideStatusCard extends ConsumerWidget {
  const RideStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rideState = ref.watch(rideProvider);
    final rideNotifier = ref.read(rideProvider.notifier);
    final demoState = ref.watch(demoControllerProvider);
    final demoNotifier = ref.read(demoControllerProvider.notifier);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: demoState.isDemoActive
                              ? Colors.orange
                              : (rideState.isRiding ? AppColors.accentEmerald : Colors.amber),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          demoState.isDemoActive
                              ? 'DEMO MODE ACTIVE'
                              : (rideState.isRiding ? 'RIDE IN PROGRESS' : 'READY TO RIDE'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: demoState.isDemoActive
                                ? Colors.orange
                                : (rideState.isRiding ? AppColors.accentEmerald : Colors.amber),
                            letterSpacing: 0.8,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentEmerald.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sensors_rounded, color: AppColors.accentEmerald, size: 14),
                      SizedBox(width: 4),
                      Text('Sensors Active', style: TextStyle(color: AppColors.accentEmerald, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Start / Stop Production Ride Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: rideState.isSaving
                    ? null
                    : () async {
                        if (rideState.isRiding) {
                          final result = await rideNotifier.stopRide();
                          if (context.mounted) {
                            final success = result['success'] == true;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(
                                      success ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        result['message'] ?? (success ? 'Ride saved to Ride History!' : 'Could not save ride'),
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: success ? AppColors.accentEmerald : AppColors.primaryRed,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        } else {
                          if (demoState.isDemoActive) {
                            demoNotifier.stopDemoMode();
                          }
                          rideNotifier.startRide();
                        }
                      },
                icon: rideState.isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : Icon(
                        rideState.isRiding ? Icons.stop_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    rideState.isSaving
                        ? 'SAVING RIDE...'
                        : (rideState.isRiding ? 'STOP RIDE' : 'START RIDE MONITOR'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: rideState.isRiding ? AppColors.primaryRed : AppColors.accentEmerald,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 6,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Demo Mode Presentation Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  if (demoState.isDemoActive) {
                    demoNotifier.stopDemoMode();
                  } else {
                    if (rideState.isRiding) {
                      rideNotifier.stopRide();
                    }
                    demoNotifier.startDemoMode();
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  side: const BorderSide(color: Colors.orange, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  backgroundColor: Colors.orange.withValues(alpha: 0.1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.science_rounded, color: Colors.orange, size: 24),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        demoState.isDemoActive ? '🧪 STOP DEMO MODE' : '🧪 START DEMO MODE',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Colors.orange,
                          letterSpacing: 0.8,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (demoState.isDemoActive) ...[
              const SizedBox(height: 10),

              // Sensitive Demo Mode Information Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.bolt_rounded, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sensitive Demo Mode: Real hardware sensors & GPS active. Minor disturbance triggers alert.',
                        style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Demo Crash & SMS Alert Trigger (convenient for immediate presentation test)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => demoNotifier.triggerDemoCrash(),
                  icon: const Icon(Icons.emergency_rounded, color: Colors.white, size: 20),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '🚨 TRIGGER TEST CRASH & SMS ALERT',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade800,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
