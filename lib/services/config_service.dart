import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Simple configuration service for API endpoints
class ConfigService {
  static bool _isInitialized = false;
  
  /// Initialize the configuration service
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await dotenv.load(fileName: ".env");
      _isInitialized = true;
      print("✅ API Configuration loaded successfully");
    } catch (e) {
      print("❌ Failed to load .env file: $e");
      print("⚠️ Using default API endpoint values");
      _isInitialized = true;
    }
  }
  
  /// Get a configuration value with default fallback
  static String _get(String key, String defaultValue) {
    if (!_isInitialized) {
      print("⚠️ ConfigService not initialized, using default for $key");
      return defaultValue;
    }
    return dotenv.env[key] ?? defaultValue;
  }
  
  // ==================== API ENDPOINTS ====================
  
  /// Core API Endpoints
  static String get splicingWork => _get('ENDPOINT_SPLICING_WORK', 'CSplicingWork');
  static String get autopsyAppointment => _get('ENDPOINT_AUTOPSY_APPOINTMENT', 'Test');
  static String get user => _get('ENDPOINT_USER', 'User');
  static String get metadata => _get('ENDPOINT_METADATA', 'Metadata');
  static String get attachment => _get('ENDPOINT_ATTACHMENT', 'Attachment');
  static String get appUser => _get('ENDPOINT_APP_USER', 'App/user');
  
  /// Additional Entity Endpoints
  static String get autopsyInspection => _get('ENDPOINT_AUTOPSY_INSPECTION', 'Aytopsies1');
  static String get outsideAutopsy => _get('ENDPOINT_OUTSIDE_AUTOPSY', 'COutsideAytopsies');
  static String get smsSender => _get('ENDPOINT_SMS_SENDER', 'CSmsSender');
  static String get billing => _get('ENDPOINT_BILLING', 'CBilling');
  static String get master => _get('ENDPOINT_MASTER', 'CMaster');
  static String get emfyshsh => _get('ENDPOINT_EMFYSHSH', 'CEmfyshsh');
  static String get tobbs => _get('ENDPOINT_TOBBS', 'CTobbs');
  static String get pilotAutopsy => _get('ENDPOINT_PILOT_AUTOPSY', 'CPilotAutopsies');
  static String get chatMessage => _get('ENDPOINT_CHAT_MESSAGE', 'CChatMessage');
  static String get importLog => _get('ENDPOINT_IMPORT_LOG', 'CImportLog');
  static String get chatConversation => _get('ENDPOINT_CHAT_CONVERSATION', 'CChatConversation');
  static String get chatGroup => _get('ENDPOINT_CHAT_GROUP', 'CChatGroup');
  static String get vlaves => _get('ENDPOINT_VLAVES', 'CVlaves');
  static String get chomatourgika => _get('ENDPOINT_CHOMATOURGIKA', 'CChomatourgika');
  static String get kataskeyesBFasi => _get('ENDPOINT_KATASKEYES_B_FASI', 'KataskeyesBFasi');
  static String get texnikosElegxos => _get('ENDPOINT_TEXNIKOS_ELEGXOS', 'Texnikoselegxos');
  static String get dummy => _get('ENDPOINT_DUMMY', 'Dummy');
  
  /// API Configuration
  static String get apiVersion => _get('API_VERSION', 'v1');
  static String get apiBasePath => _get('API_BASE_PATH', '/api/v1');
  static int get batchSize => int.tryParse(_get('BATCH_SIZE', '50')) ?? 50;
  
  /// Build full API endpoint URL
  static String buildEndpoint(String entityName, [String? id, String? action]) {
    var url = '$apiBasePath/$entityName';
    if (id != null && id.isNotEmpty) {
      url += '/$id';
    }
    if (action != null && action.isNotEmpty) {
      url += '/$action';
    }
    return url;
  }
  
  /// Get all available endpoints as a map
  static Map<String, String> getAllEndpoints() {
    return {
      'splicingWork': splicingWork,
      'autopsyAppointment': autopsyAppointment,
      'user': user,
      'metadata': metadata,
      'attachment': attachment,
      'appUser': appUser,
      'autopsyInspection': autopsyInspection,
      'outsideAutopsy': outsideAutopsy,
      'smsSender': smsSender,
      'billing': billing,
      'master': master,
      'emfyshsh': emfyshsh,
      'tobbs': tobbs,
      'pilotAutopsy': pilotAutopsy,
      'chatMessage': chatMessage,
      'importLog': importLog,
      'chatConversation': chatConversation,
      'chatGroup': chatGroup,
      'vlaves': vlaves,
      'chomatourgika': chomatourgika,
      'kataskeyesBFasi': kataskeyesBFasi,
      'texnikosElegxos': texnikosElegxos,
      'dummy': dummy,
    };
  }
}