import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fieldx_fsm/services/enhanced_service_adapters.dart';

class AsBuiltScreen extends StatefulWidget {
  final String appointmentId;
  final bool isBuildingMode; // Add this parameter to distinguish between appointment and building

  const AsBuiltScreen({
    Key? key, 
    required this.appointmentId,
    this.isBuildingMode = false, // Default to appointment mode for backward compatibility
  }) : super(key: key);

  @override
  _AsBuiltScreenState createState() => _AsBuiltScreenState();
}

class _AsBuiltScreenState extends State<AsBuiltScreen> {
  Map<String, dynamic>? asBuiltData;
  bool isLoading = true;
  bool hasError = false;
  bool isOffline = false;
  static const String _apiKey = "5af9459182c0ae4e1606e5d65864df25";
  
  // Consistent null message
  static const String _noDataMessage = "Δεν υπάρχουν δεδομένα στο CRM";

  @override
  void initState() {
    super.initState();
    _fetchAsBuiltData();
  }

  Future<String?> _getCRMBaseUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedUrl = prefs.getString('crmDomain');
    
    if (storedUrl == null || storedUrl.isEmpty) {
      return null;
    }
    
    // Ensure HTTP protocol 
    if (storedUrl.startsWith('https://')) {
      storedUrl = storedUrl.replaceFirst('https://', 'http://');
    }
    
