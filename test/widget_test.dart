import 'package:flutter_test/flutter_test.dart';
import 'package:rent_easy/app.dart';
import 'package:rent_easy/data/property_repository.dart';
import 'package:rent_easy/state/property_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<PropertyStore> _createStore() async {
  SharedPreferences.setMockInitialValues({});
  final store = PropertyStore(repository: PropertyRepository());
  await store.load();
  return store;
}

void main() {
  testWidgets('RentEasy home screen displays correctly', (
    WidgetTester tester,
  ) async {
    final store = await _createStore();

    await tester.pumpWidget(RentEasyApp(store: store));
    await tester.pumpAndSettle();

    expect(find.text('RentEasy'), findsOneWidget);
    expect(find.text('Find a place that'), findsOneWidget);
    expect(find.text('Property categories'), findsOneWidget);
    expect(find.text('Featured properties'), findsOneWidget);
    expect(find.text('Spacious Family House'), findsOneWidget);
  });

  testWidgets('bottom navigation opens the My Ads dashboard', (
    WidgetTester tester,
  ) async {
    final store = await _createStore();

    await tester.pumpWidget(RentEasyApp(store: store));
    await tester.pumpAndSettle();

    await tester.tap(find.text('My Ads'));
    await tester.pumpAndSettle();

    expect(find.text('My Ads'), findsWidgets);
    expect(find.text('List a property'), findsWidgets);
    expect(find.textContaining('Local mode'), findsOneWidget);
  });
}
