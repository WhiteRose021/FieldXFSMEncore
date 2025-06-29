// lib/screens/earth_closure_screen.dart - Fixed version
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:typed_data';

class EarthClosureScreen extends StatefulWidget {
  const EarthClosureScreen({super.key});

  @override
  State<EarthClosureScreen> createState() => _EarthClosureScreenState();
}

class _EarthClosureScreenState extends State<EarthClosureScreen> {
  // Form key for validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Text controllers
  final TextEditingController _mikosChwmaController = TextEditingController();

  // State variables
  bool _isLoading = false;
  String _status = 'pending';
  String _emfyshsh = '';
  String _skapsimo = '';
  String _difficultyLevel = 'easy';

  // Attachment variables
  final List<Map<String, dynamic>> _existingAttachments = [];
  Uint8List? _newAttachmentBytes;
  String? _newAttachmentFileName;
  String? _newAttachmentMime;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    _mikosChwmaController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    // Initialize form with default values or load existing data
    // You can add any initialization logic here
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        _showErrorMessage('No internet connection');
        return;
      }

      // Collect form data
      final formData = {
        'status': _status,
        'emfyshsh': _emfyshsh,
        'skapsimo': _skapsimo,
        'difficulty_level': _difficultyLevel,
        'mikos_chwma': _mikosChwmaController.text,
      };

      // Add attachments if any
      if (_newAttachmentBytes != null) {
        formData['attachment'] = {
          'data': _newAttachmentBytes,
          'filename': _newAttachmentFileName,
          'mime_type': _newAttachmentMime,
        } as String;
      }

      // Submit the form data
      await _submitToServer(formData);

      // Show success message
      _showSuccessMessage('Earth closure submitted successfully');

      // Navigate back or reset form
      if (mounted) {
        Navigator.pop(context);
      }

    } catch (e) {
      _showErrorMessage('Failed to submit: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submitToServer(Map<String, dynamic> formData) async {
    // This is a placeholder - replace with actual API call
    await Future.delayed(const Duration(seconds: 2));
    
    // Simulate success/failure
    // throw Exception('Simulated error');
  }

  void _showSuccessMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Earth Closure'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status dropdown
            _buildStatusDropdown(),
            const SizedBox(height: 16),

            // Emfyshsh field
            _buildEmfyshshField(),
            const SizedBox(height: 16),

            // Skapsimo field
            _buildSkapsimoField(),
            const SizedBox(height: 16),

            // Difficulty level dropdown
            _buildDifficultyLevelDropdown(),
            const SizedBox(height: 16),

            // Mikos Chwma field
            _buildMikosChwmaField(),
            const SizedBox(height: 16),

            // Attachments section
            _buildAttachmentsSection(),
            const SizedBox(height: 24),

            // Submit button
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _status,
      decoration: const InputDecoration(
        labelText: 'Status',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'pending', child: Text('Pending')),
        DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
        DropdownMenuItem(value: 'completed', child: Text('Completed')),
        DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
      ],
      onChanged: (value) {
        setState(() {
          _status = value!;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a status';
        }
        return null;
      },
    );
  }

  Widget _buildEmfyshshField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Emfyshsh',
        border: OutlineInputBorder(),
      ),
      onChanged: (value) {
        setState(() {
          _emfyshsh = value;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter emfyshsh value';
        }
        return null;
      },
    );
  }

  Widget _buildSkapsimoField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Skapsimo',
        border: OutlineInputBorder(),
      ),
      onChanged: (value) {
        setState(() {
          _skapsimo = value;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter skapsimo value';
        }
        return null;
      },
    );
  }

  Widget _buildDifficultyLevelDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _difficultyLevel,
      decoration: const InputDecoration(
        labelText: 'Difficulty Level',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'easy', child: Text('Easy')),
        DropdownMenuItem(value: 'medium', child: Text('Medium')),
        DropdownMenuItem(value: 'hard', child: Text('Hard')),
        DropdownMenuItem(value: 'very_hard', child: Text('Very Hard')),
      ],
      onChanged: (value) {
        setState(() {
          _difficultyLevel = value!;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select difficulty level';
        }
        return null;
      },
    );
  }

  Widget _buildMikosChwmaField() {
    return TextFormField(
      controller: _mikosChwmaController,
      decoration: const InputDecoration(
        labelText: 'Mikos Chwma',
        border: OutlineInputBorder(),
        suffixText: 'cm',
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter mikos chwma value';
        }
        final number = double.tryParse(value);
        if (number == null) {
          return 'Please enter a valid number';
        }
        return null;
      },
    );
  }

  Widget _buildAttachmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attachments',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        
        // Existing attachments
        if (_existingAttachments.isNotEmpty) ...[
          const Text('Existing attachments:'),
          ..._existingAttachments.map((attachment) => ListTile(
            leading: const Icon(Icons.attachment),
            title: Text(attachment['name'] ?? 'Unknown'),
            subtitle: Text(attachment['type'] ?? ''),
          )),
          const SizedBox(height: 8),
        ],

        // Add new attachment button
        ElevatedButton.icon(
          onPressed: _pickAttachment,
          icon: const Icon(Icons.add),
          label: const Text('Add Attachment'),
        ),

        // Show selected attachment
        if (_newAttachmentFileName != null) ...[
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.attachment),
              title: Text(_newAttachmentFileName!),
              subtitle: Text(_newAttachmentMime ?? 'Unknown type'),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  setState(() {
                    _newAttachmentBytes = null;
                    _newAttachmentFileName = null;
                    _newAttachmentMime = null;
                  });
                },
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
            ? const CircularProgressIndicator()
            : const Text('Submit Earth Closure'),
      ),
    );
  }

  Future<void> _pickAttachment() async {
    // This is a placeholder - you would use a package like file_picker
    // to actually pick files from the device
    
    // For now, just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File picker not implemented yet'),
      ),
    );
  }
}