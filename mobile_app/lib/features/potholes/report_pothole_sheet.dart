import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/pothole_provider.dart';

class ReportPotholeSheet extends ConsumerStatefulWidget {
  const ReportPotholeSheet({super.key});

  @override
  ConsumerState<ReportPotholeSheet> createState() => _ReportPotholeSheetState();
}

class _ReportPotholeSheetState extends ConsumerState<ReportPotholeSheet> {
  String _severity = 'MEDIUM';
  final String _roadType = 'City Street';
  final _descController = TextEditingController(text: 'Deep asphalt erosion pothole near lane divider.');
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  void _submitReport() async {
    setState(() => _isSubmitting = true);
    await ref.read(potholeProvider.notifier).reportPothole(
      latitude: 37.7769,
      longitude: -122.4164,
      severity: _severity,
      roadType: _roadType,
      description: _descController.text,
    );
    setState(() => _isSubmitting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pothole report submitted successfully! Thank you for keeping riders safe.')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Report Pothole Hazard',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.close, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 16),

          // Photo Preview Mock
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.darkCardBorder),
              image: const DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1515162816999-a0c47dc192f7?w=400'),
                fit: BoxFit.cover,
              ),
            ),
            child: const Center(
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: Icon(Icons.camera_alt_rounded, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Severity Selector
          const Text('Severity Level', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: ['LOW', 'MEDIUM', 'HIGH'].map((sev) {
              final selected = _severity == sev;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Center(child: Text(sev, style: TextStyle(color: selected ? Colors.white : Colors.white70, fontWeight: FontWeight.bold))),
                    selected: selected,
                    selectedColor: sev == 'HIGH' ? AppColors.primaryRed : sev == 'MEDIUM' ? AppColors.accentAmber : AppColors.accentBlue,
                    onSelected: (val) => setState(() => _severity = sev),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Description Input
          TextField(
            controller: _descController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Pothole Description',
              filled: true,
              fillColor: AppColors.darkBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'SUBMIT POTHOLE REPORT',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
            ),
          ),
        ],
      ),
    ),
  );
}
}
