// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/backend_config.dart';
import '../services/auth_service.dart';
import '../services/permissions_manager.dart';
import '../repositories/autopsy_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedEnvironment = 'development';
  String _tenant = '';
  bool _isLoading = false;
  String _testResult = '';
  Map<String, dynamic> _currentSettings = {};
  Map<String, dynamic> _debugInfo = {};

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    try {
      final environment = await BackendConfig.getEnvironment();
      final tenant = await BackendConfig.getTenant();
      final settings = await BackendConfig.getSettings();
      final debugInfo = await BackendConfig.getDebugInfo();

      setState(() {
        _selectedEnvironment = environment;
        _tenant = tenant;
        _currentSettings = settings;
        _debugInfo = debugInfo;
      });
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
      _testResult = '';
    });

    try {
      // Configure based on selected environment
      switch (_selectedEnvironment) {
        case 'production':
          await BackendConfig.configureProduction(tenant: _tenant);
          break;
        case 'staging':
          await BackendConfig.configureStaging(tenant: _tenant);
          break;
        case 'development':
        default:
          await BackendConfig.configureDevelopment(tenant: _tenant);
          break;
      }

      // Reload settings to reflect changes
      await _loadCurrentSettings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Testing connection...';
    });

    try {
      // First save the current settings
      await _saveSettings();

      // Validate configuration
      final isValid = await BackendConfig.validateConfiguration();
      final apiUrl = await BackendConfig.getApiBaseUrl();
      final headers = await BackendConfig.getDefaultHeaders();
      
      setState(() {
        _testResult = 'Connection Test Results:\n\n';
        _testResult += 'Environment: $_selectedEnvironment\n';
        _testResult += 'API URL: $apiUrl\n';
        _testResult += 'Tenant: $_tenant\n';
        _testResult += 'Configuration Valid: ${isValid ? "✅ Yes" : "❌ No"}\n\n';
        
        if (isValid) {
          _testResult += 'Headers:\n';
          headers.forEach((key, value) {
            _testResult += '  $key: $value\n';
          });
          _testResult += '\n✅ Configuration looks good!\n';
          _testResult += 'Try logging in to test authentication.';
        } else {
          _testResult += '❌ Configuration validation failed.\n';
          _testResult += 'Please check your settings.';
        }
      });

    } catch (e) {
      setState(() {
        _testResult = '❌ Connection test failed: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _clearCache() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Clear permissions cache
      final permissionsManager = context.read<PermissionsManager>();
      permissionsManager.clearCache();

      // Clear autopsy repository cache
      final autopsyRepository = context.read<AutopsyRepository>();
      autopsyRepository.clearCaches();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cache cleared successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing cache: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FieldX Settings'),
        backgroundColor: _getEnvironmentColor(),
        foregroundColor: Colors.white,
        actions: [
          Consumer<AuthService>(
            builder: (context, authService, child) {
              if (authService.isAuthenticated) {
                return IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await authService.logout();
                    if (mounted) {
                      Navigator.of(context).pushReplacementNamed('/login');
                    }
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current User Info
            Consumer<AuthService>(
              builder: (context, authService, child) {
                if (authService.isAuthenticated) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current User',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text('User: ${authService.currentUser ?? "Unknown"}'),
                          Text('Type: ${authService.userType ?? "Unknown"}'),
                          if (authService.tenantName?.isNotEmpty == true)
                            Text('Tenant: ${authService.tenantName}'),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 16),

            // Environment Settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Environment Configuration',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedEnvironment,
                      items: const [
                        DropdownMenuItem(value: 'development', child: Text('Development (Local)')),
                        DropdownMenuItem(value: 'staging', child: Text('Staging')),
                        DropdownMenuItem(value: 'production', child: Text('Production')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedEnvironment = value!;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Environment',
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(
                          Icons.cloud,
                          color: _getEnvironmentColor(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: _tenant,
                      decoration: const InputDecoration(
                        labelText: 'Tenant',
                        hintText: 'applink, beyond, etc.',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                      ),
                      onChanged: (value) => _tenant = value,
                    ),
                    const SizedBox(height: 16),
                    
                    // Current Settings Display
                    if (_currentSettings.isNotEmpty) ...[
                      const Divider(),
                      const Text(
                        'Current Settings:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('API URL: ${_currentSettings['apiBaseUrl'] ?? "Not set"}'),
                      Text('Environment: ${_currentSettings['environment'] ?? "Not set"}'),
                      Text('Tenant: ${_currentSettings['tenant'] ?? "Not set"}'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveSettings,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: const Text('Save Settings'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getEnvironmentColor(),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _testConnection,
                    icon: const Icon(Icons.wifi_tethering),
                    label: const Text('Test Connection'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Cache Management
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _clearCache,
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear Cache'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                ),
              ),
            ),

            // Test Results
            if (_testResult.isNotEmpty) ...[
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Test Results',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _testResult,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Debug Information (Expandable)
            if (_debugInfo.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: ExpansionTile(
                  title: const Text(
                    'Debug Information',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  leading: const Icon(Icons.bug_report),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _debugInfo.toString(),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Get color based on environment
  Color _getEnvironmentColor() {
    switch (_selectedEnvironment) {
      case 'production':
        return Colors.green;
      case 'staging':
        return Colors.orange;
      case 'development':
      default:
        return Colors.blue;
    }
  }
}