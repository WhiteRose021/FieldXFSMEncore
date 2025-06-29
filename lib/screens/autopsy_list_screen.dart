// lib/screens/autopsy_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/autopsy_repository.dart';
import '../services/permissions_manager.dart';
import '../services/autopsy_client.dart';
import '../models/autopsy_models.dart';
import 'autopsies_screen.dart';

class AutopsyListScreen extends StatelessWidget {
  const AutopsyListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AutopsyClient>(
          create: (_) => AutopsyClient(baseUrl: 'https://applink.fieldx.gr/api'),
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
            if (autopsy.autopsycustomername?.isNotEmpty == true)
              Text('Customer: ${autopsy.autopsycustomername}'),
            if (autopsy.fullAddress.isNotEmpty)
              Text('Address: ${autopsy.fullAddress}'),
          ],
        ),
        trailing: autopsy.autopsystatus != null
            ? Chip(
                label: Text(
                  AutopsyOptions.getStatusLabel(autopsy.autopsystatus) ?? 
                  autopsy.autopsystatus!,
                  style: const TextStyle(fontSize: 12),
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}