import 'package:hive_flutter/hive_flutter.dart';
import '../local/transaction_entity.dart';
import '../local/category_entity.dart';
import '../models/transaction.dart' as app_model;
import '../models/category.dart' as app_model;

class LocalDatabaseService {
  static const String _transactionsBoxName = 'transactions';
  static const String _categoriesBoxName = 'categories';

  // --- CATEGORY OPERATIONS ---
  Future<List<app_model.Category>> getAllCategories() async {
    final box = await Hive.openBox<CategoryEntity>(_categoriesBoxName);
    return box.values.map((entity) => _mapCategoryEntityToModel(entity)).toList();
  }

  Future<void> saveAllCategories(List<app_model.Category> categories) async {
    final box = await Hive.openBox<CategoryEntity>(_categoriesBoxName);
    await box.clear();
    final categoryEntities = categories.map((model) => _mapCategoryModelToEntity(model)).toList();
    await box.putAll({for (var entity in categoryEntities) entity.id: entity});
  }

  // --- TRANSACTION OPERATIONS ---
  Future<List<app_model.Transaction>> getAllTransactions() async {
    final transactionBox = await Hive.openBox<TransactionEntity>(_transactionsBoxName);
    final categoryBox = await Hive.openBox<CategoryEntity>(_categoriesBoxName);

    // Fetch all categories once and create a map for quick lookup
    final categoryMap = {for (var cat in categoryBox.values) cat.id: cat};

    final transactions = transactionBox.values.map((tEntity) {
      final categoryEntity = categoryMap[tEntity.categoryId];

      app_model.Category categoryModel;

      // ✅ FIX STARTS HERE
      if (categoryEntity == null) {
        // Instead of throwing Exception, create a placeholder "Unknown" category
        // This prevents the app from crashing when data is out of sync
        categoryModel = app_model.Category(
          id: tEntity.categoryId, // Keep the ID so we know what's missing
          name: 'Unknown Category',
          icon: 'help_outline',   // Generic question mark icon
          color: '#9E9E9E',       // Grey color
          type: 'expense',
        );
      } else {
        categoryModel = _mapCategoryEntityToModel(categoryEntity);
      }
      // ✅ FIX ENDS HERE

      return _mapTransactionEntityToModel(tEntity, categoryModel);
    }).toList();

    return transactions;
  }

  Future<void> saveAllTransactions(List<app_model.Transaction> transactions) async {
    final box = await Hive.openBox<TransactionEntity>(_transactionsBoxName);
    await box.clear();
    final transactionEntities = transactions.map((model) => _mapTransactionModelToEntity(model)).toList();
    await box.putAll({for (var entity in transactionEntities) entity.id: entity});
  }

  Future<void> saveTransaction(app_model.Transaction transaction) async {
    final box = await Hive.openBox<TransactionEntity>(_transactionsBoxName);
    final entity = _mapTransactionModelToEntity(transaction);
    await box.put(transaction.id, entity);
  }

  Future<void> deleteTransaction(int transactionId) async {
    final box = await Hive.openBox<TransactionEntity>(_transactionsBoxName);
    await box.delete(transactionId);
  }

  // --- MAPPERS ---

  app_model.Category _mapCategoryEntityToModel(CategoryEntity entity) {
    return app_model.Category(
      id: entity.id,
      name: entity.name,
      icon: entity.icon,
      color: entity.color,
      type: entity.type,
    );
  }

  CategoryEntity _mapCategoryModelToEntity(app_model.Category model) {
    return CategoryEntity(
      id: model.id,
      name: model.name,
      icon: model.icon,
      color: model.color,
      type: model.type,
    );
  }

  app_model.Transaction _mapTransactionEntityToModel(TransactionEntity entity, app_model.Category category) {
    return app_model.Transaction(
      id: entity.id,
      type: entity.type,
      amount: entity.amount,
      description: entity.description,
      date: entity.date,
      category: category,
      currency: entity.currency,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  TransactionEntity _mapTransactionModelToEntity(app_model.Transaction model) {
    return TransactionEntity(
      id: model.id,
      type: model.type,
      amount: model.amount,
      description: model.description,
      date: model.date,
      categoryId: model.category.id,
      currency: model.currency,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }
}