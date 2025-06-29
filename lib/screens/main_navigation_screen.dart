// lib/screens/main_navigation_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/autopsy_repository.dart';
import '../services/permissions_manager.dart';
import '../services/autopsy_client.dart';
import 'autopsies_screen.dart';

class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AutopsyClient>(
          create: (_) => AutopsyClient(baseUrl: 'https://your-api-url.com'),
        ),
        ChangeNotifierProvider<PermissionsManager>(
          create: (_) => PermissionsManager(),
        ),
        ChangeNotifierProxyProvider<AutopsyClient, AutopsyRepository>(
          create: (context) => AutopsyRepository(
            client: context.read<AutopsyClient>(),
          ),
          update: (context, client, previous) =>
              previous ?? AutopsyRepository(client: client),
        ),
      ],
      child: const AutopsiesScreen(),
    );
  }
}