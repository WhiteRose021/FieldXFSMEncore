// lib/screens/enhanced_settings_screen.dart
import 'package:fieldx_fsm/services/enhanced_unified_crm_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/enhanced_service_adapters.dart';

class EnhancedSettingsScreen extends StatefulWidget {
  const EnhancedSettingsScreen({super.key});

  @override
  _EnhancedSettingsScreenState createState() => _EnhancedSettingsScreenState();
}

class _EnhancedSettingsScreenState extends State<EnhancedSettingsScreen> {
  final TextEditingController crmUrlController = TextEditingController();
  
  // Backend selection
  BackendType _selectedBackend = BackendType.espocrm;
  String? _selectedTenant;
  bool _isDevelopment = true;
  
  // Connection status
  bool _isTestingConnection = false;
  String? _connectionStatus;
  
  // Available tenants for Encore
  final List<Map<String, String>> _availableTenants = [
    {'code': 'applink', 'name': 'AppLink', 'port': '4001'},
    {'code': 'beyond', 'name': 'Beyond', 'port': '4002'},
    {'code': 'demo', 'name': 'Demo', 'port': '4003'},
    {'code': 'test', 'name': 'Test', 'port': '4004'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// Load all stored settings
  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    setState(() {
      // Load EspoCRM URL (your existing logic)
      crmUrlController.text = prefs.getString('crmDomain') ?? "";
      
      // Load backend preferences
      _selectedBackend = BackendType.values.firstWhere(
        (type) => type.name == prefs.getString('selectedBackend'),
        orElse: () => BackendType.espocrm,
      );
      
      _selectedTenant = prefs.getString('selectedTenant');
      _isDevelopment = prefs.getBool('isDevelopment') ?? true;
    });
  }

  /// Save all settings
  Future<void> _saveSettings() async {
    if (_selectedBackend == BackendType.espocrm) {
      String url = crmUrlController.text.trim();
      if (url.isEmpty) {
        _showSnackBar("CRM URL cannot be empty!", Colors.red);
        return;
      }
    } else if (_selectedBackend == BackendType.encore) {
      if (_selectedTenant == null) {
        _showSnackBar("Please select a tenant for Encore backend!", Colors.red);
        return;
      }
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Save EspoCRM URL (your existing logic)
    if (_selectedBackend == BackendType.espocrm) {
      await prefs.setString('crmDomain', crmUrlController.text.trim());
    }
    
    // Save backend preferences
    await prefs.setString('selectedBackend', _selectedBackend.name);
    if (_selectedTenant != null) {
      await prefs.setString('selectedTenant', _selectedTenant!);
    }
    await prefs.setBool('isDevelopment', _isDevelopment);

    // Initialize the backend
    await _initializeBackend();
    
    _showSnackBar("Settings saved successfully!", Colors.green);
    Navigator.pop(context);
  }

  /// Initialize the selected backend
  Future<void> _initializeBackend() async {
    try {
      await BackendManager.initializeApp(
        backendType: _selectedBackend,
        tenantCode: _selectedTenant,
        isDevelopment: _isDevelopment,
      );
      
      setState(() {
        _connectionStatus = "✅ Backend initialized successfully";
      });
    } catch (e) {
      setState(() {
        _connectionStatus = "❌ Failed to initialize backend: $e";
      });
    }
  }

  /// Test connection to selected backend
  Future<void> _testConnection() async {
    setState(() {
      _isTestingConnection = true;
      _connectionStatus = "🔄 Testing connection...";
    });

    try {
      if (_selectedBackend == BackendType.espocrm) {
        await _testEspoCRMConnection();
      } else {
        await _testEncoreConnection();
      }
    } catch (e) {
      setState(() {
        _connectionStatus = "❌ Connection failed: $e";
      });
    } finally {
      setState(() {
        _isTestingConnection = false;
      });
    }
  }

  /// Test EspoCRM connection
  Future<void> _testEspoCRMConnection() async {
    String url = crmUrlController.text.trim();
    if (url.isEmpty) {
      throw Exception("CRM URL is required");
    }

    // Temporarily save URL and test
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('crmDomain', url);
    
    await BackendManager.initializeApp(backendType: BackendType.espocrm);
    bool isConnected = await BackendManager.testConnectivity();
    
    setState(() {
      _connectionStatus = isConnected 
        ? "✅ EspoCRM connection successful" 
        : "❌ EspoCRM connection failed";
    });
  }

  /// Test Encore connection
  Future<void> _testEncoreConnection() async {
    if (_selectedTenant == null) {
      throw Exception("Tenant selection is required");
    }

    await BackendManager.initializeApp(
      backendType: BackendType.encore,
      tenantCode: _selectedTenant,
      isDevelopment: _isDevelopment,
    );
    
    bool isConnected = await BackendManager.testConnectivity();
    
    setState(() {
      _connectionStatus = isConnected 
        ? "✅ Encore connection successful" 
        : "❌ Encore connection failed";
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Backend Settings"),
        backgroundColor: Color(0xFF0066CC),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Backend Status
            _buildCurrentBackendCard(),
            
            const SizedBox(height: 20),
            
            // Backend Selection
            _buildBackendSelectionCard(),
            
            const SizedBox(height: 20),
            
            // EspoCRM Configuration (conditional)
            if (_selectedBackend == BackendType.espocrm)
              _buildEspoCRMConfigCard(),
            
            // Encore Configuration (conditional)
            if (_selectedBackend == BackendType.encore)
              _buildEncoreConfigCard(),
            
            const SizedBox(height: 20),
            
            // Connection Test
            _buildConnectionTestCard(),
            
            const SizedBox(height: 30),
            
            // Save Button
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentBackendCard() {
    final currentBackend = BackendManager.getCurrentBackend();
    final isEncore = BackendManager.isUsingEncore();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isEncore ? Icons.cloud : Icons.storage,
                  color: isEncore ? Colors.blue : Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  "Current Backend",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              currentBackend.name.toUpperCase(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: isEncore ? Colors.blue : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_connectionStatus != null) ...[
              const SizedBox(height: 8),
              Text(_connectionStatus!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBackendSelectionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Select Backend",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // EspoCRM Option
            RadioListTile<BackendType>(
              title: Row(
                children: [
                  Icon(Icons.storage, color: Colors.green),
                  const SizedBox(width: 8),
                  const Text("EspoCRM Backend"),
                ],
              ),
              subtitle: const Text("Original EspoCRM API (192.168.4.20:6969)"),
              value: BackendType.espocrm,
              groupValue: _selectedBackend,
              onChanged: (value) {
                setState(() {
                  _selectedBackend = value!;
                  _connectionStatus = null;
                });
              },
            ),
            
            // Encore Option
            RadioListTile<BackendType>(
              title: Row(
                children: [
                  Icon(Icons.cloud, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text("Encore Backend"),
                ],
              ),
              subtitle: const Text("High-performance TypeScript backend"),
              value: BackendType.encore,
              groupValue: _selectedBackend,
              onChanged: (value) {
                setState(() {
                  _selectedBackend = value!;
                  _connectionStatus = null;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEspoCRMConfigCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storage, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  "EspoCRM Configuration",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: crmUrlController,
              decoration: const InputDecoration(
                labelText: "Base URL",
                hintText: "http://192.168.4.20:6969",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEncoreConfigCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  "Encore Configuration",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Environment Selection
            Row(
              children: [
                const Text("Environment: "),
                Switch(
                  value: _isDevelopment,
                  onChanged: (value) {
                    setState(() {
                      _isDevelopment = value;
                      _connectionStatus = null;
                    });
                  },
                ),
                Text(_isDevelopment ? "Development" : "Production"),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Tenant Selection
            const Text("Select Tenant:"),
            const SizedBox(height: 8),
            
            ...(_availableTenants.map((tenant) => RadioListTile<String>(
              title: Text(tenant['name']!),
              subtitle: Text(
                _isDevelopment 
                  ? "localhost:${tenant['port']}" 
                  : "Production endpoint"
              ),
              value: tenant['code']!,
              groupValue: _selectedTenant,
              onChanged: (value) {
                setState(() {
                  _selectedTenant = value;
                  _connectionStatus = null;
                });
              },
            ))),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionTestCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Connection Test",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isTestingConnection ? null : _testConnection,
                icon: _isTestingConnection 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.wifi_find),
                label: Text(_isTestingConnection ? "Testing..." : "Test Connection"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            
            if (_connectionStatus != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _connectionStatus!.startsWith("✅") 
                    ? Colors.green.withOpacity(0.1)
                    : _connectionStatus!.startsWith("❌")
                    ? Colors.red.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _connectionStatus!.startsWith("✅") 
                      ? Colors.green
                      : _connectionStatus!.startsWith("❌")
                      ? Colors.red
                      : Colors.orange,
                  ),
                ),
                child: Text(_connectionStatus!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveSettings,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        child: const Text(
          "Save Settings",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}