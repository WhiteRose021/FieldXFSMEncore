import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class KataskeyesBFasiService {
  static const String _apiKey = "5af9459182c0ae4e1606e5d65864df25"; 
  
  // Updated API entity name
  static const String _apiEntity = "CKataskeyastikadates";

  Future<String?> _getCRMBaseUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedUrl = prefs.getString('crmDomain');

    if (storedUrl == null || storedUrl.isEmpty) return null;

    // Ensure HTTP protocol
    if (storedUrl.startsWith('https://')) {
      storedUrl = storedUrl.replaceFirst('https://', 'http://');
    }

    return storedUrl;
  }

  Future<String?> _getAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  /// Fetches all KataskeyesBFasi constructions (not just those assigned to the current user)
  Future<List<Map<String, dynamic>>> fetchAllConstructions() async {
    String? crmBaseUrl = await _getCRMBaseUrl();
    String? authToken = await _getAuthToken();

    if (crmBaseUrl == null || authToken == null) {
      print("⛔ CRM Base URL or Auth Token is missing.");
      return [];
    }

    List<Map<String, dynamic>> allConstructions = [];
    int offset = 0;
    int batchSize = 50;
    bool hasMoreData = true;

    while (hasMoreData) {
      final url = Uri.parse(
        "$crmBaseUrl/api/v1/$_apiEntity?maxSize=$batchSize&offset=$offset",
      );
      final headers = {
        'Authorization': 'Basic $authToken',
        'X-Api-Key': _apiKey,
      };

      try {
        print("🔄 Fetching all $_apiEntity constructions (Offset: $offset) from: $url");
        final response = await http.get(url, headers: headers);

        if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
          final list = jsonResponse['list'] as List<dynamic>? ?? [];
          
          final mappedConstructions = list.map<Map<String, dynamic>>((construction) => {
                "id": construction["id"] ?? "",
                "sr": construction["sr"] ?? "",
                "company": construction["customerName"] ?? "Unknown",  // Updated field name
                "description": construction["customerMobile"] ?? "",   // Updated field name
                "address": construction["name"] ?? "No Address",       // Updated field name
                "status": construction["status"] ?? "UNKNOWN",
                "mapsurl": construction["mapsurl"] ?? "",
                "assignedUserName": construction["assignedUserName"] ?? "Δεν έχει ανατεθεί",
                "customerFloor": construction["orofosbep"] ?? "",      // Updated field name
                "perioxi": construction["perioxi"] ?? "",
                "kagkela": construction["kagkela"] ?? "ΟΧΙ",
                "enaeria": construction["enaeria"] ?? "ΟΧΙ",
                "kanali": construction["kanali"] ?? "ΟΧΙ",
                "kya": construction["kya"] ?? "ΟΧΙ",
                "createdAt": construction["createdAt"] ?? "",
                "dateStart": construction["dateStart"] ?? "",          // Added field
                "dateEnd": construction["dateEnd"] ?? "",              // Added field
                "duration": construction["duration"] ?? 0,             // Added field
            }).toList();

          allConstructions.addAll(mappedConstructions);

          if (list.length < batchSize) {
            print("✅ No more data to fetch. Stopping pagination.");
            hasMoreData = false;
          } else {
            offset += batchSize;
          }
        } else {
          print("❌ Error fetching all $_apiEntity constructions: ${response.statusCode}");
          hasMoreData = false;
        }
      } catch (e) {
        print("❌ Exception while fetching constructions: $e");
        hasMoreData = false;
      }
    }

    print("✅ Total $_apiEntity Constructions Found: ${allConstructions.length}");
    return allConstructions;
  }

  /// Fetches all KataskeyesBFasi appointments assigned to the logged-in technician user
  Future<List<Map<String, dynamic>>> fetchTechnicianAppointments() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? crmBaseUrl = await _getCRMBaseUrl();
    String? userId = prefs.getString('userId');
    bool isTechnicianConstruct = true; // Always allow access for testing
    String? authToken = await _getAuthToken();

    if (crmBaseUrl == null || userId == null || authToken == null) {
      print("⛔ CRM URL/User ID/Auth Token is missing.");
      return [];
    }
    
    // Debug info about user
    print("💡 DEBUG: User ID: $userId");
    List<String>? teamNames = prefs.getStringList('teamNames');
    print("💡 DEBUG: User Teams: $teamNames");

    List<Map<String, dynamic>> allAppointments = [];
    int offset = 0;
    int batchSize = 50;
    bool hasMoreData = true;

    while (hasMoreData) {
      final url = Uri.parse(
        "$crmBaseUrl/api/v1/$_apiEntity?maxSize=$batchSize&offset=$offset",
      );
      final headers = {
        'Authorization': 'Basic $authToken',
        'X-Api-Key': _apiKey,
      };

      try {
        print("🔄 Fetching $_apiEntity appointments (Offset: $offset) from: $url");
        final response = await http.get(url, headers: headers);

        if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
          final list = jsonResponse['list'] as List<dynamic>? ?? [];
          // print("📜 Raw API Response List Size: ${list.length}");

          final filteredAppointments = list
              .where((appointment) => appointment['assignedUserId'] == userId)
              .map<Map<String, dynamic>>((appointment) => {
                    "id": appointment["id"] ?? "",
                    "sr": appointment["sr"] ?? "",
                    "company": appointment["customerName"] ?? "Unknown",     // Updated field name
                    "description": appointment["customerMobile"] ?? "",      // Updated field name
                    "address": appointment["name"] ?? "No Address",          // Updated field name
                    "status": appointment["status"] ?? "UNKNOWN",
                    "mapsurl": appointment["mapsurl"] ?? "",
                    "assignedUserName": appointment["assignedUserName"] ?? "Unknown",
                    "customerFloor": appointment["orofosbep"] ?? "",         // Updated field name
                    "perioxi": appointment["perioxi"] ?? "",
                    "kagkela": appointment["kagkela"] ?? "ΟΧΙ",
                    "enaeria": appointment["enaeria"] ?? "ΟΧΙ",
                    "kanali": appointment["kanali"] ?? "ΟΧΙ",
                    "kya": appointment["kya"] ?? "ΟΧΙ",
                    "createdAt": appointment["createdAt"] ?? "",
                    "dateStart": appointment["dateStart"] ?? "",             // Added field
                    "dateEnd": appointment["dateEnd"] ?? "",                 // Added field
                    "scheduledDate": _formatDateTime(appointment["dateStart"] ?? ""),  // Format date for display
                  })
              .toList();

          int numFound = filteredAppointments.length;
          int totalItems = list.length;
          print("✅ Found $numFound appointments assigned to user $userId");
          print("📋 Comparing $numFound current assignments with $totalItems known assignments");
          
          allAppointments.addAll(filteredAppointments);

          if (list.length < batchSize) {
            print("✅ No more data to fetch. Stopping pagination.");
            hasMoreData = false;
          } else {
            offset += batchSize;
          }
        } else {
          print("❌ Error fetching $_apiEntity appointments: ${response.statusCode}");
          hasMoreData = false;
        }
      } catch (e) {
        print("❌ Exception while fetching appointments: $e");
        hasMoreData = false;
      }
    }

    print("✅ Total $_apiEntity Appointments Found for User: ${allAppointments.length}");
    
    // If no appointments found, add some debug info
    if (allAppointments.isEmpty) {
      print("⚠️ No new assignments found");
    }
    
    return allAppointments;
  }

  /// Fetches detailed info for a single appointment by its ID
  Future<Map<String, dynamic>?> fetchAppointmentDetails(String appointmentId) async {
    final crmBaseUrl = await _getCRMBaseUrl();
    final authToken = await _getAuthToken();

    if (crmBaseUrl == null || appointmentId.isEmpty || authToken == null) {
      print("⛔ CRM Base URL, Appointment ID, or Auth Token is missing.");
      return null;
    }

    final url = Uri.parse("$crmBaseUrl/api/v1/$_apiEntity/$appointmentId");
    final headers = {
      'Authorization': 'Basic $authToken',
      'X-Api-Key': _apiKey,
    };

    try {
      print("🔄 Fetching details for $_apiEntity appointment ID: $appointmentId");
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
        print("✅ $_apiEntity Appointment Details Fetched for $appointmentId");
        
        // Process photos to extract attachment IDs and names
        Map<String, String> photoAttachments = {};
        if (jsonResponse["photos"] != null && jsonResponse["photos"].toString().isNotEmpty) {
          final photoHtml = jsonResponse["photos"].toString();
          final matches = RegExp(r'entryPoint=download&id=([a-f0-9]+)').allMatches(photoHtml);
          for (var match in matches) {
            final id = match.group(1);
            if (id != null) {
              photoAttachments[id] = "Photo_$id.jpg";
            }
          }
        }
        
        // Return a cleaned up version of the data with custom mapping
        return {
          "id": jsonResponse["id"] ?? "",
          "sr": jsonResponse["sr"] ?? "",
          "status": jsonResponse["status"] ?? "",
          "clientName": jsonResponse["customerName"] ?? "N/A",             // Updated field name
          "adminmobile": jsonResponse["customerMobile"] ?? "N/A",          // Updated field name
          "name": jsonResponse["name"] ?? "No Address",
          "mapsurl": jsonResponse["mapsurl"] ?? "",
          "dateStart": jsonResponse["dateStart"] ?? "",
          "customerFloor": jsonResponse["orofosbep"] ?? "",                // Updated field name
          "perioxi": jsonResponse["perioxi"] ?? "",
          "kagkela": jsonResponse["kagkela"] ?? "ΟΧΙ",
          "enaeria": jsonResponse["enaeria"] ?? "ΟΧΙ",
          "kanali": jsonResponse["kanali"] ?? "ΟΧΙ",
          "kya": jsonResponse["kya"] ?? "ΟΧΙ",
          "constructionType": jsonResponse["category"] ?? "N/A",
          "constructionPhase": jsonResponse["bep"] ?? "N/A",
          "constructionComments": jsonResponse["description"] ?? "",        // Updated field name
          "constructionAttachmentNames": photoAttachments,
          "aytopsias": jsonResponse["aytopsias"] ?? "",
          "adminName": jsonResponse["adminname"] ?? "",
          "adminNumber": jsonResponse["adminNumber"] ?? "",                 // Added field
          "infoHtml": jsonResponse["infoHtml"] ?? "",                       // Added field
          "floors1": jsonResponse["floors1"] ?? "",                         // Added field
          "materials": _extractMaterials(jsonResponse),
        };
      } else {
        print("❌ Error fetching $_apiEntity appointment details: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ Exception fetching $_apiEntity appointment details: $e");
      return null;
    }
  }

  /// Helper function to extract materials from the appointment data
  List<String> _extractMaterials(Map<String, dynamic> appointmentData) {
    List<String> materials = [];
    
    // Add materials based on the yes/no fields
    if (appointmentData["kagkela"] == "ΝΑΙ") {
      materials.add("Κάγκελα");
    }
    if (appointmentData["enaeria"] == "ΝΑΙ") {
      materials.add("Εναέρια");
    }
    if (appointmentData["kanali"] == "ΝΑΙ") {
      materials.add("Κανάλι");
    }
    if (appointmentData["kya"] == "ΝΑΙ") {
      materials.add("ΚΥΑ");
    }
    
    return materials;
  }

  /// Submits closure data for an appointment
  Future<bool> submitClosure(String appointmentId, Map<String, dynamic> data) async {
    final crmBaseUrl = await _getCRMBaseUrl();
    final authToken = await _getAuthToken();

    if (crmBaseUrl == null || appointmentId.isEmpty || authToken == null) {
      print("⛔ CRM Base URL, Appointment ID, or Auth Token is missing.");
      return false;
    }

    // Map the closure data to the appropriate field names
    Map<String, dynamic> apiData = {};
    
    // Always include status
    apiData["status"] = data["status"];
    
    // If status is ΟΛΟΚΛΗΡΩΣΗ, map other fields
    if (data["status"] == "ΟΛΟΚΛΗΡΩΣΗ") {
      if (data.containsKey("constructionStage")) {
        apiData["bep"] = data["constructionStage"];
      }
      if (data.containsKey("kagkela")) {
        apiData["kagkela"] = data["kagkela"];
      }
      if (data.containsKey("enaeria")) {
        apiData["enaeria"] = data["enaeria"];
      }
      if (data.containsKey("kanali")) {
        apiData["kanali"] = data["kanali"];
      }
      if (data.containsKey("kya")) {
        apiData["kya"] = data["kya"];
      }
      // Handle attachments if present
      if (data.containsKey("constructionAttachmentIds")) {
        apiData["photosIds"] = data["constructionAttachmentIds"];
      }
    }

    final url = Uri.parse("$crmBaseUrl/api/v1/$_apiEntity/$appointmentId");
    final headers = {
      'Authorization': 'Basic $authToken',
      'Content-Type': 'application/json',
    };

    try {
      print("🔄 Submitting closure data for $_apiEntity appointment ID: $appointmentId with data: $apiData");
      final response = await http.patch(url, headers: headers, body: json.encode(apiData));

      if (response.statusCode == 200) {
        print("✅ $_apiEntity closure data submitted successfully!");
        return true;
      } else {
        print("❌ Error submitting $_apiEntity closure data: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("❌ Exception submitting $_apiEntity closure data: $e");
      return false;
    }
  }

  /// Uploads an attachment file and returns the new attachment ID
  Future<String?> uploadAttachment({
    required String appointmentId,
    required String fileName,
    required String mimeType,
    required String base64FileContent,
  }) async {
    final crmBaseUrl = await _getCRMBaseUrl();
    final authToken = await _getAuthToken();

    if (crmBaseUrl == null || authToken == null) {
      print("⛔ CRM Base URL or Auth Token is missing.");
      return null;
    }

    final url = Uri.parse("$crmBaseUrl/api/v1/Attachment");
    final headers = {
      'Authorization': 'Basic $authToken',
      'X-Api-Key': _apiKey,
      'Content-Type': 'application/json',
    };

    final payload = {
      "name": fileName,
      "type": mimeType,
      "role": "Attachment",
      "parentType": _apiEntity,
      "field": "photos",  // The field name for photos
      "file": "data:$mimeType;base64,$base64FileContent"
    };

    try {
      print("🔄 Uploading attachment for $_apiEntity with payload: $payload");
      final response = await http.post(url, headers: headers, body: json.encode(payload));
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print("✅ $_apiEntity attachment uploaded successfully with id: ${jsonResponse['id']}");
        return jsonResponse['id'];
      } else {
        print("❌ Error uploading $_apiEntity attachment: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ Exception uploading $_apiEntity attachment: $e");
      return null;
    }
  }

  /// Fetches all KataskeyesBFasi buildings with specific statuses
  Future<List<Map<String, dynamic>>> fetchFilteredBuildings() async {
    String? crmBaseUrl = await _getCRMBaseUrl();
    String? authToken = await _getAuthToken();

    if (crmBaseUrl == null || authToken == null) {
      print("⛔ CRM URL or Auth Token is missing.");
      return [];
    }

    List<Map<String, dynamic>> buildings = [];
    int offset = 0;
    int batchSize = 50;
    bool hasMoreData = true;

    while (hasMoreData) {
      Uri url = Uri.parse(
          "$crmBaseUrl/api/v1/$_apiEntity?maxSize=$batchSize&offset=$offset");

      var headers = {
        'Authorization': 'Basic $authToken',
        'X-Api-Key': _apiKey,
      };

      try {
        print("🔄 Fetching filtered $_apiEntity buildings (Offset: $offset) from: $url");
        var response = await http.get(url, headers: headers);

        if (response.statusCode == 200) {
          var jsonResponse = json.decode(response.body);
          List<dynamic> list = jsonResponse['list'] ?? [];

          var filteredBuildings = list
              .where((building) =>
                  building['status'] == "ΑΠΟΣΤΟΛΗ" ||
                  building['status'] == "ΝΕΟ" ||
                  building['status'] == "ΑΠΟΡΡΙΨΗ")
              .map((building) => {
                    "id": building["id"] ?? "",
                    "sr": building["sr"] ?? "",
                    "company": building["customerName"] ?? "Unknown", // Updated field name
                    "description": building["customerMobile"] ?? "",  // Updated field name
                    "address": building["name"] ?? "No Address",      // Updated field name
                    "status": building["status"] ?? "UNKNOWN",
                    "createdAt": building["createdAt"] ?? "",
                    "assignedUserName": building["assignedUserName"] ?? "Δεν βρέθηκε.",
                    "perioxi": building["perioxi"] ?? "",
                    "dateStart": building["dateStart"] ?? "",         // Added field
                  })
              .toList();

          buildings.addAll(filteredBuildings);

          if (list.length < batchSize) {
            print("✅ No more data to fetch. Stopping pagination.");
            hasMoreData = false;
          } else {
            offset += batchSize;
          }
        } else {
          print("❌ Error fetching $_apiEntity buildings: ${response.statusCode}");
          hasMoreData = false;
        }
      } catch (e) {
        print("❌ Error fetching $_apiEntity buildings: $e");
        hasMoreData = false;
      }
    }

    print("✅ Total Filtered $_apiEntity Buildings Found: ${buildings.length}");
    return buildings;
  }

  /// Fetches details for a specific building
  Future<Map<String, dynamic>?> fetchBuildingDetails(String buildingId) async {
    String? crmBaseUrl = await _getCRMBaseUrl();

    if (crmBaseUrl == null) {
      print("⛔ CRM URL is missing.");
      return null;
    }

    Uri url = Uri.parse("$crmBaseUrl/api/v1/$_apiEntity/$buildingId");

    var headers = {'X-Api-Key': _apiKey};

    try {
      print("🔄 Fetching $_apiEntity building details from: $url");
      var response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);

        return {
          "id": jsonResponse["id"] ?? "",
          "sr": jsonResponse["sr"] ?? "",
          "status": jsonResponse["status"] ?? "",
          "createdAt": jsonResponse["createdAt"] ?? "",
          "clientName": jsonResponse["customerName"] ?? "N/A",   // Updated field name
          "adminmobile": jsonResponse["customerMobile"] ?? "N/A", // Updated field name
          "name": jsonResponse["name"] ?? "No Address",
          "mapsurl": jsonResponse["mapsurl"] ?? "",
          "perioxi": jsonResponse["perioxi"] ?? "",
          "customerFloor": jsonResponse["orofosbep"] ?? "",      // Updated field name
        };
      } else {
        print("❌ Error fetching $_apiEntity building details: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ Error fetching $_apiEntity building details: $e");
      return null;
    }
  }
  
  /// Helper function to format date time
  String _formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return "${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return dateTimeStr;
    }
  }
}