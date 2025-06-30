// lib/screens/autopsy_list_screen.dart - FIXED VERSION
// Updated imports and types to use AutopsyService

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/autopsy_repository.dart';
import '../services/permissions_manager.dart';
import '../services/autopsy_service.dart';  // FIXED: Updated import
import '../models/autopsy_models.dart';
import 'autopsies_screen.dart';
import '../widgets/debug_test_widget.dart';

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
    Key? key,
    required this.autopsy,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final createdAt = autopsy.createdAt;
    final formattedDate = createdAt != null
        ? '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}'
        : '—';

    return InkWell(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: SR + Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SR: ${autopsy.effectiveDisplayName}',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (autopsy.autopsyStatus != null)
                    Chip(
                      label: Text(
                        AutopsyOptions.getStatusLabel(autopsy.autopsyStatus!) ?? autopsy.autopsyStatus!,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Colors.grey[100],
                      side: BorderSide(color: Colors.grey.shade400),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // Customer Name
              if (autopsy.autopsyCustomerName?.isNotEmpty == true)
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        autopsy.autopsyCustomerName!,
                        style: theme.textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

              // Address
              if (autopsy.fullAddress.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        autopsy.fullAddress,
                        style: theme.textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              // Created At
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    formattedDate,
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
