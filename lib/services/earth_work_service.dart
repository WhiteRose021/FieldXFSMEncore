import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class EarthWorkService {
  static const String _apiKey = "5af9459182c0ae4e1606e5d65864df25"; 
  
  // API entity name for earthwork
  static const String _apiEntity = "CEarthWork";

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

  /// Fetches all earthwork jobs (not just those assigned to the current user)
  Future<List<Map<String, dynamic>>> fetchAllEarthWorks() async {
    String? crmBaseUrl = await _getCRMBaseUrl();
    String? authToken = await _getAuthToken();

    if (crmBaseUrl == null || authToken == null) {
      print("⛔ CRM Base URL or Auth Token is missing.");
      return [];
    }

    List<Map<String, dynamic>> allEarthWorks = [];
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
        print("🔄 Fetching all $_apiEntity jobs (Offset: $offset) from: $url");
        final response = await http.get(url, headers: headers);

        if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
          final list = jsonResponse['list'] as List<dynamic>? ?? [];
          
          final mappedEarthWorks = list.map<Map<String, dynamic>>((earthwork) => {
                "id": earthwork["id"] ?? "",
                "sr": earthwork["sr"] ?? "",
                "company": earthwork["customerName"] ?? "Unknown",
                "description": earthwork["customerMobile"] ?? "",
                "address": earthwork["name"] ?? "No Address",
                "status": earthwork["status"] ?? "UNKNOWN",
                "mapsurl": earthwork["mapsurl"] ?? "",
                "cabAddress": earthwork["cabAddress"] ?? "",
                "assignedUserName": earthwork["assignedUserName"] ?? "Δεν έχει ανατεθεί",
                "difficultyLevel": earthwork["difficultyLevel"] ?? "",
                "emfyshsh": earthwork["emfyshsh"] ?? "ΟΧΙ",
                "typosPlakas": earthwork["typosPlakas"] ?? "",
                "megethosPlakas": earthwork["megethosPlakas"] ?? "",
                "mikosChwma": earthwork["mikosChwma"] ?? 0,
                "garden": earthwork["garden"] ?? "ΟΧΙ",
                "skapsimo": earthwork["skapsimo"] ?? "ΟΧΙ",
                "createdAt": earthwork["createdAt"] ?? "",
                "dateStart": earthwork["dateStart"] ?? "",
                "dateEnd": earthwork["dateEnd"] ?? "",
                "duration": earthwork["duration"] ?? 0,
            }).toList();

          allEarthWorks.addAll(mappedEarthWorks);

          if (list.length < batchSize) {
            print("✅ No more data to fetch. Stopping pagination.");
            hasMoreData = false;
          } else {
            offset += batchSize;
          }
        } else {
          print("❌ Error fetching all $_apiEntity jobs: ${response.statusCode}");
          hasMoreData = false;
        }
      } catch (e) {
        print("❌ Exception while fetching earthworks: $e");
        hasMoreData = false;
      }
    }

    print("✅ Total $_apiEntity Jobs Found: ${allEarthWorks.length}");
    return allEarthWorks;
  }

  /// Fetches all earthwork jobs assigned to the logged-in technician
  Future<List<Map<String, dynamic>>> fetchTechnicianAppointments() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? crmBaseUrl = await _getCRMBaseUrl();
    String? userId = prefs.getString('userId');
    bool isTechnicianEarthworker = prefs.getBool('isTechnicianEarthworker') ?? false;
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
          print("📜 Raw API Response List Size: ${list.length}");

          final filteredAppointments = list
              .where((appointment) => appointment['assignedUserId'] == userId)
              .map<Map<String, dynamic>>((appointment) => {
                    "id": appointment["id"] ?? "",
                    "sr": appointment["sr"] ?? "",
                    "company": appointment["customerName"] ?? "Unknown",
                    "description": appointment["customerMobile"] ?? "",
                    "address": appointment["name"] ?? "No Address",
                    "status": appointment["status"] ?? "UNKNOWN",
                    "mapsurl": appointment["mapsurl"] ?? "",
                    "cabAddress": appointment["cabAddress"] ?? "",
                    "assignedUserName": appointment["assignedUserName"] ?? "Unknown",
                    "difficultyLevel": appointment["difficultyLevel"] ?? "",
                    "emfyshsh": appointment["emfyshsh"] ?? "ΟΧΙ",
                    "typosPlakas": appointment["typosPlakas"] ?? "",
                    "megethosPlakas": appointment["megethosPlakas"] ?? "",
                    "mikosChwma": appointment["mikosChwma"] ?? 0,
                    "garden": appointment["garden"] ?? "ΟΧΙ",
                    "skapsimo": appointment["skapsimo"] ?? "ΟΧΙ",
                    "createdAt": appointment["createdAt"] ?? "",
                    "dateStart": appointment["dateStart"] ?? "",
                    "dateEnd": appointment["dateEnd"] ?? "",
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

  /// Fetches detailed info for a single earthwork job by its ID
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
          "clientName": jsonResponse["customerName"] ?? "N/A",
          "adminmobile": jsonResponse["customerMobile"] ?? "N/A",
          "name": jsonResponse["name"] ?? "No Address",
          "mapsurl": jsonResponse["mapsurl"] ?? "",
          "cabAddress": jsonResponse["cabAddress"] ?? "",
          "dateStart": jsonResponse["dateStart"] ?? "",
          "dateEnd": jsonResponse["dateEnd"] ?? "",
          "difficultyLevel": jsonResponse["difficultyLevel"] ?? "ΕΥΚΟΛΟ",
          "emfyshsh": jsonResponse["emfyshsh"] ?? "ΟΧΙ",
          "typosPlakas": jsonResponse["typosPlakas"] ?? "ΛΕΥΚΗ",
          "megethosPlakas": jsonResponse["megethosPlakas"] ?? "ΑΛΛΟ",
          "mikosChwma": jsonResponse["mikosChwma"] ?? 0,
          "garden": jsonResponse["garden"] ?? "ΟΧΙ",
          "skapsimo": jsonResponse["skapsimo"] ?? "ΟΧΙ",
          "photoAttachments": photoAttachments,
          "aytopsia": jsonResponse["aytopsia"] ?? "",
          "description": jsonResponse["description"] ?? "",
          "cordX": jsonResponse["cordX"] ?? "",
          "cordY": jsonResponse["cordy"] ?? "",
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

  /// Submits closure data for an appointment
  Future<bool> submitClosure(String appointmentId, Map<String, dynamic> data) async {
    final crmBaseUrl = await _getCRMBaseUrl();
    final authToken = await _getAuthToken();

    if (crmBaseUrl == null || appointmentId.isEmpty || authToken == null) {
      print("⛔ CRM Base URL, Appointment ID, or Auth Token is missing.");
      return false;
    }

    final url = Uri.parse("$crmBaseUrl/api/v1/$_apiEntity/$appointmentId");
    final headers = {
      'Authorization': 'Basic $authToken',
      'X-Api-Key': _apiKey,
      'Content-Type': 'application/json',
    };

    try {
      print("🔄 Submitting closure data for $_apiEntity appointment ID: $appointmentId with data: $data");
      final response = await http.patch(url, headers: headers, body: json.encode(data));

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

  /// Fetches filtered earthwork jobs
  Future<List<Map<String, dynamic>>> fetchFilteredEarthWorks() async {
    String? crmBaseUrl = await _getCRMBaseUrl();
    String? authToken = await _getAuthToken();

    if (crmBaseUrl == null || authToken == null) {
      print("⛔ CRM URL or Auth Token is missing.");
      return [];
    }

    List<Map<String, dynamic>> earthWorks = [];
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
        print("🔄 Fetching filtered $_apiEntity jobs (Offset: $offset) from: $url");
      var response = await http.get(url, headers: headers);

        if (response.statusCode == 200) {
          var jsonResponse = json.decode(response.body);
          List<dynamic> list = jsonResponse['list'] ?? [];

          var filteredEarthWorks = list
              .where((item) =>
                  item['status'] == "ΑΠΟΣΤΟΛΗ" ||
                  item['status'] == "ΝΕΟ" ||
                  item['status'] == "ΑΠΟΡΡΙΨΗ")
              .map((item) => {
                    "id": item["id"] ?? "",
                    "sr": item["sr"] ?? "",
                    "company": item["customerName"] ?? "Unknown",
                    "description": item["customerMobile"] ?? "",
                    "address": item["name"] ?? "No Address",
                    "status": item["status"] ?? "UNKNOWN",
                    "createdAt": item["createdAt"] ?? "",
                    "assignedUserName": item["assignedUserName"] ?? "Δεν βρέθηκε.",
                    "difficultyLevel": item["difficultyLevel"] ?? "",
                    "dateStart": item["dateStart"] ?? "",
                  })
              .toList();

          earthWorks.addAll(filteredEarthWorks);

          if (list.length < batchSize) {
            print("✅ No more data to fetch. Stopping pagination.");
            hasMoreData = false;
          } else {
            offset += batchSize;
          }
        } else {
          print("❌ Error fetching $_apiEntity earthworks: ${response.statusCode}");
          hasMoreData = false;
        }
      } catch (e) {
        print("❌ Error fetching $_apiEntity earthworks: $e");
        hasMoreData = false;
      }
    }

    print("✅ Total Filtered $_apiEntity Jobs Found: ${earthWorks.length}");
    return earthWorks;
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