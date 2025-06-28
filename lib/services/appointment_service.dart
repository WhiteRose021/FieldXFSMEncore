import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AppointmentService {
  static const String apiKey = "5af9459182c0ae4e1606e5d65864df25";
  static const int _batchSize = 50;
  
  // Expose baseUrl for SyncEngine
  static String? _baseUrl;
  static Future<String> get baseUrl async {
    if (_baseUrl != null) return _baseUrl!;
    final prefs = await SharedPreferences.getInstance();
    String? storedUrl = prefs.getString('crmDomain');
    if (storedUrl == null || storedUrl.isEmpty) {
      throw Exception("CRM URL is not configured");
    }
    if (storedUrl.startsWith('https://')) {
      storedUrl = storedUrl.replaceFirst('https://', 'http://');
    }
    _baseUrl = storedUrl;
    return _baseUrl!;
  }

  // Helper to get auth headers
  static Future<Map<String, String>> get authHeaders async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken');
    if (authToken == null) {
      throw Exception("No authentication token available");
    }
    return {
      'Authorization': 'Basic $authToken',
      'X-Api-Key': apiKey,
    };
  }

  /// Retrieves the base CRM URL from SharedPreferences, ensuring HTTP usage.
  Future<String?> _getCRMBaseUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedUrl = prefs.getString('crmDomain');

    if (storedUrl == null || storedUrl.isEmpty) {
      return null;
    }
    if (storedUrl.startsWith('https://')) {
      storedUrl = storedUrl.replaceFirst('https://', 'http://');
    }
    return storedUrl;
  }

  /// Retrieves the auth token from SharedPreferences.
  Future<String?> _getAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  /// Fetches all appointments assigned to the logged-in technician user.
  Future<List<Map<String, dynamic>>> fetchTechnicianAppointments() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? crmBaseUrl = await _getCRMBaseUrl();
    String? userId = prefs.getString('userId');
    bool isTechnicianSplicer = prefs.getBool('isTechnicianSplicer') ?? false;
    String? authToken = await _getAuthToken();

    if (!isTechnicianSplicer || crmBaseUrl == null || userId == null || authToken == null) {
      print("⛔ User is not a technician or CRM URL/User ID/Auth Token is missing.");
      return [];
    }

    List<Map<String, dynamic>> allAppointments = [];
    int offset = 0;
    bool hasMoreData = true;

    while (hasMoreData) {
      final url = Uri.parse(
        "$crmBaseUrl/api/v1/CSplicingWork?maxSize=$_batchSize&offset=$offset",
      );
      final headers = {
        'Authorization': 'Basic $authToken',
        'X-Api-Key': apiKey,
      };

      try {
        print("🔄 Fetching appointments (Offset: $offset) from: $url");
        final response = await http.get(url, headers: headers);

        if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
          final list = jsonResponse['list'] as List<dynamic>? ?? [];
          // print("📜 Raw API Response List: $list"); // Log the raw list to see all fields

          final filteredAppointments = list
              .where((appointment) => appointment['assignedUserId'] == userId)
              .map<Map<String, dynamic>>((appointment) => {
                    "id": appointment["id"] ?? "",
                    "sr": appointment["sr"] ?? "",
                    "company": appointment["clientName"] ?? "Unknown",
                    "description": appointment["adminmobile"] ?? "",
                    "address": appointment["name"] ?? "No Address",
                    "status": appointment["status"] ?? "UNKNOWN",
                    "mapsurl": appointment["mapsurl"] ?? "",
                    "assignedUserName": appointment["assignedUserName"] ?? "Unknown", // Fetch assignedUserName
                    "assignedUserId": appointment["assignedUserId"] ?? "", // Include assignedUserId for polling
                    "name": appointment["name"] ?? "New task", // Include name for notification text
                    "sxolia": appointment["sxolia"] ?? "Δεν υπάρχουν σχόλια",
                    "cabaddresslink": appointment["cabaddresslink"] ?? "N/A",
                    "attachmentfbIds": appointment["attachmentfbIds"] ?? [],
                    "attachmentfbNames": appointment["attachmentfbNames"] ?? [],
                    "attachmentfbTypes": appointment["attachmentfbTypes"] ?? [],
                    "maurh": appointment["maurh"] ?? [],
                  })
              .toList();

          allAppointments.addAll(filteredAppointments);

          if (list.length < _batchSize) {
            print("✅ No more data to fetch. Stopping pagination.");
            hasMoreData = false;
          } else {
            offset += _batchSize;
          }
        } else {
          print("❌ Error fetching appointments: ${response.statusCode}");
          hasMoreData = false;
        }
      } catch (e) {
        print("❌ Exception while fetching appointments: $e");
        hasMoreData = false;
      }
    }

    print("✅ Total Appointments Found for User: ${allAppointments.length}");
    return allAppointments;
  }
  
  /// Fetches appointments assigned to the current user
  Future<List<Map<String, dynamic>>> fetchAssignedAppointments() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    
    if (userId == null) {
      print("⛔ No user ID found in preferences");
      return [];
    }
    
    try {
      // Fetch all appointments using your existing method
      List<Map<String, dynamic>> allAppointments = await fetchTechnicianAppointments();
      
      // Filter for appointments assigned to the current user
      // (technically redundant since fetchTechnicianAppointments already filters,
      // but keeping as a safeguard)
      List<Map<String, dynamic>> userAppointments = allAppointments
          .where((appointment) => appointment["assignedUserId"] == userId)
          .toList();
      
      print("✅ Found ${userAppointments.length} appointments assigned to user $userId");
      return userAppointments;
    } catch (e) {
      print("❌ Error fetching user appointments: $e");
      return [];
    }
  }

  /// Fetches detailed info for a single appointment by its ID.
  Future<Map<String, dynamic>?> fetchAppointmentDetails(String appointmentId) async {
    final crmBaseUrl = await _getCRMBaseUrl();
    final authToken = await _getAuthToken();

    if (crmBaseUrl == null || appointmentId.isEmpty || authToken == null) {
      print("⛔ CRM Base URL, Appointment ID, or Auth Token is missing.");
      return null;
    }

    final url = Uri.parse("$crmBaseUrl/api/v1/CSplicingWork/$appointmentId");
    final headers = {
      'Authorization': 'Basic $authToken',
      'X-Api-Key': apiKey,
    };

    try {
      print("🔄 Fetching details for appointment ID: $appointmentId");
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
        print("✅ Appointment Details Fetched for $appointmentId");
        return jsonResponse;
      } else {
        print("❌ Error fetching appointment details: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ Exception fetching appointment details: $e");
      return null;
    }
  }

  /// Updates the status field of an appointment record.
  Future<bool> updateAppointmentStatus(String appointmentId, String newStatus) async {
    final crmBaseUrl = await _getCRMBaseUrl();
    final authToken = await _getAuthToken();

    if (crmBaseUrl == null || appointmentId.isEmpty || authToken == null) {
      print("⛔ CRM Base URL, Appointment ID, or Auth Token is missing.");
      return false;
    }

    final url = Uri.parse("$crmBaseUrl/api/v1/CSplicingWork/$appointmentId");
    final headers = {
      'Authorization': 'Basic $authToken',
      'X-Api-Key': apiKey,
      'Content-Type': 'application/json',
    };

    final body = json.encode({"status": newStatus});

    try {
      print("🔄 Updating status for appointment ID: $appointmentId to $newStatus");
      final response = await http.patch(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        print("✅ Status updated successfully!");
        return true;
      } else {
        print("❌ Error updating status: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("❌ Exception updating status: $e");
      return false;
    }
  }

  /// Submits closure data for an appointment to EspoCRM.
  Future<bool> submitClosure(String appointmentId, Map<String, dynamic> data) async {
    final crmBaseUrl = await _getCRMBaseUrl();
    final authToken = await _getAuthToken();
    
    // Get the technician information from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final technicianId = prefs.getString('userId');
    final technicianName = prefs.getString('userName'); // Get the stored user name
    
    if (crmBaseUrl == null || appointmentId.isEmpty || authToken == null) {
      print("⛔ CRM Base URL, Appointment ID, or Auth Token is missing.");
      return false;
    }

    // Add detailed logs showing the technician who's making the changes
    print("👤 Technician making changes: $technicianName (ID: $technicianId)");
    
    // Try multiple common field names for user attribution in CRM systems
    // We'll include several options - your system might use one of these
    if (technicianId != null) {
      // Common field names - your CRM might use one or more of these
      data['modifiedById'] = technicianId;       // Who modified the record
      data['assignedUserId'] = technicianId;     // Who is assigned to the task
      data['updatedById'] = technicianId;        // Who updated the record
      data['userId'] = technicianId;             // Generic user ID field
      data['responsibleUserId'] = technicianId;  // Who is responsible for the record
      data['executedById'] = technicianId;       // Who executed the task
      
      // Some CRM systems might also want the username in a separate field
      if (technicianName != null) {
        data['modifiedByName'] = technicianName;
        data['executedByName'] = technicianName;
        data['technicianName'] = technicianName;
      }
    }

    final url = Uri.parse("$crmBaseUrl/api/v1/CSplicingWork/$appointmentId");
    final headers = {
      'Authorization': 'Basic $authToken',
      'Content-Type': 'application/json',
    };

    try {
      print("🔄 Submitting closure data for appointment ID: $appointmentId");
      print("📝 Full data payload: ${json.encode(data)}");
      final response = await http.patch(url, headers: headers, body: json.encode(data));

      if (response.statusCode == 200) {
        print("✅ Closure data submitted successfully by technician: $technicianName!");
        
        // Try to parse the response to see what the server accepted
        try {
          final responseBody = json.decode(response.body);
          print("📄 Server response: $responseBody");
          // This might show you which fields the server actually used
        } catch (e) {
          // Just continue if we can't parse the response
        }
        
        return true;
      } else {
        print("❌ Error submitting closure data: ${response.statusCode}");
        print("❌ Response body: ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Exception submitting closure data: $e");
      throw e;
    }
  }

  /// Uploads an attachment file and returns the new attachment ID.
  Future<String?> uploadAttachment({
    required String appointmentId,
    required String fileName,
    required String mimeType,
    required String base64FileContent,
    String field = "tobebuilt", // Added field parameter with default value
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
      "parentType": "CSplicingWork",
      "field": field, // Use the field parameter instead of hardcoding "tobebuilt"
      "file": "data:$mimeType;base64,$base64FileContent"
    };

    try {
      print("🔄 Uploading attachment with payload: $payload");
      final response = await http.post(url, headers: headers, body: json.encode(payload));
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print("✅ Attachment uploaded successfully with id: ${jsonResponse['id']}");
        return jsonResponse['id'];
      } else {
        print("❌ Error uploading attachment: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ Exception uploading attachment: $e");
      return null;
    }
  }

  Future<List<dynamic>?> fetchAppointmentAttachments(String appointmentId) async {
    final crmBaseUrl = await _getCRMBaseUrl();
    final authToken = await _getAuthToken();

    if (crmBaseUrl == null || appointmentId.isEmpty || authToken == null) {
      print("⛔ CRM Base URL, Appointment ID, or Auth Token is missing.");
      return null;
    }

    final url = Uri.parse("$crmBaseUrl/api/v1/CSplicingWork/$appointmentId/attachmentfb");
    final headers = {
      'Authorization': 'Basic $authToken',
      'X-Api-Key': apiKey,
    };

    try {
      print("🔄 Fetching attachments for appointment ID: $appointmentId");
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print("✅ Attachments fetched successfully for appointment ID: $appointmentId");
        return jsonResponse is List ? jsonResponse : [jsonResponse];
      } else {
        print("❌ Error fetching appointment attachments: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ Exception fetching appointment attachments: $e");
      return null;
    }
  }
}