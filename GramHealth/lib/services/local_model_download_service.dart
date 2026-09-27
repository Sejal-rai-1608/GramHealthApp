import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';
import 'package:http/http.dart' as http;

import '../config/offline_ai_config.dart';

typedef ProgressCallback = void Function(int received, int total);

/// Manages downloading the LiteRT-LM model file with:
/// - HTTP range-request resumption
/// - Progress reporting
/// - Atomic rename (model.tmp → final)
/// - SHA-256 verification
class LocalModelDownloadService {
  LocalModelDownloadService();

  bool _cancelled = false;

  // ---------------------------------------------------------------------------
  // Main download
  // ---------------------------------------------------------------------------

  /// Download [url] to [destinationPath].
  ///
  /// - Uses HTTP Range requests to resume partial downloads.
  /// - Writes to a .tmp file and renames on completion.
  /// - Calls [onProgress] with (bytesReceived, totalBytes).
  Future<void> download({
    required String url,
    required String destinationPath,
    required int expectedSizeBytes,
    ProgressCallback? onProgress,
  }) async {
    _cancelled = false;
    final tmpPath = '$destinationPath.tmp';
    final tmpFile = File(tmpPath);

    int startByte = 0;
    if (await tmpFile.exists()) {
      startByte = await tmpFile.length();
      if (startByte >= expectedSizeBytes) {
        _log('Tmp file ($startByte bytes) >= expected ($expectedSizeBytes). Deleting stale tmp.');
        try {
          await tmpFile.delete();
        } catch (_) {}
        startByte = 0;
      } else {
        _log('Resuming from byte $startByte');
      }
    }

    int retries = 0;
    while (retries < OfflineAiConfig.maxDownloadRetries) {
      try {
        await _downloadRange(
          url: url,
          tmpFile: tmpFile,
          startByte: startByte,
          expectedTotal: expectedSizeBytes,
          onProgress: onProgress,
        );
        break; // success
      } on SocketException catch (e) {
        retries++;
        _log('Network error (attempt $retries): $e');
        if (retries >= OfflineAiConfig.maxDownloadRetries) rethrow;
        await Future<void>.delayed(Duration(seconds: 2 * retries));
        startByte = await tmpFile.exists() ? await tmpFile.length() : 0;
      } on HttpException catch (e) {
        retries++;
        _log('HTTP error (attempt $retries): $e');
        if (retries >= OfflineAiConfig.maxDownloadRetries) rethrow;
        await Future<void>.delayed(Duration(seconds: 2 * retries));
        startByte = await tmpFile.exists() ? await tmpFile.length() : 0;
      }
    }

    if (_cancelled) {
      throw const DownloadCancelledException();
    }

    // Atomic rename
    await tmpFile.rename(destinationPath);
    _log('Download complete → $destinationPath');
  }

  Future<void> _downloadRange({
    required String url,
    required File tmpFile,
    required int startByte,
    required int expectedTotal,
    ProgressCallback? onProgress,
  }) async {
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      if (startByte > 0) {
        request.headers['Range'] = 'bytes=$startByte-';
      }

      final response = await client
          .send(request)
          .timeout(OfflineAiConfig.downloadChunkTimeout);

      if (response.statusCode == 416) {
        // Range Not Satisfiable — partial file was invalid or exhausted
        _log('HTTP 416 Range Not Satisfiable. Resetting tmp file.');
        try {
          await tmpFile.delete();
        } catch (_) {}
        throw const DownloadHttpException('HTTP 416 Range Not Satisfiable');
      }

      if (response.statusCode != 200 && response.statusCode != 206) {
        throw DownloadHttpException(
          'HTTP ${response.statusCode} from $url',
        );
      }

      final isRange = response.statusCode == 206;
      final total = isRange
          ? (response.contentLength ?? 0) + startByte
          : (response.contentLength ?? expectedTotal);
      var received = isRange ? startByte : 0;

      final sink = tmpFile.openWrite(
        mode: isRange ? FileMode.append : FileMode.write,
      );

      try {
        await for (final chunk in response.stream) {
          if (_cancelled) {
            await sink.close();
            throw const DownloadCancelledException();
          }
          sink.add(chunk);
          received += chunk.length;
          onProgress?.call(received, total > 0 ? total : expectedTotal);
        }
      } finally {
        await sink.flush();
        await sink.close();
      }
    } finally {
      client.close();
    }
  }

  /// Returns current byte count of downloaded/in-progress model file.
  Future<int> getDownloadedBytes(String destinationPath) async {
    final tmpFile = File('$destinationPath.tmp');
    if (await tmpFile.exists()) {
      return await tmpFile.length();
    }
    final finalFile = File(destinationPath);
    if (await finalFile.exists()) {
      return await finalFile.length();
    }
    return 0;
  }

  // ---------------------------------------------------------------------------
  // Cancel
  // ---------------------------------------------------------------------------

  void cancel() {
    _cancelled = true;
    _log('Download cancelled.');
  }

  // ---------------------------------------------------------------------------
  // SHA-256
  // ---------------------------------------------------------------------------

  Future<String> computeSha256(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return '';

    final output = AccumulatorSink<Digest>();
    final input = sha256.startChunkedConversion(output);

    await for (final chunk in file.openRead()) {
      input.add(chunk);
    }
    input.close();
    return output.events.single.toString();
  }

  // ---------------------------------------------------------------------------
  // Cleanup
  // ---------------------------------------------------------------------------

  Future<void> deleteTmpFile(String destinationPath) async {
    final tmp = File('$destinationPath.tmp');
    if (await tmp.exists()) await tmp.delete();
  }

  void _log(String msg) {
    if (OfflineAiConfig.enableDiagnostics) {
      // ignore: avoid_print
      print('[LocalModelDownloadService] $msg');
    }
  }
}

class DownloadCancelledException implements Exception {
  const DownloadCancelledException();
  @override
  String toString() => 'DownloadCancelledException: download was cancelled.';
}

class DownloadHttpException implements Exception {
  const DownloadHttpException(this.message);
  final String message;
  @override
  String toString() => 'DownloadHttpException: $message';
}
