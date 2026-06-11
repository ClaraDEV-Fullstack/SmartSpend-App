import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_new/main.dart';
import 'package:frontend_new/services/locale_service.dart';
import 'package:frontend_new/local/category_entity.dart';
import 'package:frontend_new/local/transaction_entity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('smartspend_test');
    Hive.init(tempDir.path);
    Hive.registerAdapter(CategoryEntityAdapter());
    Hive.registerAdapter(TransactionEntityAdapter());
    await Hive.openBox<CategoryEntity>('categories');
    await Hive.openBox<TransactionEntity>('transactions');
    await Hive.openBox('syncQueue');
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('SmartSpend app loads splash screen', (WidgetTester tester) async {
    final localeService = LocaleService();
    await localeService.initialize();

    await tester.pumpWidget(MyApp(localeService: localeService));
    await tester.pump();

    expect(find.text('SmartSpend'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
