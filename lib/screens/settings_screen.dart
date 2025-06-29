// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/permissions_manager.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Permissions'),
              subtitle: const Text('Manage app permissions'),
              onTap: () => _showPermissionsDialog(context),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.cleaning_services),
              title: const Text('Clear Cache'),
              subtitle: const Text('Clear app cache and data'),
              onTap: () => _clearCache(context),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Debug Info'),
              subtitle: const Text('View debug information'),
              onTap: () => _showDebugInfo(context),
            ),
          ),
        ],
      ),
    );
  }

  void _clearCache(BuildContext context) {
    final permissionsManager = context.read<PermissionsManager>();
    permissionsManager.clearCache();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cache cleared successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showDebugInfo(BuildContext context) {
    final permissionsManager = context.read<PermissionsManager>();
    final debugInfo = permissionsManager.getDebugSummary();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Information'),
        content: SingleChildScrollView(
          child: Text(
            debugInfo.entries
                .map((e) => '${e.key}: ${e.value}')
                .join('\n'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPermissionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permissions'),
        content: Consumer<PermissionsManager>(
          builder: (context, permissions, child) {
            if (permissions.isLoading) {
              return const CircularProgressIndicator();
            }
            
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(
                    permissions.canCreate ? Icons.check : Icons.close,
                    color: permissions.canCreate ? Colors.green : Colors.red,
                  ),
                  title: const Text('Create'),
                ),
                ListTile(
                  leading: Icon(
                    permissions.canEdit ? Icons.check : Icons.close,
                    color: permissions.canEdit ? Colors.green : Colors.red,
                  ),
                  title: const Text('Edit'),
                ),
                ListTile(
                  leading: Icon(
                    permissions.canDelete ? Icons.check : Icons.close,
                    color: permissions.canDelete ? Colors.green : Colors.red,
                  ),
                  title: const Text('Delete'),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}