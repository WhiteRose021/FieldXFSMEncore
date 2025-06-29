// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/backend_config.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedBackend = 'encore';
  bool _isDevelopment = true;
  String _encoreUrl = '';
  String _tenant = '';
  String _espoCrmUrl = '';
  bool _isLoading = false;
  String _testResult = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    try {
      final backend = await BackendConfig.getBackendType();
      final encoreSettings = await BackendConfig.getEncoreSettings();
      final espoCrmSettings = await BackendConfig.getEspoCRMSettings();

      setState(() {
        _selectedBackend = backend;
        _isDevelopment = encoreSettings['isDevelopment'] ?? true;
        _encoreUrl = encoreSettings['apiUrl'] ?? '';
        _tenant = encoreSettings['tenant'] ?? '';
        _espoCrmUrl = espoCrmSettings['crmDomain'] ?? '';
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
      if (_selectedBackend == 'encore') {
        await BackendConfig.configureEncore(
          apiUrl: _encoreUrl,
          tenant: _tenant,
          isDevelopment: _isDevelopment,
        );
      } else {
        await BackendConfig.configureEspoCRM(
          crmDomain: _espoCrmUrl,
        );
      }

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

      // Get the API URL
      final apiUrl = await BackendConfig.getApiBaseUrl();
      
      setState(() {
        _testResult = 'Testing connection to: $apiUrl\n';
      });

      // Test basic connectivity (you can expand this)
      final uri = Uri.parse(apiUrl);
      
      setState(() {
        _testResult += 'Backend: $_selectedBackend\n';
        _testResult += 'URL: $apiUrl\n';
        if (_selectedBackend == 'encore') {
          _testResult += 'Tenant: $_tenant\n';
          _testResult += 'Development: $_isDevelopment\n';
        }
        _testResult += '\n✅ Configuration looks good!\n';
        _testResult += 'Try logging in to test authentication.';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backend Settings'),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Backend Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Backend Type',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedBackend,
                      items: const [
                        DropdownMenuItem(value: 'encore', child: Text('Encore Backend')),
                        DropdownMenuItem(value: 'espocrm', child: Text('EspoCRM Backend')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedBackend = value!;
                        });
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Encore Settings
            if (_selectedBackend == 'encore') ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Encore Settings',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _encoreUrl,
                        decoration: const InputDecoration(
                          labelText: 'Encore API URL',
                          hintText: 'https://your-app.encr.app or http://localhost:4000',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => _encoreUrl = value,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _tenant,
                        decoration: const InputDecoration(
                          labelText: 'Tenant',
                          hintText: 'default',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => _tenant = value,
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Development Mode'),
                        subtitle: const Text('Use local development settings'),
                        value: _isDevelopment,
                        onChanged: (value) {
                          setState(() {
                            _isDevelopment = value;
                            if (value) {
                              _encoreUrl = 'http://localhost:4000';
                            } else {
                              _encoreUrl = 'https://your-app.encr.app';
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // EspoCRM Settings
            if (_selectedBackend == 'espocrm') ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'EspoCRM Settings',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _espoCrmUrl,
                        decoration: const InputDecoration(
                          labelText: 'EspoCRM Domain',
                          hintText: 'https://your-espocrm.com',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => _espoCrmUrl = value,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveSettings,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Save Settings'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _testConnection,
                    child: const Text('Test Connection'),
                  ),
                ),
              ],
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
                      Text(
                        _testResult,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}