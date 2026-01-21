// lib/services/sync_service.dart

import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';
import 'local_database_service.dart';

class SyncService {
  static const String _syncQueueBoxName = 'syncQueue';
  final TransactionService _transactionService;
  final LocalDatabaseService _localDb;

  SyncService(this._transactionService, this._localDb);

  // Adds an action to the sync queue
  Future<void> queueAction(String actionType, Transaction? transaction, int? transactionId) async {
    final box = await Hive.openBox(_syncQueueBoxName);
    final action = {
      'type': actionType, // 'CREATE', 'UPDATE', 'DELETE'
      'payload': transaction?.toJson(), // Store the full transaction for CREATE/UPDATE
      'transactionId': transactionId, // Store ID for DELETE
      'timestamp': DateTime.now().toIso8601String(),
    };
    await box.add(action);
    print('Queued $actionType action for transaction ${transaction?.id ?? transactionId}');
  }

  // Attempts to sync all pending actions with the remote server
  Future<void> syncPendingActions() async {
    print('Starting sync process...');
    final box = await Hive.openBox(_syncQueueBoxName);
    if (box.isEmpty) {
      print('No actions to sync.');
      return;
    }

    final keysToDelete = <dynamic>[];
    for (final key in box.keys) {
      final action = box.get(key);
      if (action == null) continue;

      try {
        bool success = false;
        switch (action['type']) {
          case 'CREATE':
            final tx = Transaction.fromJson(action['payload']);
            final createdTx = await _transactionService.createTransaction(tx);
            // Update local transaction with the real ID from the server
            await _localDb.saveTransaction(createdTx);
            success = true;
            break;
          case 'UPDATE':
            final tx = Transaction.fromJson(action['payload']);
            await _transactionService.updateTransaction(tx);
            success = true;
            break;
          case 'DELETE':
            await _transactionService.deleteTransaction(action['transactionId']);
            success = true;
            break;
        }

        if (success) {
          keysToDelete.add(key); // Mark for deletion if sync was successful
          print('Successfully synced ${action['type']} action.');
        }
      } catch (e) {
        print('Failed to sync action ${action['type']}: $e');
        // We stop on the first error to maintain order, but you could also continue
        // and just mark the failed ones.
        break;
      }
    }

    // Remove successfully synced actions from the queue
    if (keysToDelete.isNotEmpty) {
      await box.deleteAll(keysToDelete);
      print('Removed ${keysToDelete.length} synced actions from the queue.');
    }
    print('Sync process finished.');
  }
}