import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/pothole_provider.dart';
import 'report_pothole_sheet.dart';

class PotholesMapScreen extends ConsumerWidget {
  const PotholesMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final potholeState = ref.watch(potholeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Pothole Hazards', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const ReportPotholeSheet(),
          );
        },
        backgroundColor: AppColors.primaryRed,
        icon: const Icon(Icons.add_a_photo_rounded, color: Colors.white),
        label: const Text('REPORT POTHOLE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Map Visual Section
            Container(
              height: 220,
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.darkCardBorder),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.map_rounded, size: 50, color: AppColors.accentAmber),
                        const SizedBox(height: 8),
                        Text(
                          'Google Maps Layer Active (${potholeState.potholes.length} Hazards)',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text(
                          'Heatmap overlay active for SF metropolitan area',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_rounded, color: AppColors.primaryRed, size: 14),
                          SizedBox(width: 4),
                          Text('LIVE HEATMAP', style: TextStyle(color: AppColors.primaryRed, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),

            // Pothole Cards List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: potholeState.potholes.length,
                itemBuilder: (context, index) {
                  final p = potholeState.potholes[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  p.address,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: p.severity == 'HIGH' ? AppColors.primaryRed : AppColors.accentAmber,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${p.severity} SEVERITY',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(p.description, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Reported by ${p.reporterName}',
                                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: () {
                                  ref.read(potholeProvider.notifier).upvotePothole(p.id);
                                },
                                icon: const Icon(Icons.thumb_up_rounded, size: 16, color: AppColors.accentEmerald),
                                label: Text('Confirm (${p.upvotes})', style: const TextStyle(color: AppColors.accentEmerald, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
