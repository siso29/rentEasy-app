import 'package:flutter/material.dart';

import 'app.dart';
import 'data/property_repository.dart';
import 'state/property_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final store = PropertyStore(repository: PropertyRepository());
  await store.load();

  runApp(RentEasyApp(store: store));
}
