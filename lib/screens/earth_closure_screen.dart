import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import '../services/earth_work_service.dart';

class EarthClosureScreen extends StatefulWidget {
  final String appointmentId;

  const EarthClosureScreen({super.key, required this.appointmentId});

  @override
  _EarthClosureScreenState createState() => _EarthClosureScreenState();
}

class _EarthClosureScreenState extends State<EarthClosureScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _status;
  String? _emfyshsh;
  String? _skapsimo;
  String? _difficultyLevel;
  bool _isLoading = true;

  // Dropdown options
  final List<String> _statusOptions = ['ΑΠΟΣΤΟΛΗ', 'ΟΛΟΚΛΗΡΩΣΗ', 'ΜΗ ΟΛΟΚΛΗΡΩΣΗ', 'ΑΠΟΡΡΙΨΗ'];
  final List<String> _booleanOptions = ['', 'ΝΑΙ', 'ΟΧΙ'];
  final List<String> _difficultyOptions = ['', 'ΕΥΚΟΛΟ', 'ΜΕΤΡΙΟ', 'ΔΥΣΚΟΛΟ'];

  // For attachments
  Map<String, String> _existingAttachments = {};
  Uint8List? _newAttachmentBytes;
  String? _newAttachmentFileName;
  String? _newAttachmentMime;
  
  // Text field controllers
  final TextEditingController _mikosChwmaController = TextEditingController(text: "0");

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }
  
  @override
  void dispose() {
    _mikosChwmaController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final appointmentDetails = await EarthWorkService().fetchAppointmentDetails(widget.appointmentId);
      if (appointmentDetails != null) {
        setState(() {
          _status = appointmentDetails['status']?.toString();
          _emfyshsh = appointmentDetails['emfyshsh']?.toString();
          _skapsimo = appointmentDetails['skapsimo']?.toString();
          _difficultyLevel = appointmentDetails['difficultyLevel']?.toString();
          
          // Set mikosChwma value
          final mikosChwma = appointmentDetails['mikosChwma'];
          if (mikosChwma != null) {
            _mikosChwmaController.text = mikosChwma.toString();
          }
          
          // Get photo attachments
          if (appointmentDetails['photoAttachments'] != null) {
            _existingAttachments = Map<String, String>.from(appointmentDetails['photoAttachments']);
          }
          
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Αποτυχία φόρτωσης δεδομένων")),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("❌ Exception fetching initial data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Αποτυχία φόρτωσης δεδομένων")),
      );
    }
  }

  Future<void> _pickAttachment() async {
    // Show a dialog to let the user choose the source
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Επιλέξτε πηγή"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, ImageSource.camera),
              child: const Text("Κάμερα"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, ImageSource.gallery),
              child: const Text("Συλλογή"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, null), // Use null for file picker
              child: const Text("Άλλο Αρχείο"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Ακύρωση"),
            ),
          ],
        );
      },
    );

    // If the user cancels the dialog or selects file picker
    if (source == null) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(withData: true);
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        String? mimeType = lookupMimeType(file.name) ?? "application/octet-stream";
        setState(() {
          _newAttachmentBytes = file.bytes;
          _newAttachmentFileName = file.name;
          _newAttachmentMime = mimeType;
        });
      }
      return;
    }

    // Handle camera or gallery selection using image_picker
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      final Uint8List imageBytes = await image.readAsBytes();
      String? mimeType = lookupMimeType(image.name) ?? "image/jpeg";
      setState(() {
        _newAttachmentBytes = imageBytes;
        _newAttachmentFileName = image.name;
        _newAttachmentMime = mimeType;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Additional validation for required fields when status is 'ΟΛΟΚΛΗΡΩΣΗ'
      if (_status == 'ΟΛΟΚΛΗΡΩΣΗ' &&
          (_emfyshsh == null || _emfyshsh!.isEmpty || _emfyshsh == '' ||
              _skapsimo == null || _skapsimo!.isEmpty || _skapsimo == '' ||
              _difficultyLevel == null || _difficultyLevel!.isEmpty || _difficultyLevel == '')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Όλα τα πεδία είναι υποχρεωτικά για την κατάσταση 'ΟΛΟΚΛΗΡΩΣΗ'")),
        );
        return;
      }

      // Check connectivity status
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        // Offline: Save to Hive
        var box = Hive.box('pendingActions');
        await box.add({
          'type': 'earthClosure',
          'appointmentId': widget.appointmentId,
          'data': {
            "status": _status,
            if (_status == 'ΟΛΟΚΛΗΡΩΣΗ') ...{
              "emfyshsh": _emfyshsh,
              "skapsimo": _skapsimo,
              "difficultyLevel": _difficultyLevel,
              "mikosChwma": int.tryParse(_mikosChwmaController.text) ?? 0,
            },
          },
          'attachment': _newAttachmentBytes != null
              ? {
                  'bytes': _newAttachmentBytes,
                  'fileName': _newAttachmentFileName,
                  'mime': _newAttachmentMime,
                }
              : null,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Αποθηκεύτηκε χωρίς σύνδεση. Θα συγχρονιστεί όταν είστε συνδεδεμένοι.")),
        );
        Navigator.pop(context);
      } else {
        // Online: Proceed with original submission
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              content: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: const Text(
                      "Η εργασία κλείνει, παρακαλώ περιμένετε...",
                      style: TextStyle(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
        );

        final Map<String, dynamic> data = {
          "status": _status,
          if (_status == 'ΟΛΟΚΛΗΡΩΣΗ') ...{
            "emfyshsh": _emfyshsh,
            "skapsimo": _skapsimo,
            "difficultyLevel": _difficultyLevel,
            "mikosChwma": int.tryParse(_mikosChwmaController.text) ?? 0,
          },
        };

        if (_status == 'ΟΛΟΚΛΗΡΩΣΗ' && _newAttachmentBytes != null && _newAttachmentFileName != null && _newAttachmentMime != null) {
          String base64File = base64Encode(_newAttachmentBytes!);
          String? newAttachmentId = await EarthWorkService().uploadAttachment(
            appointmentId: widget.appointmentId,
            fileName: _newAttachmentFileName!,
            mimeType: _newAttachmentMime!,
            base64FileContent: base64File,
          );
          if (newAttachmentId != null) {
            List<String> attachmentIds = [];
            if (_existingAttachments.isNotEmpty) {
              attachmentIds.addAll(_existingAttachments.keys);
            }
            attachmentIds.add(newAttachmentId);
            data["photosIds"] = attachmentIds;
          } else {
            Navigator.of(context, rootNavigator: true).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Αποτυχία αποστολής επισύναψης")),
            );
            return;
          }
        }

        final success = await EarthWorkService().submitClosure(widget.appointmentId, data);

        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }

        if (success && mounted) {
          Navigator.pop(context);
          Future.microtask(() {
            Navigator.pop(context, true);
          });
        } else if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Σφάλμα"),
                content: const Text("Αποτυχία κλεισίματος εργασίας"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("OK"),
                  ),
                ],
              );
            },
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Κλείσιμο Εργασίας Χωματουργικών"),
        backgroundColor: Colors.black87,
        elevation: 4,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 2,
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              child: const Text("Υποβολή"),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "ID Εργασίας: ${widget.appointmentId}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildDropdownField(
                      label: "Κατάσταση",
                      value: _statusOptions.contains(_status) ? _status : null,
                      items: _statusOptions,
                      onChanged: (newValue) => setState(() => _status = newValue),
                      validator: (value) => value == null || value.isEmpty
                          ? "Παρακαλώ επιλέξτε κατάσταση"
                          : null,
                    ),
                    if (_status == 'ΟΛΟΚΛΗΡΩΣΗ') ...[
                      const SizedBox(height: 20),
                      _buildDropdownField(
                        label: "Επίπεδο Δυσκολίας",
                        value: _difficultyOptions.contains(_difficultyLevel) ? _difficultyLevel : null,
                        items: _difficultyOptions,
                        onChanged: (newValue) => setState(() => _difficultyLevel = newValue),
                        validator: (value) => value == null
                            ? "Παρακαλώ επιλέξτε επίπεδο δυσκολίας"
                            : null,
                      ),
                      const SizedBox(height: 20),
                      _buildDropdownField(
                        label: "Εμφύσηση",
                        value: _booleanOptions.contains(_emfyshsh) ? _emfyshsh : null,
                        items: _booleanOptions,
                        onChanged: (newValue) => setState(() => _emfyshsh = newValue),
                        validator: (value) => value == null
                            ? "Παρακαλώ επιλέξτε αν έγινε εμφύσηση"
                            : null,
                      ),
                      const SizedBox(height: 20),
                      _buildDropdownField(
                        label: "Σκάψιμο",
                        value: _booleanOptions.contains(_skapsimo) ? _skapsimo : null,
                        items: _booleanOptions,
                        onChanged: (newValue) => setState(() => _skapsimo = newValue),
                        validator: (value) => value == null
                            ? "Παρακαλώ επιλέξτε αν έγινε σκάψιμο"
                            : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _mikosChwmaController,
                        decoration: InputDecoration(
                          labelText: "Μήκος Χώματος (μέτρα)",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.black87, width: 1.5),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Παρακαλώ εισάγετε μήκος χώματος";
                          }
                          final number = int.tryParse(value);
                          if (number == null) {
                            return "Παρακαλώ εισάγετε έναν έγκυρο αριθμό";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Επισύναψη Φωτογραφιών",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildAttachmentsSection(),
                      const SizedBox(height: 16),
                      _buildAttachmentButton(),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required String? Function(String?) validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.black87, width: 1.5),
        ),
      ),
      items: items.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value.isEmpty ? "Κενό" : value),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildAttachmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_existingAttachments.isNotEmpty)
          ..._existingAttachments.values.map(
            (fileName) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  const Icon(Icons.photo, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(child: Text(fileName, style: const TextStyle(fontSize: 14))),
                ],
              ),
            ),
          )
        else
          const Text(
            "Δεν υπάρχουν επισυναπτόμενες φωτογραφίες.",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        if (_newAttachmentFileName != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.add_circle_outline, size: 18, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Νέα φωτογραφία: $_newAttachmentFileName",
                  style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.blue),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAttachmentButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _pickAttachment,
        icon: const Icon(Icons.camera_alt, size: 20),
        label: const Text("Προσθήκη Φωτογραφίας"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 2,
        ),
      ),
    );
  }
}