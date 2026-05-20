import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'screens/sign_in_screen.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'state/catalog_model.dart';
import 'state/collection_model.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Startup. Open Hive, restore any signed-in session, ensure the demo
  // account exists so the archive opens to a populated collection, bind
  // the collection model to auth state, then load the bundled catalog and
  // drop-alert data. All of this completes before the first frame so the
  // UI never has to show a loading spinner.
  final storage = StorageService();
  await storage.init();

  final auth = AuthService();
  await auth.init();
  await auth.ensureDemoUser(
    name: 'Alex',
    email: 'alex@sneakerbro.local',
    password: 'archive',
  );

  final collection = CollectionModel(storage, auth);
  await collection.bind();

  final catalog = CatalogModel();
  await catalog.init();

  runApp(SneakerBroApp(
    auth: auth,
    collection: collection,
    catalog: catalog,
  ));
}

class SneakerBroApp extends StatelessWidget {
  const SneakerBroApp({
    super.key,
    required this.auth,
    required this.collection,
    required this.catalog,
  });

  final AuthService auth;
  final CollectionModel collection;
  final CatalogModel catalog;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: auth),
        ChangeNotifierProvider<CollectionModel>.value(value: collection),
        ChangeNotifierProvider<CatalogModel>.value(value: catalog),
      ],
      child: MaterialApp(
        title: 'SneakerBro',
        debugShowCheckedModeBanner: false,
        theme: buildSneakerBroTheme(),
        home: const _AuthGate(),
      ),
    );
  }
}

/// Routes between the sign-in screen and the main app based on auth state.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    if (auth.isSignedIn) return const HomeScreen();
    return const SignInScreen();
  }
}
