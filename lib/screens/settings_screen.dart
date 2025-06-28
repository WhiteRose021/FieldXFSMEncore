import 'package:fieldx_fsm/repositories/autopsy_repository.dart';
import 'package:fieldx_fsm/services/auth_service.dart';
import 'package:fieldx_fsm/services/permissions_manager.dart';
import 'package:fieldx_fsm/utils/error_handler.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 2,
      ),
      body: ListView(
        children: [
          // User info section
          Consumer<AuthService>(
            builder: (context, authService, child) {
              return Card(
                margin: const EdgeInsets.all(16),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: Text(authService.currentUsername ?? 'Unknown User'),
                  subtitle: Text('User ID: ${authService.currentUser ?? 'N/A'}'),
                ),
              );
            },
          ),
          
          
          const SizedBox(height: 16),
          
          // Actions section
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.refresh),
                  title: const Text('Refresh Permissions'),
                  onTap: () => _refreshPermissions(context),
                ),
                ListTile(
                  leading: const Icon(Icons.clear),
                  title: const Text('Clear Cache'),
                  onTap: () => _clearCache(context),
                ),
                ListTile(
                  leading: const Icon(Icons.bug_report),
                  title: const Text('Debug Info'),
                  onTap: () => _showDebugInfo(context),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Logout section
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () => _logout(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshPermissions(BuildContext context) async {
    try {
      final permissionsManager = context.read<PermissionsManager>();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissions refreshed')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ErrorHandler.showErrorSnackBar(context, error);
      }
    }
  }

  Future<void> _clearCache(BuildContext context) async {
    try {
      final repository = context.read<AutopsyRepository>();
      final permissionsManager = context.read<PermissionsManager>();
      
      repository.clearCaches();
      await permissionsManager.clearCache();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cache cleared')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ErrorHandler.showErrorSnackBar(context, error);
      }
    }
  }

  void _showDebugInfo(BuildContext context) {
    final repository = context.read<AutopsyRepository>();
    final permissionsManager = context.read<PermissionsManager>();
    
    final debugInfo = {
      'Repository Cache': repository.getCacheInfo(),
      'Permissions': permissionsManager.getDebugSummary(),
    };
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Information'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          child: SingleChildScrollView(
            child: Text(
              debugInfo.entries
                  .map((e) => '${e.key}:\n${e.value}\n')
                  .join('\n'),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
            ),
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

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    
    if (confirmed == true && context.mounted) {
      await context.read<AuthService>().logout();
    }
  }
}