    return storedUrl;
  }

  Future<void> _fetchAsBuiltData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Check all possible cache keys for this data
      SharedPreferences prefs = await SharedPreferences.getInstance();
      Map<String, dynamic>? cachedDetails;
      bool dataLoaded = false;
      
      // Try different possible cache keys based on mode
      final List<String> possibleKeys;
      if (widget.isBuildingMode) {
        possibleKeys = [
          'building_details_${widget.appointmentId}',
          'building_${widget.appointmentId}',
          'cached_building_${widget.appointmentId}'
        ];
      } else {
        possibleKeys = [
          'appointment_details_${widget.appointmentId}',
          'appointment_${widget.appointmentId}',
          'cached_appointment_${widget.appointmentId}'
        ];
      }
      
      for (final key in possibleKeys) {
        final cachedDataString = prefs.getString(key);
        if (cachedDataString != null) {
          print("📦 Found cached data using key: $key");
          try {
            cachedDetails = json.decode(cachedDataString) as Map<String, dynamic>;
            break; // Found valid data, exit loop
          } catch (e) {
            print("⚠️ Error parsing cached data: $e");
          }
        }
      }
      
      // If we have cached data, use it
      if (cachedDetails != null) {
        print("📋 Using cached details for ${widget.isBuildingMode ? 'building' : 'appointment'} ${widget.appointmentId}");
        setState(() {
          asBuiltData = cachedDetails;
          dataLoaded = true;
        });
      }

      // Perform a real network check by trying a quick fetch
      bool isNetworkReachable = false;
      try {
        // Attempt to reach the server with a 3-second timeout
        final String? crmBaseUrl = await _getCRMBaseUrl();
        if (crmBaseUrl != null) {
          final testUrl = Uri.parse("$crmBaseUrl/api/v1/ping");
          await http.get(testUrl, headers: {'X-Api-Key': _apiKey}).timeout(
            const Duration(seconds: 3),
            onTimeout: () => throw TimeoutException('Network test timed out'),
          );
          isNetworkReachable = true;
        }
      } catch (e) {
        print("🔌 Network connectivity test failed: $e");
        isNetworkReachable = false;
      }
      
      setState(() {
        isOffline = !isNetworkReachable;
      });
      
      if (!isNetworkReachable) {
        // We're definitely offline
        setState(() => isLoading = false);
        if (!dataLoaded) {
          setState(() => hasError = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Εκτός σύνδεσης - δεν υπάρχουν αποθηκευμένα δεδομένα AsBuilt"),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Εκτός σύνδεσης - φορτώθηκαν αποθηκευμένα δεδομένα AsBuilt"),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // We're online - try to fetch fresh data
      print("🌐 Online - fetching fresh AsBuilt details");
      try {
        Map<String, dynamic>? freshDetails;
        
        // Use the appropriate service based on mode
        if (widget.isBuildingMode) {
          final service = CSplicingWorkService();
          freshDetails = await service.fetchBuildingDetails(widget.appointmentId);
        } else {
          final service = AppointmentService();
          freshDetails = await service.fetchAppointmentDetails(widget.appointmentId);
        }
        
        if (freshDetails != null) {
          // Cache the fresh data for future offline use
          final cacheKey = widget.isBuildingMode 
              ? 'building_${widget.appointmentId}' 
              : 'appointment_${widget.appointmentId}';
          await prefs.setString(cacheKey, json.encode(freshDetails));
          
          setState(() {
            asBuiltData = freshDetails;
            isLoading = false;
          });
        } else if (!dataLoaded) {
          // Only show error if we couldn't load from cache either
          setState(() {
            hasError = true;
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Αποτυχία φόρτωσης δεδομένων AsBuilt")),
          );
        } else {
          setState(() => isLoading = false);
        }
      } catch (e) {
        print("❌ Error fetching fresh AsBuilt data: $e");
        if (!dataLoaded) {
          setState(() {
            hasError = true;
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Αποτυχία σύνδεσης στον server")),
          );
        } else {
          setState(() => isLoading = false);
        }
      }
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
      print("❌ Exception in _fetchAsBuiltData: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Σφάλμα: ${e.toString()}")),
      );
    }
  }

  // Helper method to safely get string value with null check
  String _getSafeValue(String? key) {
    if (asBuiltData == null || key == null) return _noDataMessage;
    
    final value = asBuiltData![key];
    if (value == null || value.toString().trim().isEmpty || value.toString().toLowerCase() == 'null') {
      return _noDataMessage;
    }
    
    return value.toString();
  }

  // Helper: Label-Value row for General Information.
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: value == _noDataMessage ? Colors.red.shade600 : null,
                fontStyle: value == _noDataMessage ? FontStyle.italic : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper: Section card with a title.
  Widget _buildSection(String title, Widget content) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            content,
          ],
        ),
      ),
    );
  }

  /// Cleans the raw floors text by removing repeated keywords and ensuring one cell per row.
  List<List<String>> _parseFloorsText(String? raw) {
    if (raw == null || raw.trim().isEmpty || raw.toLowerCase() == "null" || raw == "Δεν υπάρχουν δεδομένα στο CRM") {
      return [[_noDataMessage]]; // Return one row with one cell
    }
    
    final lines = raw.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    final List<List<String>> data = [];
    
    for (var line in lines) {
      var cleaned = line
          .replaceAll('ΟΡΟΦΟΣ:', '')
          .replaceAll('ΔΙΑΜΕΡΙΣΜΑΤΑ:', '')
          .replaceAll('ΚΑΤΑΣΤΗΜΑΤΑ:', '')
          .replaceAll('ΑΡΙΘΜΗΣΗ ΧΩΡΟΥ ΠΕΛΑΤΗ:', '')
          .replaceAll('GIS ID:', '')
          .trim();
      
      if (cleaned.isNotEmpty && cleaned.toLowerCase() != 'null') {
        // Join split parts into a single cell
        final cellContent = cleaned.split(RegExp(r'[|]\s*')).map((e) => e.trim()).join(' | ');
        data.add([cellContent]); // Always return exactly one cell per row
      }
    }
    
    return data.isNotEmpty ? data : [[_noDataMessage]];
  }

  /// Cleans the raw optical paths text and ensures one cell per row.
  List<List<String>> _parseOpticalPathsText(String? raw) {
    if (raw == null || raw.trim().isEmpty || raw.toLowerCase() == "null" || raw == "Δεν υπάρχουν δεδομένα στο CRM") {
      return [[_noDataMessage]]; // Return one row with one cell
    }
    
    final lines = raw.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    final List<List<String>> data = [];
    
    for (var line in lines) {
      var cleaned = line
          .replaceAll('OPTICAL PATH TYPE:', '')
          .replaceAll('OPTICAL PATH TYPE', '')
          .replaceAll('OPTICAL PATH:', '')
          .replaceAll('OPTICAL PATH', '')
          .replaceAll('GISID:', '')
          .replaceAll('GISID', '')
          .trim();
      
      if (cleaned.isNotEmpty && cleaned.toLowerCase() != 'null') {
        // Join split parts into a single cell
        final cellContent = cleaned.split(RegExp(r'[|]\s*')).map((e) => e.trim()).join(' | ');
        data.add([cellContent]); // Always return exactly one cell per row
      }
    }
    
    return data.isNotEmpty ? data : [[_noDataMessage]];
  }

  /// Parses HTML table into rows and columns (simplified parsing).
  List<List<String>> _parseHtmlTable(String? html) {
    if (html == null || html.trim().isEmpty || html.toLowerCase() == 'null') {
      return [[_noDataMessage, ""]]; // Return one row with two cells
    }
    
    final List<List<String>> data = [];
    // Simplified parsing: Look for <tr> and <td> tags
    final rows = html.split('</tr>').where((r) => r.contains('<td')).toList();
    
    for (var row in rows) {
      final cells = row.split('</td>').where((c) => c.contains('<td')).map((c) {
        final start = c.indexOf('>') + 1;
        final cellValue = c.substring(start).trim().replaceAll(RegExp(r'<[^>]+>'), '');
        return cellValue.isEmpty || cellValue.toLowerCase() == 'null' ? _noDataMessage : cellValue;
      }).toList();
      
      if (cells.isNotEmpty) {
        // Ensure exactly 2 cells per row for the HTML table
        while (cells.length < 2) {
          cells.add(_noDataMessage); // Pad with no data message if needed
        }
        // Take only the first 2 cells if there are more
        data.add([cells[0], cells.length > 1 ? cells[1] : _noDataMessage]);
      }
    }
    
    return data.isNotEmpty ? data : [[_noDataMessage, ""]];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("AsBuilt Details"),
        backgroundColor: Color(0xFF0066CC),
        elevation: 4,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        actions: [
          if (isOffline)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Icon(Icons.wifi_off, color: Colors.orange),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text("Αποτυχία φόρτωσης δεδομένων AsBuilt."),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchAsBuiltData,
                        child: const Text("Προσπάθεια ξανά"),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Offline notification bar when using cached data
                      if (isOffline)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.wifi_off, color: Colors.orange),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Εκτός σύνδεσης - Προβολή αποθηκευμένων δεδομένων",
                                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // 1) General Information Card
                      _buildSection(
                        "General Information",
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow("CAB DISTANCE", _getSafeValue("tobbapostasticab")),
                            _buildInfoRow("BEP Type", _getSafeValue("tobbbeptype")),
                            _buildInfoRow("BID", _getSafeValue("tobbbid")),
                            _buildInfoRow("BMO Type", _getSafeValue("tobbbmotype")),
                            _buildInfoRow("Conduit", _getSafeValue("tobbconduit")),
                            _buildInfoRow("SR", _getSafeValue("tobbsrid")),
                            _buildInfoRow("Smart Readiness", _getSafeValue("tobbsmart")),
                          ],
                        ),
                      ),
                      
                      // 2) Floors Information Card
                      _buildSection(
                        "Floors Information",
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Floors",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text("Floor Data")),
                                ],
                                rows: _parseFloorsText(_getSafeValue("tobbfloors") == _noDataMessage ? null : asBuiltData!["tobbfloors"]?.toString())
                                    .map((row) => DataRow(
                                          cells: row.map((cell) => DataCell(
                                            Text(
                                              cell,
                                              style: TextStyle(
                                                color: cell == _noDataMessage ? Colors.red.shade600 : null,
                                                fontStyle: cell == _noDataMessage ? FontStyle.italic : null,
                                              ),
                                            ),
                                          )).toList(),
                                        ))
                                    .toList(),
                              ),
                            ),
                            const Divider(height: 24),
                            const Text(
                              "Floors",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text("Column 1")),
                                  DataColumn(label: Text("Column 2")),
                                ],
                                rows: _parseHtmlTable(asBuiltData!["tobbfloors1"]?.toString())
                                    .map((row) => DataRow(
                                          cells: List.generate(
                                              2,
                                              (index) => DataCell(
                                                Text(
                                                  row.length > index ? row[index] : _noDataMessage,
                                                  style: TextStyle(
                                                    color: (row.length > index ? row[index] : _noDataMessage) == _noDataMessage 
                                                        ? Colors.red.shade600 : null,
                                                    fontStyle: (row.length > index ? row[index] : _noDataMessage) == _noDataMessage 
                                                        ? FontStyle.italic : null,
                                                  ),
                                                ),
                                              )),
                                        ))
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // 3) Optical Paths Information Card
                      _buildSection(
                        "Optical Paths",
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Optical Paths",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text("Optical Path Data")),
                                ],
                                rows: _parseOpticalPathsText(_getSafeValue("tobbopticalpaths") == _noDataMessage ? null : asBuiltData!["tobbopticalpaths"]?.toString())
                                    .map((row) => DataRow(
                                          cells: row.map((cell) => DataCell(
                                            Text(
                                              cell,
                                              style: TextStyle(
                                                color: cell == _noDataMessage ? Colors.red.shade600 : null,
                                                fontStyle: cell == _noDataMessage ? FontStyle.italic : null,
                                              ),
                                            ),
                                          )).toList(),
                                        ))
                                    .toList(),
                              ),
                            ),
                            const Divider(height: 24),
                            const Text(
                              "Optical Paths",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text("Column 1")),
                                  DataColumn(label: Text("Column 2")),
                                ],
                                rows: _parseHtmlTable(asBuiltData!["tobbopticalpaths1"]?.toString())
                                    .map((row) => DataRow(
                                          cells: List.generate(
                                              2,
                                              (index) => DataCell(
                                                Text(
                                                  row.length > index ? row[index] : _noDataMessage,
                                                  style: TextStyle(
                                                    color: (row.length > index ? row[index] : _noDataMessage) == _noDataMessage 
                                                        ? Colors.red.shade600 : null,
                                                    fontStyle: (row.length > index ? row[index] : _noDataMessage) == _noDataMessage 
                                                        ? FontStyle.italic : null,
                                                  ),
                                                ),
                                              )),
                                        ))
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}