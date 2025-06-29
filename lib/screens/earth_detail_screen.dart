// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

import '../services/earth_work_service.dart';
import 'earth_closure_screen.dart';

enum DetailScreenState {
  loading,
  loaded,
  error,
}

class EarthDetailScreen extends StatefulWidget {
  final String appointmentId;

  const EarthDetailScreen({
    super.key,
    required this.appointmentId,
  });

  @override
  _EarthDetailScreenState createState() => _EarthDetailScreenState();
}

class _EarthDetailScreenState extends State<EarthDetailScreen> {
  DetailScreenState _screenState = DetailScreenState.loading;
  Map<String, dynamic>? appointmentDetails;
  String? selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _screenState = DetailScreenState.loading;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString("earthAppointment_${widget.appointmentId}");
      if (cachedJson != null) {
        appointmentDetails = json.decode(cachedJson);
        selectedStatus = appointmentDetails?["status"];
      }

      final earthService = EarthWorkService();
      final fetchedDetails = await earthService.fetchAppointmentDetails(widget.appointmentId);

      if (fetchedDetails != null) {
        prefs.setString("earthAppointment_${widget.appointmentId}", json.encode(fetchedDetails));
        appointmentDetails = fetchedDetails;
        selectedStatus = fetchedDetails["status"];
      }

      if (appointmentDetails == null) {
        setState(() {
          _screenState = DetailScreenState.error;
        });
        return;
      }

