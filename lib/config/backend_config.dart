// lib/config/backend_config.dart
import 'package:shared_preferences/shared_preferences.dart';

/// Clean Encore-only backend configuration
class BackendConfig {
  // Encore Backend URLs for different environments
  static const String productionUrl = 'https://applink.fieldx.gr/api';
  static const String stagingUrl = 'https://staging.fieldx.gr/api'; // Optional staging
  static const String developmentUrl = 'http://localhost:4000'; // Local development
  
  // Default settings
  static const String defaultTenant = 'applink'; // Default tenant
  static const String defaultEnvironment = 'development';
  
  // Environment types
  static const String envDevelopment = 'development';
  static const String envStaging = 'staging';
  static const String envProduction = 'production';

  /// Get the current environment
  static Future<String> getEnvironment() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('environment') ?? defaultEnvironment;
  }

  /// Set the environment (development/staging/production)
  static Future<void> setEnvironment(String environment) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('environment', environment);
  }

  /// Get the API base URL based on current environment
  static Future<String> getApiBaseUrl() async {
    final environment = await getEnvironment();
    
    switch (environment) {
      case envProduction:
        return productionUrl;
      case envStaging:
        return stagingUrl;
      case envDevelopment:
      default:
        return developmentUrl;
    }
  }

  /// Get the current tenant
  static Future<String> getTenant() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selectedTenant') ?? defaultTenant;
  }

  /// Set the tenant for multi-tenant setups
  static Future<void> setTenant(String tenant) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedTenant', tenant);
  }

  /// Check if we're in development mode
  static Future<bool> isDevelopment() async {
    final environment = await getEnvironment();
    return environment == envDevelopment;
  }

  /// Configure for development environment
  static Future<void> configureDevelopment({String? tenant}) async {
    await setEnvironment(envDevelopment);
    if (tenant != null) {
      await setTenant(tenant);
    }
  }

  /// Configure for staging environment
  static Future<void> configureStaging({String? tenant}) async {
    await setEnvironment(envStaging);
    if (tenant != null) {
      await setTenant(tenant);
    }
  }

  /// Configure for production environment
  static Future<void> configureProduction({String? tenant}) async {
    await setEnvironment(envProduction);
    if (tenant != null) {
      await setTenant(tenant);
    }
  }

  /// Get all current settings
  static Future<Map<String, dynamic>> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final environment = await getEnvironment();
    final tenant = await getTenant();
    final apiUrl = await getApiBaseUrl();
    
    return {
      'environment': environment,
      'tenant': tenant,
      'apiBaseUrl': apiUrl,
      'isDevelopment': environment == envDevelopment,
      'isProduction': environment == envProduction,
      'isStaging': environment == envStaging,
    };
  }

  /// Initialize default configuration on first app launch
  static Future<void> initializeDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Set environment if not set
    if (!prefs.containsKey('environment')) {
      await prefs.setString('environment', defaultEnvironment);
    }
    
    // Set tenant if not set
    if (!prefs.containsKey('selectedTenant')) {
      await prefs.setString('selectedTenant', defaultTenant);
    }
    
    // Clean up old EspoCRM/backend switching keys
    await _cleanupOldKeys(prefs);
  }

  /// Clean up old SharedPreferences keys from the previous messy architecture
  static Future<void> _cleanupOldKeys(SharedPreferences prefs) async {
    final keysToRemove = [
      'selectedBackend',      // Old backend switching
      'crmDomain',           // EspoCRM URL
      'encoreApiUrl',        // Old Encore URL key
      'isDevelopment',       // Old boolean, now using environment string
    ];
    
    for (final key in keysToRemove) {
      if (prefs.containsKey(key)) {
        await prefs.remove(key);
      }
    }
  }

  /// Get auth headers with tenant information (for API calls)
  static Future<Map<String, String>> getDefaultHeaders() async {
    final tenant = await getTenant();
    
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (tenant.isNotEmpty) 'X-Tenant': tenant,
    };
  }

  /// Get API URL for a specific endpoint
  static Future<String> getEndpointUrl(String endpoint) async {
    final baseUrl = await getApiBaseUrl();
    // Remove leading slash from endpoint if present
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    return '$baseUrl/$cleanEndpoint';
  }

  /// Get debug information for troubleshooting
  static Future<Map<String, dynamic>> getDebugInfo() async {
    final settings = await getSettings();
    final headers = await getDefaultHeaders();
    
    return {
      'settings': settings,
      'defaultHeaders': headers,
      'availableEnvironments': [envDevelopment, envStaging, envProduction],
      'urlMapping': {
        envDevelopment: developmentUrl,
        envStaging: stagingUrl,
        envProduction: productionUrl,
      },
    };
  }

  /// Validate current configuration
  static Future<bool> validateConfiguration() async {
    try {
      final environment = await getEnvironment();
      final tenant = await getTenant();
      final apiUrl = await getApiBaseUrl();
      
      // Check if environment is valid
      if (![envDevelopment, envStaging, envProduction].contains(environment)) {
        return false;
      }
      
      // Check if tenant is not empty
      if (tenant.isEmpty) {
        return false;
      }
      
      // Check if API URL is valid
      if (apiUrl.isEmpty || !Uri.tryParse(apiUrl)!.isAbsolute) {
        return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }
}