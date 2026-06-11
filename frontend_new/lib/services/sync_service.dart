// lib/services/sync_service.dart

import 'package:hive/hive.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../services/transaction_service.dart';
import '../services/category_service.dart';
import 'local_database_service.dart';

class SyncService {
  static const String _syncQueueBoxName = 'syncQueue';
  final TransactionService _transactionService;
  final CategoryService _categoryService;
  final LocalDatabaseService _localDb;

  SyncService(
    this._transactionService,
    this._categoryService,
    this._localDb,
  );

  Future<void> queueTransactionAction(
    String actionType,
    Transaction? transaction,
    int? transactionId,
  ) async {
    await _queueAction(
      entity: 'transaction',
      actionType: actionType,
      payload: transaction?.toJson(),
      entityId: transactionId,
    );
  }

  Future<void> queueCategoryAction(
    String actionType,
    Category? category,
    int? categoryId,
  ) async {
    await _queueAction(
      entity: 'category',
      actionType: actionType,
      payload: category?.toJson(),
      entityId: categoryId,
    );
  }

  Future<void> _queueAction({
    required String entity,
    required String actionType,
    Map<String, dynamic>? payload,
    int? entityId,
  }) async {
    final box = await Hive.openBox(_syncQueueBoxName);
    await box.add({
      'entity': entity,
      'type': actionType,
      'payload': payload,
      'entityId': entityId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> replaceQueuedCategoryCreate(Category category) async {
    final box = await Hive.openBox(_syncQueueBoxName);
    for (final key in box.keys) {
      final action = box.get(key);
      if (action == null) continue;
      if (action['entity'] == 'category' &&
          action['type'] == 'CREATE' &&
          action['payload']?['id'] == category.id) {
        await box.put(key, {
          ...action,
          'payload': category.toJson(),
        });
        return;
      }
    }
  }

  Future<void> removeQueuedActionsForCategory(int categoryId) async {
    final box = await Hive.openBox(_syncQueueBoxName);
    final keysToDelete = <dynamic>[];

    for (final key in box.keys) {
      final action = box.get(key);
      if (action == null) continue;

      if (action['entity'] != 'category') continue;

      final payloadId = action['payload']?['id'];
      if (payloadId == categoryId || action['entityId'] == categoryId) {
        keysToDelete.add(key);
      }
    }

    if (keysToDelete.isNotEmpty) {
      await box.deleteAll(keysToDelete);
    }
  }

  Future<void> replaceQueuedCreate(Transaction transaction) async {
    final box = await Hive.openBox(_syncQueueBoxName);
    for (final key in box.keys) {
      final action = box.get(key);
      if (action == null) continue;
      if (action['entity'] == 'transaction' &&
          action['type'] == 'CREATE' &&
          action['payload']?['id'] == transaction.id) {
        await box.put(key, {
          ...action,
          'payload': transaction.toJson(),
        });
        return;
      }
    }
  }

  Future<void> removeQueuedActionsForTransaction(int transactionId) async {
    final box = await Hive.openBox(_syncQueueBoxName);
    final keysToDelete = <dynamic>[];

    for (final key in box.keys) {
      final action = box.get(key);
      if (action == null) continue;

      if (action['entity'] != 'transaction') continue;

      final payloadId = action['payload']?['id'];
      if (payloadId == transactionId || action['entityId'] == transactionId) {
        keysToDelete.add(key);
      }
    }

    if (keysToDelete.isNotEmpty) {
      await box.deleteAll(keysToDelete);
    }
  }

  Future<void> syncAll() async {
    await syncPendingActions();
  }

  Future<void> syncPendingActions() async {
    final box = await Hive.openBox(_syncQueueBoxName);
    if (box.isEmpty) return;

    final keysToDelete = <dynamic>[];
    for (final key in box.keys) {
      final action = box.get(key);
      if (action == null) continue;

      try {
        final success = await _processAction(action);
        if (success) {
          keysToDelete.add(key);
        } else {
          break;
        }
      } catch (_) {
        break;
      }
    }

    if (keysToDelete.isNotEmpty) {
      await box.deleteAll(keysToDelete);
    }
  }

  Future<bool> _processAction(Map action) async {
    final entity = action['entity'] as String? ?? 'transaction';

    if (entity == 'category') {
      return _processCategoryAction(action);
    }

    return _processTransactionAction(action);
  }

  Future<bool> _processTransactionAction(Map action) async {
    switch (action['type']) {
      case 'CREATE':
        final tx = Transaction.fromJson(
          Map<String, dynamic>.from(action['payload']),
        );
        final tempId = tx.id;
        final createdTx = await _transactionService.createTransaction(tx);
        if (tempId < 0) {
          await _localDb.deleteTransaction(tempId);
        }
        await _localDb.saveTransaction(createdTx);
        return true;
      case 'UPDATE':
        final tx = Transaction.fromJson(
          Map<String, dynamic>.from(action['payload']),
        );
        if (tx.id > 0) {
          final updatedTx = await _transactionService.updateTransaction(tx);
          await _localDb.saveTransaction(updatedTx);
          return true;
        }
        return false;
      case 'DELETE':
        final id = action['entityId'] as int;
        if (id > 0) {
          await _transactionService.deleteTransaction(id);
          return true;
        }
        return false;
      default:
        return false;
    }
  }

  Future<bool> _processCategoryAction(Map action) async {
    switch (action['type']) {
      case 'CREATE':
        final category = Category.fromJson(
          Map<String, dynamic>.from(action['payload']),
        );
        final tempId = category.id;
        final created = await _categoryService.createCategory(category);
        if (tempId < 0) {
          await _localDb.deleteCategory(tempId);
        }
        await _localDb.saveCategory(created);
        return true;
      case 'UPDATE':
        final category = Category.fromJson(
          Map<String, dynamic>.from(action['payload']),
        );
        if (category.id > 0) {
          final updated = await _categoryService.updateCategory(category);
          await _localDb.saveCategory(updated);
          return true;
        }
        return false;
      case 'DELETE':
        final id = action['entityId'] as int;
        if (id > 0) {
          await _categoryService.deleteCategory(id);
          return true;
        }
        return false;
      default:
        return false;
    }
  }

  // Backward-compatible alias used by transaction provider
  Future<void> queueAction(
    String actionType,
    Transaction? transaction,
    int? transactionId,
  ) =>
      queueTransactionAction(actionType, transaction, transactionId);
}
