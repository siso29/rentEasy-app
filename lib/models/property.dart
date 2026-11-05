/// Categories supported by the first release of RentEasy.
abstract final class PropertyCategory {
  static const houses = 'Houses';
  static const apartments = 'Apartments';
  static const rooms = 'Rooms';

  static const all = [houses, apartments, rooms];
}

/// A rental listing.
///
/// Listings created in the current build are stored locally on the device.
/// [verified] must stay `false` for locally-created listings until an
/// administrator verifies them through the future backend.
class Property {
  const Property({
    required this.id,
    required this.title,
    required this.category,
    required this.neighborhood,
    required this.city,
    required this.monthlyRent,
    required this.bedrooms,
    required this.bathrooms,
    required this.description,
    required this.ownerId,
    required this.ownerName,
    required this.ownerPhone,
    required this.createdAt,
    this.imagePaths = const [],
    this.verified = false,
    this.isRented = false,
  });

  final String id;
  final String title;
  final String category;
  final String neighborhood;
  final String city;
  final int monthlyRent;
  final int bedrooms;
  final int bathrooms;
  final String description;
  final String ownerId;
  final String ownerName;
  final String ownerPhone;
  final DateTime createdAt;
  final List<String> imagePaths;
  final bool verified;
  final bool isRented;

  String get location => '$neighborhood, $city';

  Property copyWith({
    String? title,
    String? category,
    String? neighborhood,
    String? city,
    int? monthlyRent,
    int? bedrooms,
    int? bathrooms,
    String? description,
    String? ownerId,
    String? ownerName,
    String? ownerPhone,
    DateTime? createdAt,
    List<String>? imagePaths,
    bool? verified,
    bool? isRented,
  }) {
    return Property(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      neighborhood: neighborhood ?? this.neighborhood,
      city: city ?? this.city,
      monthlyRent: monthlyRent ?? this.monthlyRent,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      createdAt: createdAt ?? this.createdAt,
      imagePaths: imagePaths ?? this.imagePaths,
      verified: verified ?? this.verified,
      isRented: isRented ?? this.isRented,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'neighborhood': neighborhood,
      'city': city,
      'monthlyRent': monthlyRent,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'description': description,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,
      'createdAt': createdAt.toIso8601String(),
      'imagePaths': imagePaths,
      'verified': verified,
      'isRented': isRented,
    };
  }

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      neighborhood: json['neighborhood'] as String,
      city: (json['city'] as String?) ?? 'Dire Dawa',
      monthlyRent: (json['monthlyRent'] as num).toInt(),
      bedrooms: (json['bedrooms'] as num?)?.toInt() ?? 1,
      bathrooms: (json['bathrooms'] as num?)?.toInt() ?? 1,
      description: (json['description'] as String?) ?? '',
      ownerId: (json['ownerId'] as String?) ?? 'unknown',
      ownerName: (json['ownerName'] as String?) ?? 'RentEasy user',
      ownerPhone: (json['ownerPhone'] as String?) ?? '',
      createdAt:
          DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
          DateTime.now(),
      imagePaths: (json['imagePaths'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(),
      verified: (json['verified'] as bool?) ?? false,
      isRented: (json['isRented'] as bool?) ?? false,
    );
  }
}

/// Values collected by the Add/Edit Property form.
class PropertyDraft {
  const PropertyDraft({
    required this.title,
    required this.category,
    required this.neighborhood,
    required this.city,
    required this.monthlyRent,
    required this.bedrooms,
    required this.bathrooms,
    required this.description,
    required this.ownerName,
    required this.ownerPhone,
    required this.imagePaths,
  });

  final String title;
  final String category;
  final String neighborhood;
  final String city;
  final int monthlyRent;
  final int bedrooms;
  final int bathrooms;
  final String description;
  final String ownerName;
  final String ownerPhone;
  final List<String> imagePaths;
}
