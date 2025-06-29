// lib/screens/autopsy_list_screen.dart - FIXED VERSION
// Updated imports and types to use AutopsyService

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/autopsy_repository.dart';
import '../services/permissions_manager.dart';
import '../services/autopsy_service.dart';  // FIXED: Updated import
import '../models/autopsy_models.dart';
import 'autopsies_screen.dart';

class AutopsyListScreen extends StatelessWidget {
  const AutopsyListScreen({super.key});

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
      child: const AutopsiesScreen(),
    );
  }
}

// Helper widget for backward compatibility
class AutopsyListItem extends StatelessWidget {
  final CAutopsy autopsy;
  final VoidCallback? onTap;

  const AutopsyListItem({
    super.key,
    required this.autopsy,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(autopsy.effectiveDisplayName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (autopsy.autopsyCustomerName?.isNotEmpty == true)
              Text('Customer: ${autopsy.autopsyCustomerName}'),
            if (autopsy.fullAddress.isNotEmpty)
              Text('Address: ${autopsy.fullAddress}'),
          ],
        ),
        trailing: autopsy.autopsyStatus != null
            ? Chip(
                label: Text(
                  AutopsyOptions.getStatusLabel(autopsy.autopsyStatus) ?? 
                  autopsy.autopsyStatus!,
                  style: const TextStyle(fontSize: 12),
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}