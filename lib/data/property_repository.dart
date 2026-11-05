import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/property.dart';

/// Result of loading local state from disk.
class PropertySnapshot {
  const PropertySnapshot({
    required this.properties,
    required this.favoriteIds,
    this.wasSeeded = false,
  });

  final List<Property> properties;
  final Set<String> favoriteIds;
  final bool wasSeeded;
}

/// Persists listings and favourites on the device.
///
/// This is intentionally a local-first implementation. The data is **not**
/// synced to a server and will not be visible to other users until the
/// Node.js/PostgreSQL backend is introduced in a later phase.
class PropertyRepository {
  PropertyRepository({SharedPreferences? preferences}) {
    _preferences = preferences;
  }

  static const propertiesKey = 'renteasy.properties.v1';
  static const favoritesKey = 'renteasy.favorites.v1';

  SharedPreferences? _preferences;

  Future<SharedPreferences> get _prefs async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  Future<PropertySnapshot> load() async {
    final prefs = await _prefs;
    final rawProperties = prefs.getString(propertiesKey);

    if (rawProperties == null) {
      final seed = _seedProperties();
      final favorites = <String>{'seed-2'};
      await _write(prefs, seed, favorites);
      return PropertySnapshot(
        properties: seed,
        favoriteIds: favorites,
        wasSeeded: true,
      );
    }

    try {
      final decoded = jsonDecode(rawProperties) as List<dynamic>;
      final properties = decoded
          .map((item) => Property.fromJson(item as Map<String, dynamic>))
          .toList();

      final favoriteIds = (prefs.getStringList(favoritesKey) ?? const [])
          .where((id) => properties.any((property) => property.id == id))
          .toSet();

      return PropertySnapshot(properties: properties, favoriteIds: favoriteIds);
    } catch (_) {
      // Corrupt or incompatible local data should never block startup.
      final seed = _seedProperties();
      final favorites = <String>{'seed-2'};
      await _write(prefs, seed, favorites);
      return PropertySnapshot(
        properties: seed,
        favoriteIds: favorites,
        wasSeeded: true,
      );
    }
  }

  Future<void> saveProperties(List<Property> properties) async {
    final prefs = await _prefs;
    await prefs.setString(
      propertiesKey,
      jsonEncode(properties.map((property) => property.toJson()).toList()),
    );
  }

  Future<void> saveFavorites(Set<String> favoriteIds) async {
    final prefs = await _prefs;
    await prefs.setStringList(favoritesKey, favoriteIds.toList());
  }

  Future<void> _write(
    SharedPreferences prefs,
    List<Property> properties,
    Set<String> favorites,
  ) async {
    await prefs.setString(
      propertiesKey,
      jsonEncode(properties.map((property) => property.toJson()).toList()),
    );
    await prefs.setStringList(favoritesKey, favorites.toList());
  }

  List<Property> _seedProperties() {
    final now = DateTime.now();

    return [
      Property(
        id: 'seed-1',
        title: 'Spacious Family House',
        category: PropertyCategory.houses,
        neighborhood: 'Sabian',
        city: 'Dire Dawa',
        monthlyRent: 12000,
        bedrooms: 3,
        bathrooms: 2,
        description:
            'A bright family home with a private compound, secure gate and '
            'enough space for a growing family. Close to schools and shops.',
        ownerId: 'demo-owner',
        ownerName: 'Sabian Homes',
        ownerPhone: '0911000001',
        createdAt: now.subtract(const Duration(days: 2)),
        verified: true,
      ),
      Property(
        id: 'seed-2',
        title: 'Modern Apartment',
        category: PropertyCategory.apartments,
        neighborhood: 'Kefira',
        city: 'Dire Dawa',
        monthlyRent: 8500,
        bedrooms: 2,
        bathrooms: 1,
        description:
            'Well finished two-bedroom apartment with a modern kitchen, '
            'tiled floors and reliable water supply. Suitable for couples.',
        ownerId: 'demo-owner',
        ownerName: 'Kefira Properties',
        ownerPhone: '0911000002',
        createdAt: now.subtract(const Duration(days: 4)),
        verified: true,
      ),
      Property(
        id: 'seed-3',
        title: 'Comfortable Single Room',
        category: PropertyCategory.rooms,
        neighborhood: 'Gende Kore',
        city: 'Dire Dawa',
        monthlyRent: 3500,
        bedrooms: 1,
        bathrooms: 1,
        description:
            'Affordable single room in a quiet neighbourhood. Includes a '
            'private bathroom and easy access to public transport.',
        ownerId: 'demo-owner',
        ownerName: 'Gende Kore Rentals',
        ownerPhone: '0911000003',
        createdAt: now.subtract(const Duration(days: 6)),
      ),
      Property(
        id: 'seed-4',
        title: 'Beautiful Two-Bedroom Home',
        category: PropertyCategory.houses,
        neighborhood: 'Magala',
        city: 'Dire Dawa',
        monthlyRent: 9000,
        bedrooms: 2,
        bathrooms: 1,
        description:
            'A cosy two-bedroom home with a small garden and parking space. '
            'Freshly painted and ready to move in.',
        ownerId: 'demo-owner',
        ownerName: 'Magala Real Estate',
        ownerPhone: '0911000004',
        createdAt: now.subtract(const Duration(days: 9)),
        verified: true,
      ),
    ];
  }
}
