import 'dart:async';
import 'package:flutter/material.dart';
import '../config/offline_ai_config.dart';
import '../models/local_model_status.dart';
import '../services/offline_ai_service.dart';

/// Non-blocking banner card shown when the offline model is not downloaded.
///
/// Shows:
/// - Description
/// - Verified model size (from config)
/// - Storage requirement
/// - Wi-Fi recommendation
/// - Download progress bar
/// - DOWNLOAD / LATER / CANCEL buttons
///
/// Does NOT block the user from using online GramHealth features.
class OfflineSetupCard extends StatefulWidget {
  const OfflineSetupCard({super.key, this.onDismiss});
  final VoidCallback? onDismiss;

  @override
  State<OfflineSetupCard> createState() => _OfflineSetupCardState();
}

class _OfflineSetupCardState extends State<OfflineSetupCard> {
  late StreamSubscription<LocalModelStatus> _sub;
  LocalModelStatus _status = OfflineAiService.instance.modelStatus;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _sub = OfflineAiService.instance.statusStream.listen((s) {
      if (!mounted) return;
      setState(() {
        _status = s;
        _progress = OfflineAiService.instance.downloadProgress;
      });
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Hide card once downloaded and ready
    if (_status == LocalModelStatus.ready ||
        _status == LocalModelStatus.loaded ||
        _status == LocalModelStatus.generating) {
      return const SizedBox.shrink();
    }

    final sizeMb =
        (OfflineAiConfig.modelExpectedSizeBytes / (1024 * 1024))
            .round();
    final storageMb = ((OfflineAiConfig.minFreeStorageBytes) / (1024 * 1024))
        .round();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.offline_bolt, color: Color(0xFF1A73E8)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Enable Offline AI',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (widget.onDismiss != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: widget.onDismiss,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Use GramHealth even when internet connectivity is unavailable. '
              'The offline assistant provides general health information — '
              'not medical diagnoses.',
            ),
            const SizedBox(height: 12),
            // Info chips
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _infoBadge(Icons.storage, 'Download: ~$sizeMb MB'),
                _infoBadge(Icons.sd_storage, 'Needs: ~$storageMb MB free'),
                _infoBadge(Icons.wifi, 'Wi-Fi recommended'),
              ],
            ),

            // Status-specific content
            if (_status == LocalModelStatus.downloading ||
                _status == LocalModelStatus.verifying) ..._downloadingUI()
            else if (_status == LocalModelStatus.loading)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(),
              )
            else if (_status == LocalModelStatus.error) ..._errorUI()
            else ..._idleButtons(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sub-widgets
  // ---------------------------------------------------------------------------

  Widget _infoBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade700,
              )),
        ],
      ),
    );
  }

  List<Widget> _downloadingUI() {
    final pct = (_progress * 100).toStringAsFixed(0);
    return [
      const SizedBox(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _status == LocalModelStatus.verifying
                ? 'Verifying…'
                : 'Downloading Offline AI… $pct%',
            style: const TextStyle(fontSize: 12),
          ),
          TextButton(
            onPressed: OfflineAiService.instance.cancelDownload,
            child: const Text('Cancel'),
          ),
        ],
      ),
      const SizedBox(height: 4),
      LinearProgressIndicator(
        value: _status == LocalModelStatus.verifying ? null : _progress,
        minHeight: 6,
        borderRadius: BorderRadius.circular(3),
      ),
    ];
  }

  List<Widget> _errorUI() {
    return [
      const SizedBox(height: 8),
      Text(
        OfflineAiService.instance.lastError ?? 'An error occurred.',
        style: const TextStyle(color: Colors.red, fontSize: 12),
      ),
      const SizedBox(height: 8),
      ElevatedButton.icon(
        onPressed: OfflineAiService.instance.startDownload,
        icon: const Icon(Icons.refresh),
        label: const Text('Retry'),
        style:
            ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
      ),
    ];
  }

  List<Widget> _idleButtons() {
    return [
      const SizedBox(height: 12),
      Row(
        children: [
          ElevatedButton(
            onPressed: OfflineAiService.instance.startDownload,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A73E8),
              foregroundColor: Colors.white,
            ),
            child: const Text('Download'),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: widget.onDismiss,
            child: const Text('Later'),
          ),
        ],
      ),
    ];
  }
}
