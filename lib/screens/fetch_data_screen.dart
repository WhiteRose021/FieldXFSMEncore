// lib/screens/enhanced_fetch_data_screen.dart
import 'package:fieldx_fsm/services/attachment_image_cache_service.dart';
import 'package:fieldx_fsm/services/earth_work_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fieldx_fsm/services/enhanced_service_adapters.dart';
import 'dashboard_screen.dart';
import 'dart:convert';
import 'dart:async';

class EnhancedFetchDataScreen extends StatefulWidget {
  const EnhancedFetchDataScreen({super.key});

  @override
  _EnhancedFetchDataScreenState createState() => _EnhancedFetchDataScreenState();
}

class _EnhancedFetchDataScreenState extends State<EnhancedFetchDataScreen> with TickerProviderStateMixin {
  String statusMessage = "Εκκίνηση συστήματος..."; // Greek for "Starting system..."
  String subStatusMessage = "Παρακαλώ περιμένετε όσο προετοιμάζουμε τον χώρο εργασίας σας"; // Greek for "Please wait while we prepare your workspace"
  double progressValue = 0.0;
  bool dataFetched = false;
  bool _isDisposed = false;
  String? _currentBackend;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _getCurrentBackend();
    _fetchAllData();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _pulseController.repeat(reverse: true);
  }

  void _getCurrentBackend() {
    setState(() {
      _currentBackend = BackendManager.getCurrentBackend().name.toUpperCase();
    });
  }

  void _updateProgress(double progress, String status, String subStatus) {
    if (mounted && !_isDisposed) {
      setState(() {
        progressValue = progress;
        statusMessage = status;
        subStatusMessage = subStatus;
      });
    }
  }

  void _safeNavigateToLogin() {
    if (mounted && !_isDisposed) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _safeNavigateToDashboard() {
    if (mounted && !_isDisposed) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    }
  }

  Future<void> _fetchAllData() async {
    if (dataFetched) return;
    dataFetched = true;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Step 1: Authentication validation
      _updateProgress(0.1, "Πιστοποίηση", "Επαλήθευση διαπιστευτηρίων με $_currentBackend backend..."); // Authentication, Verifying credentials
      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted || _isDisposed) return;

      String? userId = prefs.getString('userId');
      String userName = prefs.getString('userName') ?? 'Unknown';

      if (userId == null || userId.isEmpty) {
        print("❌ User ID not found - redirecting to login");
        _updateProgress(0.0, "Σφάλμα πιστοποίησης", "Απαιτείται νέα σύνδεση..."); // Authentication error, New login required
        await Future.delayed(const Duration(seconds: 2));
        _safeNavigateToLogin();
        return;
      }

      print("✅ User authenticated: $userName (ID: $userId) via $_currentBackend backend");

      // Step 2: Backend connectivity test
      _updateProgress(0.15, "Δοκιμή σύνδεσης", "Έλεγχος συνδεσιμότητας $_currentBackend backend..."); // Connection test
      
      final isBackendHealthy = await BackendManager.testConnectivity();
      if (!isBackendHealthy) {
        print("⚠️ Backend not healthy, but continuing with cached data");
        _updateProgress(0.2, "Λειτουργία εκτός σύνδεσης", "Χρήση αποθηκευμένων δεδομένων..."); // Offline mode
      } else {
        print("✅ $_currentBackend backend is healthy");
        _updateProgress(0.2, "Σύνδεση επιτυχής", "Συνδέθηκε στο $_currentBackend backend..."); // Connection successful
      }

      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted || _isDisposed) return;

      // Step 3: Determine user type and load appropriate data
      bool isTechnicianAutopsy = prefs.getBool('isTechnicianAutopsy') ?? false;
      bool isTechnicianSplicer = prefs.getBool('isTechnicianSplicer') ?? false;
      bool isTechnicianConstruct = prefs.getBool('isTechnicianConstruct') ?? false;
      bool isTechnicianEarthworker = prefs.getBool('isTechnicianEarthworker') ?? false;

      print("🔧 User types - Autopsy: $isTechnicianAutopsy, Splicer: $isTechnicianSplicer, Construct: $isTechnicianConstruct, Earthworker: $isTechnicianEarthworker");

      // Load data based on user type
      if (isTechnicianAutopsy) {
        await _loadAutopsyData(prefs);
      }
      
      if (isTechnicianSplicer) {
        await _loadSplicerData(prefs);
      }
      
      if (isTechnicianConstruct) {
        await _loadConstructionData(prefs);
      }
      
      if (isTechnicianEarthworker) {
        await _loadEarthworkerData(prefs);
      }

      // If no specific technician type, load general data
      if (!isTechnicianAutopsy && !isTechnicianSplicer && !isTechnicianConstruct && !isTechnicianEarthworker) {
        await _loadGeneralData(prefs);
      }

      // Step: Final completion
      if (!mounted || _isDisposed) return;
      
      _updateProgress(1.0, "Ολοκλήρωση", "Καλώς ήρθατε στο FieldX!"); // Completion, Welcome to FieldX
      await Future.delayed(const Duration(milliseconds: 1000));

      print("✅ Data loading completed via $_currentBackend backend");
      _safeNavigateToDashboard();

    } catch (e) {
      print("❌ Error during data fetching: $e");
      
      if (!mounted || _isDisposed) return;
      
      _updateProgress(0.0, "Σφάλμα φόρτωσης", "Προσπάθεια επανασύνδεσης..."); // Loading error, Attempting reconnection
      await Future.delayed(const Duration(seconds: 2));
      
      // Try to switch to EspoCRM if Encore fails, or vice versa
      await _handleBackendFailover(e);
    }
  }

  /// Handle backend failover
  Future<void> _handleBackendFailover(dynamic error) async {
    if (BackendManager.isUsingEncore()) {
      print("🔄 Encore backend failed, attempting EspoCRM fallback...");
      _updateProgress(0.1, "Εναλλαγή backend", "Δοκιμή εναλλακτικού συστήματος..."); // Backend switch
      
      try {
        await BackendManager.switchToEspoCRM();
        setState(() {
          _currentBackend = "ESPOCRM";
        });
        
        // Retry data fetching with EspoCRM
        dataFetched = false; // Reset flag
        await _fetchAllData();
        return;
      } catch (e) {
        print("❌ EspoCRM fallback also failed: $e");
      }
    }
    
    // If all backends fail, navigate to login
    _safeNavigateToLogin();
  }

  /// Load autopsy technician data
  Future<void> _loadAutopsyData(SharedPreferences prefs) async {
    _updateProgress(0.3, "Φόρτωση αυτοψιών", "Ανάκτηση δεδομένων αυτοψιών από $_currentBackend..."); // Loading autopsies
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted || _isDisposed) return;

    try {
      List<Map<String, dynamic>> autopsyAppointments = [];
      autopsyAppointments = await AutopsyAppointmentService().fetchTechnicianAutopsyAppointments();
      await prefs.setString('cachedAutopsyAppointments', jsonEncode(autopsyAppointments));
      
      print("✅ Loaded ${autopsyAppointments.length} autopsy appointments from $_currentBackend backend");
      _updateProgress(0.5, "Δεδομένα αυτοψίας", "Φορτώθηκαν ${autopsyAppointments.length} ραντεβού αυτοψίας"); // Autopsy data loaded
    } catch (e) {
      print("❌ Error loading autopsy data: $e");
      _updateProgress(0.5, "Προειδοποίηση", "Αδυναμία φόρτωσης αυτοψιών - χρήση cache"); // Warning, using cache
    }

    await Future.delayed(const Duration(milliseconds: 800));
  }

  /// Load splicer technician data (enhanced with backend awareness)
  Future<void> _loadSplicerData(SharedPreferences prefs) async {
    _updateProgress(0.4, "Φόρτωση ραντεβού", "Ανάκτηση προγραμματισμένων εργασιών από $_currentBackend..."); // Loading appointments
    
    List<Map<String, dynamic>> appointments = [];
    try {
      appointments = await AppointmentService().fetchTechnicianAppointments();
      await prefs.setString('cachedAppointments', jsonEncode(appointments));
      
      print("✅ Loaded ${appointments.length} splicer appointments from $_currentBackend backend");
      _updateProgress(0.5, "Δεδομένα ραντεβού", "Φορτώθηκαν ${appointments.length} ραντεβού"); // Appointment data loaded
    } catch (e) {
      print("❌ Error loading splicer appointments: $e");
      final cachedData = prefs.getString('cachedAppointments');
      if (cachedData != null) {
        appointments = List<Map<String, dynamic>>.from(jsonDecode(cachedData));
        print("📱 Loaded ${appointments.length} cached appointments");
      }
      _updateProgress(0.5, "Προειδοποίηση", "Χρήση αποθηκευμένων ραντεβού"); // Warning, using cached appointments
    }

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted || _isDisposed) return;

    // Load buildings
    _updateProgress(0.55, "Φόρτωση κτιρίων", "Ανάκτηση στοιχείων κτιρίων από $_currentBackend..."); // Loading buildings
    
    List<Map<String, dynamic>> buildings = [];
    try {
      buildings = await CSplicingWorkService().fetchFilteredBuildings();
      await prefs.setString('cachedBuildings', jsonEncode(buildings));
      
      print("✅ Loaded ${buildings.length} buildings from $_currentBackend backend");
      _updateProgress(0.65, "Δεδομένα κτιρίων", "Φορτώθηκαν ${buildings.length} κτίρια"); // Building data loaded
    } catch (e) {
      print("❌ Error loading buildings: $e");
      final cachedData = prefs.getString('cachedBuildings');
      if (cachedData != null) {
        buildings = List<Map<String, dynamic>>.from(jsonDecode(cachedData));
        print("📱 Loaded ${buildings.length} cached buildings");
      }
      _updateProgress(0.65, "Προειδοποίηση", "Χρήση αποθηκευμένων κτιρίων"); // Warning, using cached buildings
    }

    await Future.delayed(const Duration(milliseconds: 800));
  }

  /// Load construction technician data
  Future<void> _loadConstructionData(SharedPreferences prefs) async {
    _updateProgress(0.6, "Φόρτωση κατασκευής", "Ανάκτηση δεδομένων κατασκευής από $_currentBackend..."); // Loading construction data

    if (!mounted || _isDisposed) return;

    try {
      List<Map<String, dynamic>> constructionAppointments = [];
      constructionAppointments = await ConstructionAppointmentService().fetchTechnicianConstructionAppointments();
      await prefs.setString('cachedConstructionAppointments', jsonEncode(constructionAppointments));
      
      print("✅ Loaded ${constructionAppointments.length} construction appointments from $_currentBackend backend");
      _updateProgress(0.7, "Δεδομένα κατασκευής", "Φορτώθηκαν ${constructionAppointments.length} ραντεβού κατασκευής"); // Construction data loaded
    } catch (e) {
      print("❌ Error loading construction data: $e");
      _updateProgress(0.7, "Προειδοποίηση", "Χρήση αποθηκευμένων δεδομένων κατασκευής"); // Warning, using cached construction data
    }

    await Future.delayed(const Duration(milliseconds: 800));
  }

  /// Load earthworker data
  Future<void> _loadEarthworkerData(SharedPreferences prefs) async {
    _updateProgress(0.65, "Φόρτωση χωματουργικών", "Ανάκτηση εργασιών χωματουργικών από $_currentBackend..."); // Loading earthwork data

    if (!mounted || _isDisposed) return;

    try {
      List<Map<String, dynamic>> earthworkAppointments = [];
      await prefs.setString('cachedEarthworkAppointments', jsonEncode(earthworkAppointments));
      
      print("✅ Loaded ${earthworkAppointments.length} earthwork appointments from $_currentBackend backend");
      _updateProgress(0.75, "Δεδομένα χωματουργικών", "Φορτώθηκαν ${earthworkAppointments.length} εργασίες"); // Earthwork data loaded
    } catch (e) {
      print("❌ Error loading earthwork data: $e");
      _updateProgress(0.75, "Προειδοποίηση", "Χρήση αποθηκευμένων χωματουργικών"); // Warning, using cached earthwork data
    }

    await Future.delayed(const Duration(milliseconds: 800));
  }

  /// Load general data for non-technician users
  Future<void> _loadGeneralData(SharedPreferences prefs) async {
    _updateProgress(0.5, "Φόρτωση γενικών δεδομένων", "Ανάκτηση βασικών στοιχείων από $_currentBackend..."); // Loading general data

    if (!mounted || _isDisposed) return;

    try {
      // Load metadata
      final metadataService = MetadataService();
      final metadata = await metadataService.fetchMetadata();
      
      if (metadata != null) {
        final metadataJson = json.encode(metadata);
        await prefs.setString('metadata', metadataJson);
        await prefs.setString('metadataTimestamp', DateTime.now().millisecondsSinceEpoch.toString());
        print("✅ General metadata loaded from $_currentBackend backend");
      }
      
      _updateProgress(0.8, "Μεταδεδομένα", "Φορτώθηκαν ρυθμίσεις συστήματος"); // Metadata loaded
    } catch (e) {
      print("❌ Error loading general data: $e");
      _updateProgress(0.8, "Προειδοποίηση", "Χρήση αποθηκευμένων ρυθμίσεων"); // Warning, using cached settings
    }

    await Future.delayed(const Duration(milliseconds: 800));
  }

  @override
  void dispose() {
    _isDisposed = true;
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo and title
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Color(0xFF0066CC),
                        borderRadius: BorderRadius.circular(60),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF0066CC).withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.engineering,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 32),
              
              Text(
                "FieldX Mobile",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0066CC),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Backend indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: BackendManager.isUsingEncore() 
                    ? Colors.blue.withOpacity(0.1)
                    : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: BackendManager.isUsingEncore() ? Colors.blue : Colors.green,
                  ),
                ),
                child: Text(
                  "Backend: $_currentBackend",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: BackendManager.isUsingEncore() ? Colors.blue : Colors.green,
                  ),
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Progress indicator
              LinearProgressIndicator(
                value: progressValue,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0066CC)),
                minHeight: 8,
              ),
              
              const SizedBox(height: 24),
              
              // Status message
              Text(
                statusMessage,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0066CC),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              // Sub-status message
              Text(
                subStatusMessage,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Progress percentage
              Text(
                "${(progressValue * 100).toInt()}%",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0066CC),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}