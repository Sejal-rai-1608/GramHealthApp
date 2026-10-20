import 'package:flutter/material.dart';
import '../models/local_model_status.dart';
import '../services/offline_ai_service.dart';
import '../theme/app_colors.dart';

class OfflineStatusIndicator extends StatelessWidget {
  const OfflineStatusIndicator({
    super.key,
    required this.isOnline,
    this.compact = true,
  });

  final bool isOnline;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<LocalModelStatus>(
      stream: OfflineAiService.instance.statusStream,
      initialData: OfflineAiService.instance.modelStatus,
      builder: (context, snap) {
        final status = snap.data ?? LocalModelStatus.unavailable;
        return _buildChip(context, status);
      },
    );
  }

  Widget _buildChip(BuildContext context, LocalModelStatus status) {
    final (:label, :color, :icon) = _resolve(status);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall!.copyWith(color: color, fontWeight: FontWeight.w700)),
          if (status == LocalModelStatus.downloading) ..._progressPart(),
        ],
      ),
    );
  }

  List<Widget> _progressPart() {
    final pct = (OfflineAiService.instance.downloadProgress * 100).toStringAsFixed(0);
    return [
      const SizedBox(width: 4),
      Text('$pct%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
    ];
  }

  ({String label, Color color, IconData icon}) _resolve(LocalModelStatus status) {
    if (isOnline) {
      return (label: 'AI \u2022 Online', color: AppColors.teal, icon: Icons.cloud_done_outlined);
    }
    switch (status) {
      case LocalModelStatus.loaded:
      case LocalModelStatus.generating:
        return (label: 'AI \u2022 Offline', color: AppColors.amberDeep, icon: Icons.offline_bolt_outlined);
      case LocalModelStatus.lexiconOnly:
        return (label: 'AI \u2022 Offline (Knowledge)', color: AppColors.amberDeep, icon: Icons.menu_book_outlined);
      case LocalModelStatus.downloading:
        return (label: 'Offline AI \u2022 Downloading', color: AppColors.teal, icon: Icons.cloud_download_outlined);
      case LocalModelStatus.verifying:
        return (label: 'Offline AI \u2022 Verifying', color: AppColors.teal, icon: Icons.sync_rounded);
      case LocalModelStatus.verified:
      case LocalModelStatus.compatible:
      case LocalModelStatus.loadable:
      case LocalModelStatus.ready:
        return (label: 'Offline AI \u2022 Ready', color: AppColors.teal, icon: Icons.check_circle_outline);
      case LocalModelStatus.loading:
        return (label: 'Offline AI \u2022 Starting', color: AppColors.teal, icon: Icons.hourglass_top_rounded);
      case LocalModelStatus.error:
        return (label: 'Offline AI \u2022 Error', color: AppColors.emergency, icon: Icons.error_outline);
      default:
        return (label: 'AI \u2022 Offline', color: AppColors.inkFaint, icon: Icons.cloud_off_outlined);
    }
  }
}
