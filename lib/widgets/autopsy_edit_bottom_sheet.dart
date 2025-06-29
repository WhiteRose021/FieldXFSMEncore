// ignore_for_file: deprecated_member_use

import 'package:fieldx_fsm/models/autopsy_models.dart';
import 'package:fieldx_fsm/repositories/autopsy_repository.dart';
import 'package:fieldx_fsm/services/permissions_manager.dart';
import 'package:fieldx_fsm/utils/error_handler.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AutopsyEditBottomSheet extends StatefulWidget {
  final CAutopsy autopsy;

  const AutopsyEditBottomSheet({
    super.key,
    required this.autopsy,
  });

  @override
  State<AutopsyEditBottomSheet> createState() => _AutopsyEditBottomSheetState();
}

class _AutopsyEditBottomSheetState extends State<AutopsyEditBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, String?> _formData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _formData = {
      'name': widget.autopsy.name,
      'description': widget.autopsy.description,
      'autopsystatus': widget.autopsy.autopsystatus,
      'autopsycomments': widget.autopsy.autopsyComments,
      'technicalcheckstatus': widget.autopsy.technicalCheckStatus,
      'autopsycustomermobile': widget.autopsy.autopsyCustomerMobile,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PermissionsManager>(
      builder: (context, permissions, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Title
                Text(
                  'Edit Autopsy',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                
                // Form fields
                if (permissions.canEditField('name'))
                  TextFormField(
                    initialValue: _formData['name'],
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => _formData['name'] = value,
                  ),
                
                const SizedBox(height: 12),
                
                if (permissions.canEditField('autopsystatus'))
                  Consumer<AutopsyRepository>(
                    builder: (context, repository, child) {
                      return DropdownButtonFormField<String>(
                        value: _formData['autopsystatus'],
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items: repository.getStatusOptions().map(
                          (option) => DropdownMenuItem(
                            value: option.value,
                            child: Text(option.label),
                          ),
                        ).toList(),
                        onChanged: (value) => setState(() {
                          _formData['autopsystatus'] = value;
                        }),
                      );
                    },
                  ),
                
                const SizedBox(height: 12),
                
                if (permissions.canEditField('autopsycomments'))
                  TextFormField(
                    initialValue: _formData['autopsycomments'],
                    decoration: const InputDecoration(
                      labelText: 'Comments',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    onChanged: (value) => _formData['autopsycomments'] = value,
                  ),
                
                const SizedBox(height: 24),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _isLoading ? null : () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveChanges,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Save'),
                      ),
                    ),
                  ],
                ),
                
                // Extra padding for keyboard
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final repository = context.read<AutopsyRepository>();
      final request = UpdateAutopsyRequest(
        name: _formData['name'],
        description: _formData['description'],
        autopsyStatus: _formData['autopsystatus'],
        autopsyComments: _formData['autopsycomments'],
        technicalCheckStatus: _formData['technicalcheckstatus'],
        autopsyCustomerMobile: _formData['autopsycustomermobile'],
      );

      await repository.updateAutopsy(widget.autopsy.id, request);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Autopsy updated successfully')),
        );
      }
    } catch (error) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
