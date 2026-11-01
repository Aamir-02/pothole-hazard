import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/ride_provider.dart';

import '../../../core/demo/demo_mode_controller.dart';

class QuickSosButton extends ConsumerWidget {
  const QuickSosButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demoState = ref.watch(demoControllerProvider);

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton.icon(
            onPressed: () => context.push('/emergency'),
            icon: const Icon(Icons.sos_rounded, size: 32, color: Colors.white),
            label: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'QUICK SOS EMERGENCY',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 8,
              shadowColor: AppColors.primaryRed.withValues(alpha: 0.6),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Simulation crash button for testing
        TextButton.icon(
          onPressed: () {
            if (demoState.isDemoActive) {
              ref.read(demoControllerProvider.notifier).triggerDemoCrash();
            } else {
              ref.read(rideProvider.notifier).simulateCrashEvent(
                onCrashDetected: () => context.push('/emergency'),
              );
            }
          },
          icon: Icon(
            demoState.isDemoActive ? Icons.science_rounded : Icons.bug_report_rounded,
            size: 16,
            color: demoState.isDemoActive ? Colors.orange : Colors.amber,
          ),
          label: Text(
            demoState.isDemoActive
                ? '🧪 Trigger Demo Crash (Test SMS & GPS)'
                : 'Simulate Crash Impact Trigger',
            style: TextStyle(
              color: demoState.isDemoActive ? Colors.orange : Colors.amber,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
