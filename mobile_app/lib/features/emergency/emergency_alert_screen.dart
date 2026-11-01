import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/ride_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/providers/contacts_provider.dart';

import '../../core/services/sms_service.dart';

class EmergencyAlertScreen extends ConsumerStatefulWidget {
  const EmergencyAlertScreen({super.key});

  @override
  ConsumerState<EmergencyAlertScreen> createState() => _EmergencyAlertScreenState();
}

class _EmergencyAlertScreenState extends ConsumerState<EmergencyAlertScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  StreamSubscription<int>? _countdownSub;
  StreamSubscription<SmsDispatchResult>? _smsSub;
  int _currentSeconds = 15;
  bool _isDispatched = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _currentSeconds = settings.countdownSeconds;

    // Ring pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    // Subscribe to emergency service countdown stream if active
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final emergencyService = ref.read(rideProvider.notifier).emergencyService;
      _countdownSub = emergencyService.countdownStream.listen((sec) {
        if (mounted) {
          setState(() {
            _currentSeconds = sec;
            if (sec <= 0) {
              _isDispatched = true;
            }
          });
        }
      });

      _smsSub = emergencyService.smsResultStream.listen((res) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message),
            backgroundColor: res.openedInComposer ? AppColors.accentEmerald : AppColors.primaryRed,
            duration: const Duration(seconds: 4),
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    _countdownSub?.cancel();
    _smsSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _onCancelPressed() async {
    final rideNotifier = ref.read(rideProvider.notifier);
    await rideNotifier.emergencyService.cancelEmergency();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Emergency SOS cancelled. We're glad you are safe!"),
          backgroundColor: AppColors.accentEmerald,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final rideState = ref.watch(rideProvider);
    final contactsState = ref.watch(contactsProvider);
    final emergencyContacts = contactsState.contacts;

    final lat = rideState.latitude;
    final lng = rideState.longitude;
    final googleMapsLink = 'https://maps.google.com/?q=$lat,$lng';

    return Scaffold(
      backgroundColor: const Color(0xFF7F1D1D), // Heavy Emergency Red
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isConstrained = constraints.maxHeight < 640;
            final ringDimension = isConstrained ? 180.0 : 230.0;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight > 40 ? constraints.maxHeight - 40 : 0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Header Badge
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.red.shade900.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'CRASH DETECTED',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    letterSpacing: 1.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          lat == 0.0 && lng == 0.0
                              ? 'Location: Acquiring GPS fix...'
                              : 'Location: ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Animated Countdown Ring
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: ringDimension,
                          height: ringDimension,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red.shade900.withValues(alpha: 0.7),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.shade400.withValues(alpha: 0.6 * _pulseController.value),
                                blurRadius: 40 + 25 * _pulseController.value,
                                spreadRadius: 12 + 12 * _pulseController.value,
                              )
                            ],
                            border: Border.all(color: Colors.white, width: 5),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '$_currentSeconds',
                                    style: TextStyle(
                                      fontSize: isConstrained ? 64 : 80,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'SENDING SOS IN',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white70,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // Dispatched Notification or Action Buttons
                    if (_isDispatched) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.accentEmerald, width: 1.5),
                        ),
                        child: Column(
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_rounded, color: AppColors.accentEmerald, size: 24),
                                SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'SOS Alerts Dispatched!',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'SMS sent to ${emergencyContacts.length} contacts with live location:\n$googleMapsLink',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentEmerald),
                              onPressed: () => context.pop(),
                              child: const Text('DISMISS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      )
                    ] else ...[
                      Column(
                        children: [
                          const Text(
                            'Are you okay? Press Cancel to stop automatic emergency alert.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 16),

                          // CANCEL BUTTON
                          SizedBox(
                            width: double.infinity,
                            height: 58,
                            child: ElevatedButton.icon(
                              onPressed: _onCancelPressed,
                              icon: const Icon(Icons.cancel_rounded, size: 28, color: Colors.white),
                              label: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  "CANCEL (I'M SAFE)",
                                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.1),
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accentEmerald,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                elevation: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
