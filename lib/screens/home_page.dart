import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/property.dart';
import '../state/property_store.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/property_card.dart';
import '../widgets/property_detail_sheet.dart';

/// Property discovery screen.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'All';
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  List<Property> _filteredProperties(PropertyStore store) {
    final query = _searchQuery.trim().toLowerCase();

    return store.properties.where((property) {
      final matchesCategory =
          _selectedCategory == 'All' || property.category == _selectedCategory;

      final matchesSearch =
          query.isEmpty ||
          property.title.toLowerCase().contains(query) ||
          property.location.toLowerCase().contains(query) ||
          property.neighborhood.toLowerCase().contains(query) ||
          property.category.toLowerCase().contains(query);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PropertyStore>();
    final properties = _filteredProperties(store);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.home_work_rounded,
                color: Colors.white,
                size: 25,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'RentEasy',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Notifications',
              onPressed: () => _showMessage(
                'Notifications will be available in a later phase.',
              ),
              icon: const Icon(Icons.notifications_none_rounded),
            ),
          ],
        ),
        const SizedBox(height: 22),
        const Row(
          children: [
            Icon(Icons.location_on_rounded, color: AppColors.primary, size: 19),
            SizedBox(width: 5),
            Text(
              'Dire Dawa, Ethiopia',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Find a place that',
          style: TextStyle(
            fontSize: 29,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
        const Text(
          'feels like home.',
          style: TextStyle(
            fontSize: 29,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() => _searchQuery = value);
          },
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search location or property...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: IconButton(
              tooltip: 'Clear search',
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              icon: const Icon(Icons.close_rounded),
            ),
          ),
        ),
        const SizedBox(height: 25),
        const Text(
          'Property categories',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: 13),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['All', ...PropertyCategory.all].map((category) {
              final selected = _selectedCategory == category;

              return Padding(
                padding: const EdgeInsets.only(right: 9),
                child: ChoiceChip(
                  label: Text(category),
                  selected: selected,
                  showCheckmark: false,
                  onSelected: (_) {
                    setState(() => _selectedCategory = category);
                  },
                  selectedColor: AppColors.primary,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide(
                    color: selected ? AppColors.primary : AppColors.border,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 25),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Featured properties',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
            Text(
              '${properties.length} found',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        if (properties.isEmpty)
          const EmptyState(
            icon: Icons.search_off_rounded,
            title: 'No properties found',
            message: 'Try another search or choose a different category.',
          )
        else
          ...properties.map(
            (property) => PropertyCard(
              property: property,
              isSaved: store.isFavorite(property.id),
              onTap: () => showPropertyDetails(context, property),
              onToggleSaved: () => store.toggleFavorite(property.id),
            ),
          ),
      ],
    );
  }
}