      setState(() {
        _screenState = DetailScreenState.loaded;
      });
    } catch (e) {
      setState(() {
        _screenState = DetailScreenState.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_screenState) {
      case DetailScreenState.loading:
        return Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
            ),
          ),
        );

      case DetailScreenState.error:
        return Scaffold(
          appBar: AppBar(
            title: const Text("Σφάλμα"),
            backgroundColor: Colors.black87,
            elevation: 4,
            titleTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Αποτυχία φόρτωσης λεπτομερειών εργασίας χωματουργικών.",
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 2,
                  ),
                  child: const Text("Προσπάθεια ξανά", style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        );

      case DetailScreenState.loaded:
        return Scaffold(
          appBar: AppBar(
            title: Text("Χωματουργικά ${appointmentDetails?["sr"] ?? "N/A"}"),
            backgroundColor: Colors.black87,
            elevation: 4,
            titleTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          // BODY: Scrollable content
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildSection("Στοιχεία Πελάτη", _buildCustomerInfo()),
                      const SizedBox(height: 24),
                      _buildSection("Στοιχεία Εργασίας", _buildJobInfo()),
                      const SizedBox(height: 24),
                      _buildSection("Χαρακτηριστικά", _buildFeaturesInfo()),
                      const SizedBox(height: 24),
                      _buildSection("Σημειώσεις", _buildNotesInfo()),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // BOTTOM NAVIGATION BAR: Action buttons
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _handleNavigate,
                    icon: const Icon(Icons.navigation, size: 20),
                    label: const Text("Πλοήγηση"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _handleCabNavigate,
                    icon: const Icon(Icons.cable, size: 20),
                    label: const Text("CAB"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _handleStartJob,
                    icon: const Icon(Icons.play_arrow, size: 20),
                    label: const Text("Κλείσιμο"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildHeader() {
    final id = appointmentDetails?["sr"]?.toString() ?? "N/A";
    final status = selectedStatus ?? "N/A";
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "#$id",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getStatusColor(status),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildCustomerInfo() {
    final customerName = appointmentDetails?["clientName"]?.toString() ?? "N/A";
    final customerPhone = appointmentDetails?["adminmobile"]?.toString() ?? "N/A";
    final address = appointmentDetails?["name"]?.toString() ?? "N/A";
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow(Icons.person, "Όνομα", customerName),
        const SizedBox(height: 12),
        _buildPhoneRow(Icons.phone, "Τηλέφωνο", customerPhone),
        const SizedBox(height: 12),
        _buildDetailRow(Icons.location_on, "Διεύθυνση", address),
      ],
    );
  }

  Widget _buildJobInfo() {
    final dateTime = appointmentDetails?["dateStart"]?.toString() ?? "N/A";
    final endTime = appointmentDetails?["dateEnd"]?.toString() ?? "N/A";
    final difficultyLevel = appointmentDetails?["difficultyLevel"]?.toString() ?? "ΕΥΚΟΛΟ";
    
    // Calculate duration in hours and minutes if available
    String duration = "N/A";
    final durationSeconds = appointmentDetails?["duration"];
    if (durationSeconds != null && durationSeconds is num) {
      final hours = (durationSeconds / 3600).floor();
      final minutes = ((durationSeconds % 3600) / 60).floor();
      duration = "${hours}h ${minutes}m";
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow(Icons.access_time, "Έναρξη", _formatDateTime(dateTime)),
        const SizedBox(height: 12),
        _buildDetailRow(Icons.access_time_filled, "Λήξη", _formatDateTime(endTime)),
        const SizedBox(height: 12),
        _buildDetailRow(Icons.timelapse, "Διάρκεια", duration),
        const SizedBox(height: 12),
        _buildDetailRow(Icons.trending_up, "Επίπεδο Δυσκολίας", difficultyLevel),
      ],
    );
  }

  Widget _buildFeaturesInfo() {
    final hasEmfyshsh = appointmentDetails?["emfyshsh"] == "ΝΑΙ";
    final typosPlakas = appointmentDetails?["typosPlakas"]?.toString() ?? "N/A";
    final megethosPlakas = appointmentDetails?["megethosPlakas"]?.toString() ?? "N/A";
    final mikosChwma = appointmentDetails?["mikosChwma"]?.toString() ?? "N/A";
    final hasGarden = appointmentDetails?["garden"] == "ΝΑΙ";
    final hasSkapsimo = appointmentDetails?["skapsimo"] == "ΝΑΙ";
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFeatureRow("Εμφύσηση", hasEmfyshsh),
        const SizedBox(height: 8),
        _buildDetailRow(Icons.dashboard, "Τύπος Πλάκας", typosPlakas),
        const SizedBox(height: 8),
        _buildDetailRow(Icons.straighten, "Μέγεθος Πλάκας", megethosPlakas),
        const SizedBox(height: 8),
        _buildDetailRow(Icons.format_line_spacing, "Μήκος Χώματος", "$mikosChwma μέτρα"),
        const SizedBox(height: 8),
        _buildFeatureRow("Κήπος", hasGarden),
        const SizedBox(height: 8),
        _buildFeatureRow("Σκάψιμο", hasSkapsimo),
      ],
    );
  }

  Widget _buildFeatureRow(String label, bool isPresent) {
    return Row(
      children: [
        Icon(
          isPresent ? Icons.check_circle : Icons.cancel,
          size: 20,
          color: isPresent ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isPresent ? Colors.black87 : Colors.black54,
            fontWeight: isPresent ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildNotesInfo() {
    final notes = appointmentDetails?["description"]?.toString() ?? "";
    // ignore: curly_braces_in_flow_control_structures
    if (notes.isEmpty) return const Text(
      "Δεν υπάρχουν σημειώσεις",
      style: TextStyle(fontSize: 14, color: Colors.grey),
    );
    
    return Text(
      notes,
      style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    if (value == "N/A" || value.isEmpty) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black54),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneRow(IconData icon, String label, String phoneNumber) {
    if (phoneNumber == "N/A" || phoneNumber.isEmpty) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black54),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => _makePhoneCall(phoneNumber),
            child: Text(
              phoneNumber,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return "${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return dateTimeStr;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "Σε εξέλιξη":
        return const Color(0xFF0066CC);
      case "Ολοκληρώθηκε":
      case "ΟΛΟΚΛΗΡΩΣΗ":
        return const Color(0xFF4CAF50);
      case "Σε αναμονή":
      case "ΑΠΟΣΤΟΛΗ":
        return const Color(0xFFFF9800);
      case "ΜΗ ΟΛΟΚΛΗΡΩΣΗ":
      case "ΑΠΟΡΡΙΨΗ":
        return Colors.red;
      case "ΝΕΟ":
        return Colors.purple;
      default:
        return const Color(0xFF666666);
    }
  }

  void _handleNavigate() async {
    final mapsUrl = appointmentDetails?["mapsurl"]?.toString() ?? "";
    if (mapsUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Δεν υπάρχει διαθέσιμη τοποθεσία χάρτη")),
      );
      return;
    }

    final coords = _extractCoordinates(mapsUrl);
    if (coords == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Μη έγκυρη διεύθυνση χάρτη")),
      );
      return;
    }

    final latitude = coords['latitude']!;
    final longitude = coords['longitude']!;

    final googleNavigationUri = Uri.parse("google.navigation:q=$latitude,$longitude&mode=d");
    final geoUri = Uri.parse("geo:$latitude,$longitude?q=$latitude,$longitude");
    final webFallbackUri = Uri.parse("https://www.google.com/maps/search/?api=1&query=$latitude,$longitude");

    if (await canLaunchUrl(googleNavigationUri)) {
      await launchUrl(googleNavigationUri, mode: LaunchMode.externalApplication);
      return;
    }
    if (await canLaunchUrl(geoUri)) {
      await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      return;
    }
    if (await canLaunchUrl(webFallbackUri)) {
      await launchUrl(webFallbackUri, mode: LaunchMode.platformDefault);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Δεν μπορεί να ανοίξει ο χάρτης")),
    );
  }
  
  void _handleCabNavigate() async {
    final cabAddress = appointmentDetails?["cabAddress"]?.toString() ?? "";
    if (cabAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Δεν υπάρχει διαθέσιμη τοποθεσία CAB")),
      );
      return;
    }

    final coords = _extractCoordinates(cabAddress);
    if (coords == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Μη έγκυρη διεύθυνση CAB")),
      );
      return;
    }

    final latitude = coords['latitude']!;
    final longitude = coords['longitude']!;

    final googleNavigationUri = Uri.parse("google.navigation:q=$latitude,$longitude&mode=d");
    final geoUri = Uri.parse("geo:$latitude,$longitude?q=$latitude,$longitude");
    final webFallbackUri = Uri.parse("https://www.google.com/maps/search/?api=1&query=$latitude,$longitude");

    if (await canLaunchUrl(googleNavigationUri)) {
      await launchUrl(googleNavigationUri, mode: LaunchMode.externalApplication);
      return;
    }
    if (await canLaunchUrl(geoUri)) {
      await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      return;
    }
    if (await canLaunchUrl(webFallbackUri)) {
      await launchUrl(webFallbackUri, mode: LaunchMode.platformDefault);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Δεν μπορεί να ανοίξει ο χάρτης CAB")),
    );
  }

  Map<String, double>? _extractCoordinates(String mapsUrl) {
    try {
      final regex = RegExp(r'q=([-]?\d+\.\d+),([-]?\d+\.\d+)');
      final match = regex.firstMatch(mapsUrl);
      if (match != null) {
        final latitude = double.parse(match.group(1)!);
        final longitude = double.parse(match.group(2)!);
        return {'latitude': latitude, 'longitude': longitude};
      }
    // ignore: empty_catches
    } catch (e) {
    }
    return null;
  }

  void _handleStartJob() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EarthClosureScreen(appointmentId: widget.appointmentId),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber == "N/A" || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Δεν υπάρχει διαθέσιμος αριθμός τηλεφώνου")),
      );
      return;
    }

    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Δεν μπορεί να ξεκινήσει η κλήση")),
      );
    }
  }
}