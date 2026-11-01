import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Sensor Sensitivity Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sensitivity', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    const Text('Adjust impact force and rotation threshold for crash detection', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    const SizedBox(height: 12),

                    Row(
                      children: ['low', 'medium', 'high'].map((sens) {
                        final isSel = settings.sensitivity == sens;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    sens.toUpperCase(),
                                    style: TextStyle(
                                      color: isSel ? Colors.white : Colors.white70,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                              selected: isSel,
                              selectedColor: AppColors.primaryRed,
                              onSelected: (_) => settingsNotifier.setSensitivity(sens),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Emergency Countdown Duration
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Emergency Countdown', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    const Text('Time given to press "I\'m Safe" before automatic SMS dispatch', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    const SizedBox(height: 12),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [5, 10, 15, 30].map((sec) {
                          final isSel = settings.countdownSeconds == sec;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(
                                '$sec Seconds',
                                style: TextStyle(
                                  color: isSel ? Colors.white : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              selected: isSel,
                              selectedColor: AppColors.primaryRed,
                              onSelected: (_) => settingsNotifier.setCountdownSeconds(sec),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Preference Toggles (SOS Enabled & Alarm)
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('SOS Enabled', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Automatically trigger emergency alert & SMS on crash', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    value: settings.sosEnabled,
                    activeThumbColor: AppColors.primaryRed,
                    onChanged: (v) => settingsNotifier.setSosEnabled(v),
                  ),
                  const Divider(color: AppColors.darkCardBorder),
                  SwitchListTile(
                    title: const Text('Alarm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Play loud siren and vibrate during crash countdown', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    value: settings.alarmEnabled,
                    activeThumbColor: AppColors.primaryRed,
                    onChanged: (v) => settingsNotifier.setAlarmEnabled(v),
                  ),
                  const Divider(color: AppColors.darkCardBorder),
                  SwitchListTile(
                    title: const Text('Dark Mode', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    value: settings.isDarkMode,
                    activeThumbColor: AppColors.accentEmerald,
                    onChanged: (v) => settingsNotifier.toggleDarkMode(v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                label: const Text('LOGOUT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkCard,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.primaryRed),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
