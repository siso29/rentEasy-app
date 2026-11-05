import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/property_repository.dart';
import '../models/property.dart';
import '../services/property_image_service.dart';

/// In-memory application state for listings and favourites.
///
/// Every mutation is persisted through [PropertyRepository]. The local
/// listing flag guarantees that data created here is clearly separated from
/// future server-backed listings.
class PropertyStore extends ChangeNotifier {
  PropertyStore({
    required PropertyRepository repository,
    PropertyImageService? imageService,
  }) : imageService = imageService ?? PropertyImageService() {
    _repository = repository;
  }

  /// Owner id used for listings created on this device.
  static const localOwnerId = 'local-user';

  late final PropertyRepository _repository;
  final PropertyImageService imageService;

  List<Property> _properties = const [];
  Set<String> _favoriteIds = <String>{};
  bool _isLoading = true;
  Object? _lastError;

  bool get isLoading => _isLoading;
  bool get isLocalMode => true;
  Object? get lastError => _lastError;

  List<Property> get properties => List.unmodifiable(_properties);

  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);

  List<Property> get favoriteProperties {
    return _properties
        .where((property) => _favoriteIds.contains(property.id))
        .toList();
  }

  /// Listings submitted from this device, newest first.
  List<Property> get myProperties {
    final mine =
        _properties
            .where((property) => property.ownerId == localOwnerId)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return mine;
  }

  bool isFavorite(String propertyId) {
    return _favoriteIds.contains(propertyId);
  }

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _repository.load();
      _properties = snapshot.properties;
      _favoriteIds = snapshot.favoriteIds;
      _lastError = null;
    } catch (error) {
      _lastError = error;
      _properties = const [];
      _favoriteIds = <String>{};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Property> addProperty(PropertyDraft draft) async {
    final property = Property(
      id: _generateId(),
      title: draft.title,
      category: draft.category,
      neighborhood: draft.neighborhood,
      city: draft.city,
      monthlyRent: draft.monthlyRent,
      bedrooms: draft.bedrooms,
      bathrooms: draft.bathrooms,
      description: draft.description,
      ownerId: localOwnerId,
      ownerName: draft.ownerName,
      ownerPhone: draft.ownerPhone,
      createdAt: DateTime.now(),
      imagePaths: List.unmodifiable(draft.imagePaths),
      verified: false,
    );

    _properties = [property, ..._properties];
    notifyListeners();
    await _persistProperties();
    return property;
  }

  Future<Property?> updateProperty(String id, PropertyDraft draft) async {
    final index = _properties.indexWhere((property) => property.id == id);
    if (index < 0) {
      return null;
    }

    final existing = _properties[index];
    if (existing.ownerId != localOwnerId) {
      throw StateError('You can only edit your own listings.');
    }

    final updated = existing.copyWith(
      title: draft.title,
      category: draft.category,
      neighborhood: draft.neighborhood,
      city: draft.city,
      monthlyRent: draft.monthlyRent,
      bedrooms: draft.bedrooms,
      bathrooms: draft.bathrooms,
      description: draft.description,
      ownerName: draft.ownerName,
      ownerPhone: draft.ownerPhone,
      imagePaths: List.unmodifiable(draft.imagePaths),
      // Verification is controlled by administrators, never by the owner.
      verified: existing.verified,
    );

    final updatedList = [..._properties];
    updatedList[index] = updated;
    _properties = updatedList;
    notifyListeners();
    await _persistProperties();
    return updated;
  }

  Future<void> deleteProperty(String id) async {
    final index = _properties.indexWhere((property) => property.id == id);
    if (index < 0) {
      return;
    }

    final property = _properties[index];
    if (property.ownerId != localOwnerId) {
      throw StateError('You can only delete your own listings.');
    }

    _properties = _properties.where((item) => item.id != id).toList();
    if (_favoriteIds.remove(id)) {
      unawaited(_persistFavorites());
    }
    notifyListeners();

    await _persistProperties();
    for (final imagePath in property.imagePaths) {
      await imageService.deleteIfManaged(imagePath);
    }
  }

  Future<void> setRented(String id, {required bool isRented}) async {
    final index = _properties.indexWhere((property) => property.id == id);
    if (index < 0) {
      return;
    }

    final property = _properties[index];
    if (property.ownerId != localOwnerId) {
      throw StateError('You can only manage your own listings.');
    }

    final updatedList = [..._properties];
    updatedList[index] = property.copyWith(isRented: isRented);
    _properties = updatedList;
    notifyListeners();
    await _persistProperties();
  }

  Future<void> toggleFavorite(String propertyId) async {
    if (!_properties.any((property) => property.id == propertyId)) {
      return;
    }

    if (_favoriteIds.contains(propertyId)) {
      _favoriteIds.remove(propertyId);
    } else {
      _favoriteIds.add(propertyId);
    }

    notifyListeners();
    await _persistFavorites();
  }

  Future<void> _persistProperties() async {
    try {
      await _repository.saveProperties(_properties);
      _lastError = null;
    } catch (error) {
      _lastError = error;
      debugPrint('Failed to save listings: $error');
    }
  }

  Future<void> _persistFavorites() async {
    try {
      await _repository.saveFavorites(_favoriteIds);
      _lastError = null;
    } catch (error) {
      _lastError = error;
      debugPrint('Failed to save favourites: $error');
    }
  }

  String _generateId() {
    return 'local-${DateTime.now().microsecondsSinceEpoch}';
  }
}
