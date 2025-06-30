// lib/app/app.dart - FIXED VERSION
// Compatible with AutopsyService and AutopsyRepository

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/autopsy_service.dart';
import '../services/permissions_manager.dart';
import '../repositories/autopsy_repository.dart';
import 'routes.dart';

class FieldFSMApp extends StatelessWidget {
  const FieldFSMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // FIXED: Use AutopsyService instead of AutopsyClient
        Provider<AutopsyService>(
          create: (_) => AutopsyService(),
        ),
        ChangeNotifierProvider<PermissionsManager>(
          create: (_) => PermissionsManager(),
        ),
        // FIXED: Updated to use AutopsyService
        ChangeNotifierProxyProvider<AutopsyService, AutopsyRepository>(
          create: (context) => AutopsyRepository(
            client: context.read<AutopsyService>(),
          ),
          update: (context, autopsyService, previous) =>
              previous ?? AutopsyRepository(client: autopsyService),
        ),
      ],
      child: MaterialApp(
        title: 'FieldFSM',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          useMaterial3: true,
        ),
        initialRoute: AppRoutes.login,
        routes: AppRoutes.getRoutes(),
        onGenerateRoute: AppRoutes.generateRoute,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}