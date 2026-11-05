import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/property_store.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/property_card.dart';
import '../widgets/property_detail_sheet.dart';

/// Favourites saved on this device.
class SavedPage extends StatelessWidget {
  const SavedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PropertyStore>();
    final saved = store.favoriteProperties;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Saved properties',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Properties you have added to your favorites.',
          style: TextStyle(color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),
        if (saved.isEmpty)
          const EmptyState(
            icon: Icons.favorite_border_rounded,
            title: 'No saved properties yet',
            message: 'Tap the heart on any listing to keep it here for later.',
          )
        else
          ...saved.map(
            (property) => PropertyCard(
              property: property,
              isSaved: true,
              onTap: () => showPropertyDetails(context, property),
              onToggleSaved: () => store.toggleFavorite(property.id),
            ),
          ),
      ],
    );
  }
}
