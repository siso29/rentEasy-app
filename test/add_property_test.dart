import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rent_easy/data/property_repository.dart';
import 'package:rent_easy/screens/add_property_screen.dart';
import 'package:rent_easy/state/property_store.dart';
import 'package:rent_easy/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<PropertyStore> _createStore() async {
  SharedPreferences.setMockInitialValues({});
  final store = PropertyStore(repository: PropertyRepository());
  await store.load();
  return store;
}

void main() {
  testWidgets('empty Add Property form is blocked by validation', (
    WidgetTester tester,
  ) async {
    final store = await _createStore();

    await tester.pumpWidget(
      ChangeNotifierProvider<PropertyStore>.value(
        value: store,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const AddPropertyScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('List a property'), findsOneWidget);
    expect(find.textContaining('Local mode'), findsOneWidget);

    final publishButton = find.widgetWithText(
      ElevatedButton,
      'Publish listing',
    );
    await tester.scrollUntilVisible(
      publishButton,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(publishButton);
    await tester.pumpAndSettle();

    expect(
      find.text('Please complete the highlighted fields.'),
      findsOneWidget,
    );
    expect(store.myProperties, isEmpty);
  });

  testWidgets('form cannot be submitted without a photo', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = await _createStore();

    await tester.pumpWidget(
      ChangeNotifierProvider<PropertyStore>.value(
        value: store,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const AddPropertyScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Listing title *'),
      'Spacious test house',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Neighborhood *'),
      'Sabian',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Monthly rent *'),
      '9000',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'About the property *'),
      'A bright and comfortable house close to shops and schools.',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Your name or agency *'),
      'Test Owner',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Phone number *'),
      '0912345678',
    );

    final publishButton = find.widgetWithText(
      ElevatedButton,
      'Publish listing',
    );
    await tester.scrollUntilVisible(
      publishButton,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(publishButton);
    await tester.pumpAndSettle();

    expect(
      find.text('Add at least one photo so renters can see the property.'),
      findsOneWidget,
    );
    expect(store.myProperties, isEmpty);
  });
}
