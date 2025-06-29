// lib/config/backend_config.dart
import 'package:shared_preferences/shared_preferences.dart';

class BackendConfig {
  // Encore Backend Configuration
  static const String encoreProductionUrl = 'https://applink.fieldx.gr/api/'; // Replace with your actual Encore app URL
  static const String encoreStagingUrl = 'https://applink.fieldx.gr/api/'; // Optional staging URL
  static const String encoreLocalUrl = 'http://localhost:4000'; // For local development
  
  // EspoCRM Backend Configuration  
  static const String espoCrmUrl = 'https://your-espocrm-domain.com'; // Replace with your EspoCRM URL
  
  // Default settings
  static const String defaultBackend = 'encore';
  static const String defaultTenant = 'default';
  static const bool defaultIsDevelopment = true; // Set to false for production

  /// Get the current backend type
  static Future<String> getBackendType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selectedBackend') ?? defaultBackend;
  }

  /// Set the backend type
  static Future<void> setBackendType(String backend) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedBackend', backend);
  }

  /// Get the API base URL based on current backend
  static Future<String> getApiBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final backend = await getBackendType();
    
    if (backend == 'encore') {
      final isDevelopment = prefs.getBool('isDevelopment') ?? defaultIsDevelopment;
      return isDevelopment ? encoreLocalUrl : encoreProductionUrl;
    } else {
      return prefs.getString('crmDomain') ?? espoCrmUrl;
    }
  }

  /// Configure Encore backend settings
  static Future<void> configureEncore({
    String? apiUrl,
    String? tenant,
    bool? isDevelopment,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (apiUrl != null) {
      await prefs.setString('encoreApiUrl', apiUrl);
    }
    
    if (tenant != null) {
      await prefs.setString('selectedTenant', tenant);
    }
    
    if (isDevelopment != null) {
      await prefs.setBool('isDevelopment', isDevelopment);
    }
    
    await setBackendType('encore');
  }

  /// Configure EspoCRM backend settings
  static Future<void> configureEspoCRM({
    String? crmDomain,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (crmDomain != null) {
      await prefs.setString('crmDomain', crmDomain);
    }
    
    await setBackendType('espocrm');
  }

  /// Get Encore-specific settings
  static Future<Map<String, dynamic>> getEncoreSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'apiUrl': prefs.getString('encoreApiUrl') ?? encoreProductionUrl,
      'tenant': prefs.getString('selectedTenant') ?? defaultTenant,
      'isDevelopment': prefs.getBool('isDevelopment') ?? defaultIsDevelopment,
    };
  }

  /// Get EspoCRM-specific settings
  static Future<Map<String, dynamic>> getEspoCRMSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'crmDomain': prefs.getString('crmDomain') ?? espoCrmUrl,
    };
  }

  /// Initialize default configuration
  static Future<void> initializeDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Set backend type if not set
    if (!prefs.containsKey('selectedBackend')) {
      await prefs.setString('selectedBackend', defaultBackend);
    }
    
    // Set Encore defaults if not set
    if (!prefs.containsKey('encoreApiUrl')) {
      await prefs.setString('encoreApiUrl', encoreProductionUrl);
    }
    
    if (!prefs.containsKey('selectedTenant')) {
      await prefs.setString('selectedTenant', defaultTenant);
    }
    
    if (!prefs.containsKey('isDevelopment')) {
      await prefs.setBool('isDevelopment', defaultIsDevelopment);
    }
    
    // Set EspoCRM defaults if not set
    if (!prefs.containsKey('crmDomain')) {
      await prefs.setString('crmDomain', espoCrmUrl);
    }
  }

  /// Get all current settings for debugging
  static Future<Map<String, dynamic>> getAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'selectedBackend': prefs.getString('selectedBackend'),
      'encoreApiUrl': prefs.getString('encoreApiUrl'),
      'selectedTenant': prefs.getString('selectedTenant'),
      'isDevelopment': prefs.getBool('isDevelopment'),
      'crmDomain': prefs.getString('crmDomain'),
    };
  }
}