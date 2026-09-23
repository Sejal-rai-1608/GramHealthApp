import 'package:flutter/material.dart';
import '../models/local_model_status.dart';
import '../services/offline_ai_service.dart';

/// Compact inline status chip displayed in the AI chat app bar.
///
/// Shows:
///   Online:       "AI • Online"         (green chip)
///   Offline:      "AI • Offline"         (amber chip)
///   Downloading:  "Offline AI • 42%"     (blue progress chip)
///   Loading:      "Offline AI • Starting" (blue chip)
///   Error:        "Offline AI • Error"    (red chip)
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
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          if (status == LocalModelStatus.downloading) ..._progressPart(),
        ],
      ),
    );
  }

  List<Widget> _progressPart() {
    final pct =
        (OfflineAiService.instance.downloadProgress * 100)
            .toStringAsFixed(0);
    return [
      const SizedBox(width: 4),
      Text(
        '$pct%',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      ),
    ];
  }

  ({
    String label,
    Color color,
    IconData icon,
  }) _resolve(LocalModelStatus status) {
    if (isOnline) {
      return (
        label: 'AI \u2022 Online',
        color: Colors.green,
        icon: Icons.cloud_done_outlined,
      );
    }
    switch (status) {
      case LocalModelStatus.loaded:
      case LocalModelStatus.generating:
        return (
          label: 'AI \u2022 Offline',
          color: Colors.amber.shade700,
          icon: Icons.offline_bolt_outlined,
        );
      case LocalModelStatus.downloading:
        return (
          label: 'Offline AI \u2022 Downloading',
          color: Colors.blue,
          icon: Icons.cloud_download_outlined,
        );
      case LocalModelStatus.loading:
        return (
          label: 'Offline AI \u2022 Starting',
          color: Colors.blue,
          icon: Icons.hourglass_top_rounded,
        );
      case LocalModelStatus.error:
        return (
          label: 'Offline AI \u2022 Error',
          color: Colors.red,
          icon: Icons.error_outline,
        );
      default:
        return (
          label: 'AI \u2022 Offline',
          color: Colors.grey,
          icon: Icons.cloud_off_outlined,
        );
    }
  }
}
