import 'package:flutter_test/flutter_test.dart';
import 'package:rent_easy/data/property_repository.dart';
import 'package:rent_easy/models/property.dart';
import 'package:rent_easy/state/property_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

PropertyDraft _draft({
  String title = 'Test Listing',
  List<String> images = const ['/tmp/photo.jpg'],
}) {
  return PropertyDraft(
    title: title,
    category: PropertyCategory.apartments,
    neighborhood: 'Kefira',
    city: 'Dire Dawa',
    monthlyRent: 8500,
    bedrooms: 2,
    bathrooms: 1,
    description: 'A comfortable test apartment in Kefira, Dire Dawa.',
    ownerName: 'Test Owner',
    ownerPhone: '0912345678',
    imagePaths: images,
  );
}

Future<PropertyStore> _loadStore() async {
  final store = PropertyStore(repository: PropertyRepository());
  await store.load();
  return store;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('seeds demo listings on first run', () async {
    final store = await _loadStore();

    expect(store.properties.length, 4);
    expect(store.favoriteIds, contains('seed-2'));
    expect(store.myProperties, isEmpty);
  });

  test('adds a local property that is unverified and available', () async {
    final store = await _loadStore();
    final property = await store.addProperty(_draft());

    expect(property.ownerId, PropertyStore.localOwnerId);
    expect(property.verified, isFalse);
    expect(property.isRented, isFalse);
    expect(store.myProperties.length, 1);
    expect(store.properties.first.id, property.id);
  });

  test('persists listings between store instances', () async {
    final first = await _loadStore();
    final property = await first.addProperty(_draft(title: 'Persistent Home'));

    final second = await _loadStore();

    expect(second.properties.any((item) => item.id == property.id), isTrue);
    expect(second.myProperties.length, 1);
  });

  test('edits an existing local listing', () async {
    final store = await _loadStore();
    final property = await store.addProperty(_draft());

    final updated = await store.updateProperty(
      property.id,
      _draft(
        title: 'Updated Listing',
        images: const ['/tmp/new-photo.jpg', '/tmp/second.jpg'],
      ),
    );

    expect(updated, isNotNull);
    expect(updated!.title, 'Updated Listing');
    expect(updated.imagePaths.length, 2);
    expect(updated.verified, isFalse);
    expect(store.myProperties.single.title, 'Updated Listing');
  });

  test('marks a listing rented and available again', () async {
    final store = await _loadStore();
    final property = await store.addProperty(_draft());

    await store.setRented(property.id, isRented: true);
    expect(store.myProperties.single.isRented, isTrue);

    await store.setRented(property.id, isRented: false);
    expect(store.myProperties.single.isRented, isFalse);
  });

  test('toggles favourites and persists them', () async {
    final store = await _loadStore();
    final property = await store.addProperty(_draft());

    await store.toggleFavorite(property.id);
    expect(store.isFavorite(property.id), isTrue);

    final reloaded = await _loadStore();
    expect(reloaded.isFavorite(property.id), isTrue);

    await store.toggleFavorite(property.id);
    expect(store.isFavorite(property.id), isFalse);
  });

  test('deletes a local listing', () async {
    final store = await _loadStore();
    final property = await store.addProperty(_draft());

    await store.deleteProperty(property.id);

    expect(store.myProperties, isEmpty);
    expect(store.properties.any((item) => item.id == property.id), isFalse);
  });

  test('cannot edit or delete listings owned by someone else', () async {
    final store = await _loadStore();

    await expectLater(
      store.updateProperty('seed-1', _draft()),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      store.deleteProperty('seed-1'),
      throwsA(isA<StateError>()),
    );
  });
}
