import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/property.dart';
import '../state/property_store.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'property_photo.dart';

/// Opens the property detail bottom sheet.
void showPropertyDetails(BuildContext context, Property property) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PropertyDetailSheet(property: property),
  );
}

class _PropertyDetailSheet extends StatelessWidget {
  const _PropertyDetailSheet({required this.property});

  final Property property;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PropertyStore>();
    final current = store.properties.firstWhere(
      (item) => item.id == property.id,
      orElse: () => property,
    );
    final isSaved = store.isFavorite(current.id);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _Gallery(
                property: current,
                isSaved: isSaved,
                onToggleSaved: () => store.toggleFavorite(current.id),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _statusChip(
                    current.verified
                        ? '✓ Verified listing'
                        : 'Pending verification',
                    active: current.verified,
                  ),
                  if (current.isRented) _statusChip('Rented', active: false),
                  _statusChip(current.category, active: false),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                current.title,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      current.location,
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                  Text(
                    timeAgo(current.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                '${formatEtb(current.monthlyRent)} ETB / month',
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _stat(
                      Icons.bed_outlined,
                      '${current.bedrooms}',
                      'Bedrooms',
                    ),
                    _stat(
                      Icons.bathtub_outlined,
                      '${current.bathrooms}',
                      'Bathrooms',
                    ),
                    _stat(
                      categoryIcon(current.category),
                      current.category,
                      'Type',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'About this property',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                current.description.isEmpty
                    ? 'The owner has not added a description yet.'
                    : current.description,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Listed by',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 23,
                      backgroundColor: AppColors.primarySoft,
                      child: Text(
                        current.ownerName.trim().isEmpty
                            ? 'R'
                            : current.ownerName.trim()[0].toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            current.ownerName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            current.ownerPhone.isEmpty
                                ? 'Contact details available soon'
                                : current.ownerPhone,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (current.ownerId == PropertyStore.localOwnerId)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Your listing',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: current.isRented
                    ? null
                    : () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Viewing requests will be available in a later phase.',
                            ),
                          ),
                        );
                      },
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text(
                  current.isRented ? 'Currently rented' : 'Request a viewing',
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'RentEasy does not ask for advance payments before a viewing. '
                'Report suspicious listings to the administration team.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statusChip(String label, {required bool active}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: active ? AppColors.primarySoft : AppColors.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: active ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _stat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 21, color: AppColors.primary),
        const SizedBox(height: 5),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _Gallery extends StatefulWidget {
  const _Gallery({
    required this.property,
    required this.isSaved,
    required this.onToggleSaved,
  });

  final Property property;
  final bool isSaved;
  final VoidCallback onToggleSaved;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final imageCount = widget.property.imagePaths.length;

    return SizedBox(
      height: 230,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageCount == 0)
              PropertyPhoto(property: widget.property)
            else
              PageView.builder(
                itemCount: imageCount,
                onPageChanged: (page) => setState(() => _page = page),
                itemBuilder: (context, index) {
                  return PropertyPhoto(property: widget.property, index: index);
                },
              ),
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  tooltip: widget.isSaved
                      ? 'Remove from saved'
                      : 'Save property',
                  onPressed: widget.onToggleSaved,
                  icon: Icon(
                    widget.isSaved
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: widget.isSaved ? Colors.red : Colors.black87,
                    size: 21,
                  ),
                ),
              ),
            ),
            if (imageCount > 1)
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(imageCount, (index) {
                    final selected = index == _page;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: selected ? 18 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: selected ? Colors.white : Colors.white70,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
