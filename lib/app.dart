import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_shell.dart';
import 'state/property_store.dart';
import 'theme/app_theme.dart';

class RentEasyApp extends StatelessWidget {
  const RentEasyApp({super.key, required this.store});

  final PropertyStore store;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PropertyStore>.value(
      value: store,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'RentEasy',
        theme: AppTheme.light,
        home: const HomeShell(),
      ),
    );
  }
}
