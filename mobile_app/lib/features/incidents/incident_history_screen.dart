import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/demo/demo_mode_controller.dart';

class IncidentHistoryScreen extends ConsumerWidget {
  const IncidentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demoState = ref.watch(demoControllerProvider);

    final defaultIncidents = [
      {
        'id': 'INC-901',
        'time': 'Today, 01:10 PM',
        'location': 'Expressway Flyover KM 12 (37.7749, -122.4194)',
        'confidence': '98%',
        'severity': 'CRITICAL',
        'status': 'SENT (2 SMS)',
        'type': 'Crash',
        'accelG': '4.8G',
        'gyroRad': '6.2 rad/s',
      },
      {
        'id': 'INC-895',
        'time': '31 July, 02:20 PM',
        'location': 'Downtown Alleyway (37.7651, -122.4241)',
        'confidence': '84%',
        'severity': 'MEDIUM',
        'status': 'CONFIRMED SAFE',
        'type': 'Crash',
        'accelG': '3.5G',
        'gyroRad': '2.1 rad/s',
      },
    ];

    final allIncidents = [...demoState.demoIncidents, ...defaultIncidents];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: allIncidents.length,
          itemBuilder: (context, index) {
            final inc = allIncidents[index];
            final isDemo = inc['type'] == 'Demo Crash';

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: isDemo ? const BorderSide(color: Colors.orange, width: 1.5) : BorderSide.none,
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                inc['id']!,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: isDemo ? Colors.orange : AppColors.primaryRed,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDemo ? Colors.orange.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Type: ${inc['type'] ?? 'Crash'}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isDemo ? Colors.orange : AppColors.primaryRed,
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDemo
                                ? Colors.orange
                                : (inc['severity'] == 'CRITICAL' ? AppColors.primaryRed : AppColors.accentAmber),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            inc['severity']!,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(inc['location']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(inc['time']!, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Crash Confidence: ${inc['confidence']}',
                              style: TextStyle(
                                color: isDemo ? Colors.orange : AppColors.primaryRed,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Accel: ${inc['accelG']} | Gyro: ${inc['gyroRad']}',
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Status: ${inc['status']}',
                            style: const TextStyle(color: AppColors.accentEmerald, fontWeight: FontWeight.bold, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incident record removed')));
                          },
                        )
                      ],
                    )
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
