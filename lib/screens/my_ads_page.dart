import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/property.dart';
import '../state/property_store.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';
import '../widgets/property_detail_sheet.dart';
import '../widgets/property_photo.dart';
import 'add_property_screen.dart';

/// Dashboard where landlords and agents manage their own listings.
class MyAdsPage extends StatelessWidget {
  const MyAdsPage({super.key});

  Future<void> _openForm(BuildContext context, {Property? property}) async {
    await Navigator.of(context).push<Property>(
      MaterialPageRoute(builder: (_) => AddPropertyScreen(property: property)),
    );
  }

  Future<void> _deleteProperty(BuildContext context, Property property) async {
    final store = context.read<PropertyStore>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete listing?'),
          content: Text(
            '"${property.title}" will be removed from this phone. '
            'This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await store.deleteProperty(property.id);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Listing deleted.')));
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete this listing.')),
      );
    }
  }

  Future<void> _toggleRented(BuildContext context, Property property) async {
    final store = context.read<PropertyStore>();
    final nextValue = !property.isRented;

    try {
      await store.setRented(property.id, isRented: nextValue);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextValue
                ? 'Listing marked as rented.'
                : 'Listing marked as available.',
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update this listing.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PropertyStore>();
    final listings = store.myProperties;
    final available = listings.where((item) => !item.isRented).length;
    final rented = listings.length - available;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        const Text(
          'My Ads',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Manage the rental properties you have listed.',
          style: TextStyle(color: AppColors.textMuted),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Available',
                value: '$available',
                icon: Icons.check_circle_outline_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                label: 'Rented',
                value: '$rented',
                icon: Icons.key_outlined,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _openForm(context),
            icon: const Icon(Icons.add_business_rounded),
            label: const Text('List a property'),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.phone_android_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Local mode: these listings are stored on this phone only. '
                  'Server sync and admin verification will be added with the backend.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (listings.isEmpty)
          EmptyState(
            icon: Icons.add_home_work_outlined,
            title: 'Your properties will appear here',
            message: 'List your rental property and connect with people looking for a home.',
            actionLabel: 'List a property',
            onAction: () => _openForm(context),
          )
        else ...[
          const Text(
            'Your listings',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 12),
          ...listings.map(
            (property) => _ManagedListingCard(
              property: property,
              onOpen: () => showPropertyDetails(context, property),
              onEdit: () => _openForm(context, property: property),
              onToggleRented: () => _toggleRented(context, property),
              onDelete: () => _deleteProperty(context, property),
            ),
          ),
        ],
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManagedListingCard extends StatelessWidget {
  const _ManagedListingCard({
    required this.property,
    required this.onOpen,
    required this.onEdit,
    required this.onToggleRented,
    required this.onDelete,
  });

  final Property property;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onToggleRented;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shadowColor: Colors.black12,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: SizedBox(
                  width: 92,
                  height: 100,
                  child: PropertyPhoto(property: property, iconSize: 34),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            property.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15.5,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 34,
                          height: 30,
                          child: PopupMenuButton<_ListingAction>(
                            tooltip: 'Manage listing',
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.more_vert_rounded, size: 20),
                            onSelected: (action) {
                              switch (action) {
                                case _ListingAction.edit:
                                  onEdit();
                                  break;
                                case _ListingAction.toggleRented:
                                  onToggleRented();
                                  break;
                                case _ListingAction.delete:
                                  onDelete();
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: _ListingAction.edit,
                                child: ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(Icons.edit_outlined),
                                  title: Text('Edit listing'),
                                ),
                              ),
                              PopupMenuItem(
                                value: _ListingAction.toggleRented,
                                child: ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(
                                    property.isRented
                                        ? Icons.check_circle_outline
                                        : Icons.key_outlined,
                                  ),
                                  title: Text(
                                    property.isRented
                                        ? 'Mark as available'
                                        : 'Mark as rented',
                                  ),
                                ),
                              ),
                              const PopupMenuItem(
                                value: _ListingAction.delete,
                                child: ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(
                                    Icons.delete_outline,
                                    color: AppColors.danger,
                                  ),
                                  title: Text(
                                    'Delete',
                                    style: TextStyle(color: AppColors.danger),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            property.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${formatEtb(property.monthlyRent)} ETB / month',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _statusPill(
                          property.isRented ? 'Rented' : 'Available',
                          active: !property.isRented,
                        ),
                        _statusPill(
                          property.verified
                              ? 'Verified'
                              : 'Pending verification',
                          active: property.verified,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusPill(String label, {required bool active}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: active ? AppColors.primarySoft : AppColors.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: active ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
    );
  }
}

enum _ListingAction { edit, toggleRented, delete }
