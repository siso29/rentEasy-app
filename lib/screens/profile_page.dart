import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/property_store.dart';
import '../theme/app_theme.dart';

/// Placeholder profile screen. Authentication arrives in Phase 3.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PropertyStore>();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'My profile',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: 25),
        const CircleAvatar(
          radius: 42,
          backgroundColor: AppColors.primarySoft,
          child: Icon(Icons.person_rounded, size: 45, color: AppColors.primary),
        ),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            'Welcome to RentEasy',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            '${store.myProperties.length} local listing(s)',
            style: const TextStyle(color: AppColors.textMuted),
          ),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 19,
                color: AppColors.primary,
              ),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'You are browsing in local mode. Sign-in, profiles and '
                  'role-based dashboards will be added in Phase 3.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _profileOption(context, Icons.person_outline, 'Account information'),
        _profileOption(
          context,
          Icons.home_work_outlined,
          'My property listings',
        ),
        _profileOption(context, Icons.settings_outlined, 'Settings'),
        _profileOption(context, Icons.help_outline, 'Help and support'),
      ],
    );
  }

  Widget _profileOption(BuildContext context, IconData icon, String title) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => _showMessage(
          context,
          '$title will be implemented in a later phase.',
        ),
      ),
    );
  }
}
