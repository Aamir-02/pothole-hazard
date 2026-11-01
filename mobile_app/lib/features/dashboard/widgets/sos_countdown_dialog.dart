import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class SosCountdownDialog extends StatelessWidget {
  final Stream<int> countdownStream;
  final int initialRemainingSeconds;
  final VoidCallback onCancel;
  final VoidCallback onSendNow;

  const SosCountdownDialog({
    super.key,
    required this.countdownStream,
    required this.initialRemainingSeconds,
    required this.onCancel,
    required this.onSendNow,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.primaryRed, width: 2),
        ),
        backgroundColor: const Color(0xFF1E1E2C),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Alarm Header Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.primaryRed,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),

              // Title
              const Text(
                '🚨 Crash Detected',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Live Countdown Stream Text & Gauge
              StreamBuilder<int>(
                stream: countdownStream,
                initialData: initialRemainingSeconds,
                builder: (context, snapshot) {
                  final seconds = snapshot.data ?? initialRemainingSeconds;

                  return Column(
                    children: [
                      Text(
                        'Emergency SOS will be sent in $seconds seconds.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      // Circular countdown indicator
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 100,
                            height: 100,
                            child: CircularProgressIndicator(
                              value: seconds > 0 ? (seconds / 15.0).clamp(0.0, 1.0) : 0.0,
                              strokeWidth: 8,
                              backgroundColor: Colors.white12,
                              color: AppColors.primaryRed,
                            ),
                          ),
                          Text(
                            '$seconds',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primaryRed,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),

              // Action Buttons
              Row(
                children: [
                  // "I'm Safe" Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          "I'm Safe",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentEmerald,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // "Send SOS Now" Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onSendNow,
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Send SOS Now',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
