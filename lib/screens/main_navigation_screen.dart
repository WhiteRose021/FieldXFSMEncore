// lib/screens/main_navigation_screen.dart - FIXED VERSION
// Updated import and types to use AutopsyService

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/autopsy_repository.dart';
import '../services/permissions_manager.dart';
import '../services/autopsy_service.dart';  // FIXED: Updated import
import '../models/autopsy_models.dart';
import 'autopsies_screen.dart';

class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // FIXED: Updated to use AutopsyService with no parameters
        Provider<AutopsyService>(
          create: (_) => AutopsyService(),
        ),
        ChangeNotifierProvider<PermissionsManager>(
          create: (_) => PermissionsManager(),
        ),
        // FIXED: Updated type references
        ChangeNotifierProxyProvider<AutopsyService, AutopsyRepository>(
          create: (context) => AutopsyRepository(
            client: context.read<AutopsyService>(),
          ),
          update: (context, client, previous) =>
              previous ?? AutopsyRepository(client: client),
        ),
      ],
      child: const Scaffold(
        body: AutopsiesScreen(),
      ),
    );
  }
}