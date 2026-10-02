import 'dart:async';
import 'package:flutter/material.dart';
import '../config/offline_ai_config.dart';
import '../models/local_model_status.dart';
import '../services/offline_ai_service.dart';

/// Non-blocking status / progress card displaying the offline AI background lifecycle.
///
/// Automatically tracks:
/// - Checking: "Offline AI • Checking"
/// - Downloading: "Offline AI • Downloading XX%" with background progress bar
/// - Verifying: "Offline AI • Verifying"
/// - Pending: "Offline AI • Download pending" (e.g. waiting for Wi-Fi or connection)
/// - Error: "Offline AI • Retry pending"
/// - Ready: "Offline AI • Ready"
///
/// Does NOT require user taps to start downloading. Does NOT block user navigation.
class OfflineSetupCard extends StatefulWidget {
  const OfflineSetupCard({super.key, this.onDismiss});
  final VoidCallback? onDismiss;

  @override
  State<OfflineSetupCard> createState() => _OfflineSetupCardState();
}

class _OfflineSetupCardState extends State<OfflineSetupCard> {
  late StreamSubscription<LocalModelStatus> _sub;
  LocalModelStatus _status = OfflineAiService.instance.modelStatus;
  double _progress = OfflineAiService.instance.downloadProgress;

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

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 MB';
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(0)} MB';
  }

  @override
  Widget build(BuildContext context) {
    // Hide card once fully ready or active in memory or in knowledge mode
    if (_status == LocalModelStatus.ready ||
        _status == LocalModelStatus.loaded ||
        _status == LocalModelStatus.generating ||
        _status == LocalModelStatus.lexiconOnly) {
      return const SizedBox.shrink();
    }

    const totalBytes = OfflineAiConfig.modelExpectedSizeBytes;
    final downloadedBytes = OfflineAiService.instance.downloadedBytes;
    final pct = (_progress * 100).toStringAsFixed(0);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _status == LocalModelStatus.downloading
                ? const Color(0xFF1A73E8).withValues(alpha: 0.3)
                : const Color(0xFFEEEEEE),
          ),
          color: Colors.white,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _status == LocalModelStatus.error
                        ? Colors.orange.withValues(alpha: 0.1)
                        : const Color(0xFF1A73E8).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _status == LocalModelStatus.error
                        ? Icons.sync_problem_rounded
                        : Icons.offline_bolt_rounded,
                    size: 20,
                    color: _status == LocalModelStatus.error
                        ? Colors.orange.shade800
                        : const Color(0xFF1A73E8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _headerTitle(pct),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF202124),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _subtitleText(totalBytes, downloadedBytes, pct),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.onDismiss != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: widget.onDismiss,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: Colors.grey.shade500,
                  ),
              ],
            ),

            // Progress Indicator / Controls
            if (_status == LocalModelStatus.downloading) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _progress > 0 ? _progress : null,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFE8F0FE),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1A73E8)),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_formatBytes(downloadedBytes)} / ${_formatBytes(totalBytes)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  GestureDetector(
                    onTap: OfflineAiService.instance.cancelDownload,
                    child: Text(
                      'Pause',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (_status == LocalModelStatus.verifying ||
                _status == LocalModelStatus.checking) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  minHeight: 4,
                  backgroundColor: Color(0xFFE8F0FE),
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A73E8)),
                ),
              ),
            ] else if (_status == LocalModelStatus.pending) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.wifi_rounded, size: 14, color: Colors.blue.shade700),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        OfflineAiService.instance.statusReason ??
                            'Download pending — will begin automatically',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_status == LocalModelStatus.error) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      OfflineAiService.instance.lastError ??
                          'Download paused. Retrying automatically...',
                      style: TextStyle(fontSize: 11, color: Colors.red.shade700),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: OfflineAiService.instance.startDownload,
                    icon: const Icon(Icons.refresh, size: 14),
                    label: const Text('Retry now', style: TextStyle(fontSize: 11)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _headerTitle(String pct) {
    switch (_status) {
      case LocalModelStatus.checking:
        return 'Offline AI • Checking';
      case LocalModelStatus.downloading:
        return 'Offline AI • Downloading $pct%';
      case LocalModelStatus.verifying:
        return 'Offline AI • Verifying';
      case LocalModelStatus.verified:
        return 'Offline AI • Verified';
      case LocalModelStatus.compatible:
        return 'Offline AI • Compatible';
      case LocalModelStatus.loadable:
        return 'Offline AI • Ready';
      case LocalModelStatus.ready:
        return 'Offline AI • Ready';
      case LocalModelStatus.loading:
        return 'Offline AI • Starting';
      case LocalModelStatus.loaded:
        return 'AI • Offline';
      case LocalModelStatus.generating:
        return 'Offline AI • Thinking';
      case LocalModelStatus.lexiconOnly:
        return 'Offline AI • Knowledge mode';
      case LocalModelStatus.pending:
        return 'Offline AI • Download pending';
      case LocalModelStatus.error:
        return 'Offline AI • Retry pending';
      case LocalModelStatus.unavailable:
        return 'Offline AI';
    }
  }

  String _subtitleText(int totalBytes, int downloadedBytes, String pct) {
    switch (_status) {
      case LocalModelStatus.checking:
        return 'Checking device capabilities in background...';
      case LocalModelStatus.downloading:
        return 'Preparing offline AI in background...';
      case LocalModelStatus.verifying:
        return 'Verifying model checksum and file integrity...';
      case LocalModelStatus.pending:
        return OfflineAiService.instance.statusReason ??
            'Waiting for network connection...';
      case LocalModelStatus.error:
        return OfflineAiService.instance.statusReason ??
            'Automatic retry scheduled.';
      default:
        return 'Background offline health assistant.';
    }
  }
}
