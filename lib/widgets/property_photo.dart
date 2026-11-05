import 'dart:io';

import 'package:flutter/material.dart';

import '../models/property.dart';

IconData categoryIcon(String category) {
  return switch (category) {
    PropertyCategory.houses => Icons.home_work_rounded,
    PropertyCategory.apartments => Icons.apartment_rounded,
    PropertyCategory.rooms => Icons.bedroom_parent_rounded,
    _ => Icons.home_rounded,
  };
}

List<Color> categoryGradient(String category) {
  return switch (category) {
    PropertyCategory.houses => const [Color(0xFFDCEBE3), Color(0xFFC3DED0)],
    PropertyCategory.apartments => const [Color(0xFFE5E5F3), Color(0xFFD3D3EA)],
    PropertyCategory.rooms => const [Color(0xFFF4E7D9), Color(0xFFE9D5BF)],
    _ => const [Color(0xFFE7EEE9), Color(0xFFD5E2DA)],
  };
}

/// Displays a stored property photo or a branded placeholder.
class PropertyPhoto extends StatelessWidget {
  const PropertyPhoto({
    super.key,
    required this.property,
    this.index = 0,
    this.fit = BoxFit.cover,
    this.iconSize = 72,
  });

  final Property property;
  final int index;
  final BoxFit fit;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    if (property.imagePaths.isEmpty) {
      return PropertyPhotoPlaceholder(
        category: property.category,
        iconSize: iconSize,
      );
    }

    final safeIndex = index.clamp(0, property.imagePaths.length - 1);
    final file = File(property.imagePaths[safeIndex]);

    return Image.file(
      file,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        return PropertyPhotoPlaceholder(
          category: property.category,
          iconSize: iconSize,
        );
      },
    );
  }
}

/// Branded fallback shown while a listing has no photos.
class PropertyPhotoPlaceholder extends StatelessWidget {
  const PropertyPhotoPlaceholder({
    super.key,
    required this.category,
    this.iconSize = 72,
  });

  final String category;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final colors = categoryGradient(category);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          categoryIcon(category),
          size: iconSize,
          color: const Color(0xFF5C8071),
        ),
      ),
    );
  }
}
