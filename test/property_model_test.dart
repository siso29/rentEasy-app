import 'package:flutter_test/flutter_test.dart';
import 'package:rent_easy/models/property.dart';
import 'package:rent_easy/utils/formatters.dart';

void main() {
  group('Property', () {
    test('serialises and deserialises without losing data', () {
      final property = Property(
        id: 'local-1',
        title: 'Test House',
        category: PropertyCategory.houses,
        neighborhood: 'Sabian',
        city: 'Dire Dawa',
        monthlyRent: 12000,
        bedrooms: 3,
        bathrooms: 2,
        description: 'A test listing description for the unit tests.',
        ownerId: 'local-user',
        ownerName: 'Test Owner',
        ownerPhone: '0912345678',
        createdAt: DateTime(2026, 1, 2, 3, 4, 5),
        imagePaths: const ['/tmp/a.jpg', '/tmp/b.jpg'],
        verified: true,
        isRented: true,
      );

      final restored = Property.fromJson(property.toJson());

      expect(restored.id, property.id);
      expect(restored.title, property.title);
      expect(restored.location, 'Sabian, Dire Dawa');
      expect(restored.monthlyRent, property.monthlyRent);
      expect(restored.imagePaths, property.imagePaths);
      expect(restored.verified, isTrue);
      expect(restored.isRented, isTrue);
      expect(restored.createdAt, property.createdAt);
    });

    test('falls back safely when optional fields are missing', () {
      final restored = Property.fromJson({
        'id': 'x',
        'title': 'Minimal',
        'category': PropertyCategory.rooms,
        'neighborhood': 'Magala',
        'monthlyRent': 3000,
      });

      expect(restored.city, 'Dire Dawa');
      expect(restored.bedrooms, 1);
      expect(restored.bathrooms, 1);
      expect(restored.imagePaths, isEmpty);
      expect(restored.verified, isFalse);
      expect(restored.isRented, isFalse);
    });
  });

  group('formatEtb', () {
    test('groups thousands', () {
      expect(formatEtb(3500), '3,500');
      expect(formatEtb(12000), '12,000');
      expect(formatEtb(1234567), '1,234,567');
      expect(formatEtb(0), '0');
    });
  });

  group('validateEthiopianPhone', () {
    test('accepts local and international formats', () {
      expect(validateEthiopianPhone('0912345678'), isNull);
      expect(validateEthiopianPhone('0712345678'), isNull);
      expect(validateEthiopianPhone('+251912345678'), isNull);
      expect(validateEthiopianPhone('09 12 34 56 78'), isNull);
    });

    test('rejects invalid numbers', () {
      expect(validateEthiopianPhone(''), isNotNull);
      expect(validateEthiopianPhone('12345'), isNotNull);
      expect(validateEthiopianPhone('0212345678'), isNotNull);
    });
  });
}
