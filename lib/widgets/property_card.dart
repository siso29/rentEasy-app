import 'package:flutter/material.dart';

import '../models/property.dart';
import '../utils/formatters.dart';
import '../theme/app_theme.dart';
import 'property_photo.dart';

/// Listing card used on Home and Saved screens.
class PropertyCard extends StatelessWidget {
  const PropertyCard({
    super.key,
    required this.property,
    required this.isSaved,
    required this.onTap,
    required this.onToggleSaved,
  });

  final Property property;
  final bool isSaved;
  final VoidCallback onTap;
  final VoidCallback onToggleSaved;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 17),
      color: Colors.white,
      elevation: 1,
      shadowColor: Colors.black12,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 165,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PropertyPhoto(property: property),
                  if (property.isRented)
                    Container(color: Colors.black.withValues(alpha: 0.28)),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Row(
                      children: [
                        _badge(
                          label: property.verified
                              ? '✓ Verified'
                              : 'New listing',
                          highlighted: property.verified,
                        ),
                        if (property.isRented) ...[
                          const SizedBox(width: 6),
                          _badge(
                            label: 'RENTED',
                            highlighted: false,
                            background: AppColors.primaryDark,
                            foreground: Colors.white,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Positioned(
                    top: 9,
                    right: 9,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        tooltip: isSaved
                            ? 'Remove from saved'
                            : 'Save property',
                        icon: Icon(
                          isSaved
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isSaved ? Colors.red : Colors.black87,
                          size: 21,
                        ),
                        onPressed: onToggleSaved,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 17,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          property.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _feature(Icons.bed_outlined, '${property.bedrooms} beds'),
                      const SizedBox(width: 16),
                      _feature(
                        Icons.bathtub_outlined,
                        '${property.bathrooms} baths',
                      ),
                      const Spacer(),
                      Text(
                        '${formatEtb(property.monthlyRent)} ETB',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'per month',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _feature(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _badge({
    required String label,
    required bool highlighted,
    Color background = Colors.white,
    Color foreground = AppColors.primaryDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: highlighted ? AppColors.primary : foreground,
        ),
      ),
    );
  }
}
