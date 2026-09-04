import 'dart:async';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../data/local_database.dart';
import 'connectivity_service.dart';
import 'api_client.dart';

enum SyncStatus { localOnly, pendingSync, syncing, synced, failed, conflict }

/// The centralized synchronization engine.
class SyncService {
  static final SyncService instance = SyncService._init();
  SyncService._init();

  bool _isSyncing = false;
  late StreamSubscription _networkSubscription;

  void initialize() {
    // Automatically attempt a sync whenever the network comes back online
    _networkSubscription = ConnectivityService.instance.statusStream.listen((status) {
      if (status == NetworkStatus.online || status == NetworkStatus.weak) {
        processQueue();
      }
    });

    // Run an initial check if we start the app online
    if (ConnectivityService.instance.currentStatus != NetworkStatus.offline) {
      processQueue();
    }
  }

  void dispose() {
    _networkSubscription.cancel();
  }

  /// Pushes a mutation to the backend or queues it if offline.
  Future<dynamic> push({
    required String entityType,
    required String operation,
    required String endpoint,
    required Map<String, dynamic> payload,
  }) async {
    final status = ConnectivityService.instance.currentStatus;

    if (status == NetworkStatus.offline) {
      // Offline: Enqueue the mutation.
      final uuid = const Uuid().v4();
      await LocalDatabase.instance.enqueueSync(
        id: uuid,
        entityType: entityType,
        operation: operation, // 'POST', 'PATCH', 'DELETE'
        endpoint: endpoint,
        payload: payload,
      );
      print('Offline: Queued $operation to $endpoint');
      return {'status': 'PENDING_SYNC', 'id': uuid};
    } else {
      // Online: Try exactly once. If it throws an exception (e.g. backend down), enqueue it.
      try {
        if (operation == 'POST') {
          return await ApiClient.post(endpoint, payload);
        } else if (operation == 'PATCH') {
          return await ApiClient.patch(endpoint, payload);
        } else if (operation == 'DELETE') {
          return await ApiClient.delete(endpoint);
        }
      } catch (e) {
        print('Network error during online push, fallback to queue. $e');
        final uuid = const Uuid().v4();
        await LocalDatabase.instance.enqueueSync(
          id: uuid,
          entityType: entityType,
          operation: operation,
          endpoint: endpoint,
          payload: payload,
        );
        return {'status': 'PENDING_SYNC', 'id': uuid, 'error': e.toString()};
      }
    }
  }

  /// Drains the SQLite sync queue.
  Future<void> processQueue() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final queue = await LocalDatabase.instance.getSyncQueue();
      
      for (var task in queue) {
        // Safety check to ensure we haven't dropped offline mid-sync
        if (ConnectivityService.instance.currentStatus == NetworkStatus.offline) break;

        final id = task['id'] as String;
        final operation = task['operation'] as String;
        final endpoint = task['endpoint'] as String;
        final payloadStr = task['payload'] as String;
        final payload = jsonDecode(payloadStr) as Map<String, dynamic>;
        final retryCount = (task['retry_count'] as int?) ?? 0;

        if (retryCount >= 5) {
          print('Task $id exceeded max retries. Keeping in queue for manual review.');
          continue;
        }

        try {
          print('SyncEngine: processing $operation for $id');
          if (operation == 'POST') {
            await ApiClient.post(endpoint, payload);
          } else if (operation == 'PATCH') {
            await ApiClient.patch(endpoint, payload);
          } else if (operation == 'DELETE') {
            await ApiClient.delete(endpoint); // ignoring payload for standard REST deletes
          }

          // Complete -> Remove from queue!
          await LocalDatabase.instance.removeSyncItem(id);
          print('SyncEngine: successfully synced $id');

        } catch (e) {
          // If we encounter a 409 Conflict, we don't blindly retry. 
          // (Can add a specific error checking logic here)
          final isConflict = e.toString().contains('409');
          if (isConflict) {
             print('SYNC CONFLICT DETECTED FOR $id. Halting retries on this item.');
             await LocalDatabase.instance.incrementRetry(id, 999); // max out
          } else {
             await LocalDatabase.instance.incrementRetry(id, retryCount);
          }
        }
      }
    } finally {
      _isSyncing = false;
    }
  }
}
