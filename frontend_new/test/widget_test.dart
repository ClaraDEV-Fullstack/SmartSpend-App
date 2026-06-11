import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_new/main.dart';
import 'package:frontend_new/services/locale_service.dart';
import 'package:frontend_new/local/category_entity.dart';
import 'package:frontend_new/local/transaction_entity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Hive.initFlutter();
    Hive.registerAdapter(CategoryEntityAdapter());
    Hive.registerAdapter(TransactionEntityAdapter());
    await Hive.openBox<CategoryEntity>('categories');
    await Hive.openBox<TransactionEntity>('transactions');
    await Hive.openBox('syncQueue');
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
