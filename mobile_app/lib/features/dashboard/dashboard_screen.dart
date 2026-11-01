import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/emergency_service.dart';
import '../../core/services/sms_service.dart';
import '../../core/demo/demo_mode_controller.dart';
import '../../core/demo/demo_constants.dart';
import 'widgets/ride_status_card.dart';
import 'widgets/speedometer_widget.dart';
import 'widgets/quick_sos_button.dart';
import 'widgets/weather_road_banner.dart';
import 'widgets/sos_countdown_dialog.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  StreamSubscription<SosState>? _demoSosSubscription;
  StreamSubscription<SmsDispatchResult>? _demoSmsSubscription;
  bool _isDialogShowing = false;
  BuildContext? _dialogContext;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenToDemoSosStream();
    });
  }

  void _listenToDemoSosStream() {
    final demoSosService = ref.read(demoControllerProvider.notifier).demoSosService;

    // Listen only to DemoModeController SOS Stream
    _demoSosSubscription?.cancel();
    _demoSosSubscription = demoSosService.sosStateStream.listen((sosState) {
      if (!mounted) return;
      if (sosState == SosState.countingDown) {
        if (!_isDialogShowing) {
          _showSosCountdownDialog(
            countdownStream: demoSosService.countdownStream,
            initialSeconds: demoSosService.remainingSeconds,
            onCancel: () => demoSosService.cancelEmergency(),
            onSendNow: () => demoSosService.triggerImmediateSos(),
          );
        }
      } else {
        if (_isDialogShowing) {
          _dismissSosDialog();
        }
      }
    });

    // Listen to Demo SMS Results
    _demoSmsSubscription?.cancel();
    _demoSmsSubscription = demoSosService.smsResultStream.listen((res) {
      if (!mounted) return;
      _dismissSosDialog();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                res.openedInComposer ? Icons.mark_email_read_rounded : Icons.error_outline_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  res.message,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: res.openedInComposer ? AppColors.accentEmerald : AppColors.primaryRed,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  void _showSosCountdownDialog({
    required Stream<int> countdownStream,
    required int initialSeconds,
    required VoidCallback onCancel,
    required VoidCallback onSendNow,
  }) {
    setState(() {
      _isDialogShowing = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        _dialogContext = dialogCtx;
        return SosCountdownDialog(
          countdownStream: countdownStream,
          initialRemainingSeconds: initialSeconds,
          onCancel: () {
            onCancel();
            _dismissSosDialog();
          },
          onSendNow: () {
            onSendNow();
            _dismissSosDialog();
          },
        );
      },
    ).then((_) {
      _isDialogShowing = false;
      _dialogContext = null;
    });
  }

  void _dismissSosDialog() {
    if (_isDialogShowing && _dialogContext != null && Navigator.canPop(_dialogContext!)) {
      Navigator.pop(_dialogContext!);
    }
    _isDialogShowing = false;
    _dialogContext = null;
  }

  @override
  void dispose() {
    _demoSosSubscription?.cancel();
    _demoSmsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final demoState = ref.watch(demoControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Orange Demo Mode Active Banner
              if (demoState.isDemoActive) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.science_rounded, color: Colors.white, size: 22),
                      SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          DemoConstants.bannerText,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            letterSpacing: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // User Greeting Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.primaryRed,
                          child: Text(
                            ((authState.user?['name'] as String?)?.isNotEmpty ?? false)
                                ? (authState.user!['name'] as String)[0].toUpperCase()
                                : 'R',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back,',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                              ),
                              Text(
                                authState.user?['name'] ?? 'Rider',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.settings_rounded, color: Colors.white),
                    onPressed: () => context.push('/settings'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Weather & Road Banner
              const WeatherRoadBanner(),
              const SizedBox(height: 16),

              // Ride Status Action Card
              const RideStatusCard(),
              const SizedBox(height: 16),

              // Speedometer & Telemetry Card
              const SpeedometerWidget(),
              const SizedBox(height: 16),

              // Quick SOS Emergency Button
              const QuickSosButton(),
              const SizedBox(height: 20),

              // Navigation Shortcut Cards Grid
              Row(
                children: [
                  Expanded(
                    child: _buildShortcutCard(
                      context,
                      title: 'Pothole Map',
                      subtitle: '2 Nearby Hazards',
                      icon: Icons.map_rounded,
                      color: AppColors.accentAmber,
                      onTap: () => context.push('/potholes'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildShortcutCard(
                      context,
                      title: 'Contacts',
                      subtitle: 'SOS Dispatch List',
                      icon: Icons.contact_phone_rounded,
                      color: AppColors.accentBlue,
                      onTap: () => context.push('/contacts'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildShortcutCard(
                      context,
                      title: 'Ride History',
                      subtitle: 'Replay Routes',
                      icon: Icons.history_rounded,
                      color: AppColors.accentEmerald,
                      onTap: () => context.push('/ride-history'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildShortcutCard(
                      context,
                      title: 'Incidents',
                      subtitle: 'Alert Logs',
                      icon: Icons.report_problem_rounded,
                      color: AppColors.primaryRed,
                      onTap: () => context.push('/incidents'),
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

  Widget _buildShortcutCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Colors.white54),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
