// lib/config/backend_config.dart
import 'package:shared_preferences/shared_preferences.dart';

/// Clean Encore-only backend configuration
class BackendConfig {
  // Encore Backend URLs for different environments
  static const String productionUrl = 'https://applink.fieldx.gr/api';
  static const String stagingUrl = 'https://staging.fieldx.gr/api'; // Optional staging
  static const String developmentUrl = 'http://localhost:4001'; // Updated to 4001 for AppLink
  
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
    
    // Log the change for debugging
    print('🔄 BackendConfig: Environment updated to $environment');
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
    
    // Log the change for debugging
    print('🔄 BackendConfig: Tenant updated to $tenant');
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
    print('✅ BackendConfig: Configured for development environment');
  }

  /// Configure for staging environment
  static Future<void> configureStaging({String? tenant}) async {
    await setEnvironment(envStaging);
    if (tenant != null) {
      await setTenant(tenant);
    }
    print('✅ BackendConfig: Configured for staging environment');
  }

  /// Configure for production environment
  static Future<void> configureProduction({String? tenant}) async {
    await setEnvironment(envProduction);
    if (tenant != null) {
      await setTenant(tenant);
    }
    print('✅ BackendConfig: Configured for production environment');
  }

  // ========== MISSING METHODS FOR SETTINGS SCREEN ==========

  /// Get current settings as Map (needed by SettingsScreen)
  static Future<Map<String, dynamic>> getSettings() async {
    final environment = await getEnvironment();
    final tenant = await getTenant();
    final apiBaseUrl = await getApiBaseUrl();
    
    return {
      'environment': environment,
      'tenant': tenant,
      'apiBaseUrl': apiBaseUrl,
    };
  }

  /// Get debug information (needed by SettingsScreen)
  static Future<Map<String, dynamic>> getDebugInfo() async {
    final environment = await getEnvironment();
    final tenant = await getTenant();
    final apiBaseUrl = await getApiBaseUrl();
    
    return {
      'environment': environment,
      'tenant': tenant,
      'apiBaseUrl': apiBaseUrl,
      'isValid': await validateConfiguration(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Validate current configuration (needed by SettingsScreen)
  static Future<bool> validateConfiguration() async {
    final environment = await getEnvironment();
    final apiBaseUrl = await getApiBaseUrl();
    
    return environment.isNotEmpty && apiBaseUrl.isNotEmpty;
  }

  /// Get default headers for HTTP requests (needed by SettingsScreen)
  static Future<Map<String, String>> getDefaultHeaders() async {
    final tenant = await getTenant();
    
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Backend expects X-Tenant-ID (not X-Tenant)
    if (tenant.isNotEmpty) {
      headers['X-Tenant-ID'] = tenant;
    }

    return headers;
  }
}