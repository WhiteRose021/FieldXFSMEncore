// lib/widgets/autopsy_widgets.dart - FIXED VERSION
// Updated field names to match cleaned autopsy_models.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/autopsy_models.dart';

class AutopsyStatusDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?>? onChanged;
  final List<AutopsyStatusOption>? options;
  final bool enabled;
  final String? hint;

  const AutopsyStatusDropdown({
    super.key,
    this.value,
    this.onChanged,
    this.options,
    this.enabled = true,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final statusOptions = options ?? AutopsyOptions.statusOptions;

    return DropdownButtonFormField<String>(
      initialValue: value, // Fixed: use initialValue instead of value
      onChanged: enabled ? onChanged : null,
      decoration: InputDecoration(
        hintText: hint ?? 'Select status',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('All Statuses'),
        ),
        ...statusOptions.map((option) => DropdownMenuItem<String>(
          value: option.value,
          child: Row(
            children: [
              if (option.color != null) ...[
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _parseColor(option.color!),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(child: Text(option.label)),
            ],
          ),
        )),
      ],
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }
}

class AutopsyCategoryDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?>? onChanged;
  final List<AutopsyCategoryOption>? options;
  final bool enabled;
  final String? hint;

  const AutopsyCategoryDropdown({
    super.key,
    this.value,
    this.onChanged,
    this.options,
    this.enabled = true,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final categoryOptions = options ?? AutopsyOptions.categoryOptions;

    return DropdownButtonFormField<String>(
      initialValue: value, // Fixed: use initialValue instead of value
      onChanged: enabled ? onChanged : null,
      decoration: InputDecoration(
        hintText: hint ?? 'Select category',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('All Categories'),
        ),
        ...categoryOptions.map((option) => DropdownMenuItem<String>(
          value: option.value,
          child: Text(option.label),
        )),
      ],
    );
  }
}

class AutopsyCard extends StatelessWidget {
  final CAutopsy autopsy;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;

  const AutopsyCard({
    super.key,
    required this.autopsy,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      autopsy.displayName ?? 'Autopsy ${autopsy.id}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // FIXED: autopsystatus → autopsyStatus
                  AutopsyStatusBadge(status: autopsy.autopsyStatus),
                ],
              ),
              const SizedBox(height: 12),
              // FIXED: autopsycustomername → autopsyCustomerName
              if (autopsy.autopsyCustomerName?.isNotEmpty == true)
                _buildInfoRow('Customer', autopsy.autopsyCustomerName!, Icons.person),
              if (autopsy.fullAddress.isNotEmpty)
                _buildInfoRow('Address', autopsy.fullAddress, Icons.location_on),
              // FIXED: autopsycategory → autopsyCategory
              if (autopsy.autopsyCategory?.isNotEmpty == true)
                _buildInfoRow('Category', autopsy.autopsyCategory!, Icons.category),
              // FIXED: Handle String createdAt instead of DateTime
              if (autopsy.createdAt != null)
                _buildInfoRow('Created', _formatDateString(autopsy.createdAt!), Icons.calendar_today),
              if (showActions) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onEdit != null)
                      TextButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit'),
                      ),
                    if (onDelete != null)
                      TextButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete, size: 16),
                        label: const Text('Delete'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // FIXED: Handle String date instead of DateTime
  String _formatDateString(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      // If parsing fails, return the original string
      return dateString;
    }
  }
}

class AutopsyStatusBadge extends StatelessWidget {
  final String? status;

  const AutopsyStatusBadge({
    super.key,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    final statusLabel = AutopsyOptions.getStatusLabel(status) ?? 'Unknown';
    final statusColor = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1), // Fixed: withOpacity → withValues
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            statusLabel,
            style: TextStyle(
              color: statusColor,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    final colorString = AutopsyOptions.getStatusColor(status);
    if (colorString != null) {
      try {
        return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
      } catch (_) {
        // Fall through to default
      }
    }
    return Colors.grey;
  }
}

class AutopsyFormFields extends StatelessWidget {
  final CAutopsy? initialData;
  final Map<String, TextEditingController> controllers;
  final bool enabled;

  const AutopsyFormFields({
    super.key,
    this.initialData,
    required this.controllers,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: controllers['displayName'],
          decoration: const InputDecoration(
            labelText: 'Display Name',
            border: OutlineInputBorder(),
          ),
          enabled: enabled,
          validator: (value) {
            if (value?.trim().isEmpty ?? true) {
              return 'Display name is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        // FIXED: Controller keys updated to camelCase
        TextFormField(
          controller: controllers['autopsyCustomerName'],
          decoration: const InputDecoration(
            labelText: 'Customer Name',
            border: OutlineInputBorder(),
          ),
          enabled: enabled,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: controllers['autopsyCustomerEmail'],
          decoration: const InputDecoration(
            labelText: 'Customer Email',
            border: OutlineInputBorder(),
          ),
          enabled: enabled,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value?.isNotEmpty == true && !_isValidEmail(value!)) {
              return 'Please enter a valid email address';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: controllers['autopsyCustomerMobile'],
          decoration: const InputDecoration(
            labelText: 'Customer Mobile',
            border: OutlineInputBorder(),
          ),
          enabled: enabled,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: controllers['autopsyOrderNumber'],
          decoration: const InputDecoration(
            labelText: 'Order Number',
            border: OutlineInputBorder(),
          ),
          enabled: enabled,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: controllers['autopsyBid'],
          decoration: const InputDecoration(
            labelText: 'BID',
            border: OutlineInputBorder(),
          ),
          enabled: enabled,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: controllers['autopsyCab'],
          decoration: const InputDecoration(
            labelText: 'CAB',
            border: OutlineInputBorder(),
          ),
          enabled: enabled,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: controllers['technicalCheckStatus'],
          decoration: const InputDecoration(
            labelText: 'Technical Check Status',
            border: OutlineInputBorder(),
          ),
          enabled: enabled,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: controllers['autopsyComments'],
          decoration: const InputDecoration(
            labelText: 'Comments',
            border: OutlineInputBorder(),
          ),
          enabled: enabled,
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        _buildAddressSection(),
      ],
    );
  }

  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Address',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controllers['address1'],
          decoration: const InputDecoration(
            labelText: 'Address Line 1',
            border: OutlineInputBorder(),
          ),
          enabled: enabled,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: controllers['address2'],
          decoration: const InputDecoration(
            labelText: 'Address Line 2',
            border: OutlineInputBorder(),
          ),
          enabled: enabled,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controllers['city'],
                decoration: const InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(),
                ),
                enabled: enabled,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: controllers['state'],
                decoration: const InputDecoration(
                  labelText: 'State',
                  border: OutlineInputBorder(),
                ),
                enabled: enabled,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controllers['postcode'],
                decoration: const InputDecoration(
                  labelText: 'Postcode',
                  border: OutlineInputBorder(),
                ),
                enabled: enabled,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: controllers['country'],
                decoration: const InputDecoration(
                  labelText: 'Country',
                  border: OutlineInputBorder(),
                ),
                enabled: enabled,
              ),
            ),
          ],
        ),
      ],
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}

class AutopsySearchBar extends StatefulWidget {
  final ValueChanged<String>? onSearch;
  final String? initialValue;
  final String? hint;

  const AutopsySearchBar({
    super.key,
    this.onSearch,
    this.initialValue,
    this.hint,
  });

  @override
  State<AutopsySearchBar> createState() => _AutopsySearchBarState();
}

class _AutopsySearchBarState extends State<AutopsySearchBar> {
  late TextEditingController _controller;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      widget.onSearch?.call(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        hintText: widget.hint ?? 'Search autopsies...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _controller.clear();
                  widget.onSearch?.call('');
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }
}

class AutopsyFilterChips extends StatelessWidget {
  final List<String> activeFilters;
  final ValueChanged<String>? onRemoveFilter;
  final VoidCallback? onClearAll;

  const AutopsyFilterChips({
    super.key,
    required this.activeFilters,
    this.onRemoveFilter,
    this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    if (activeFilters.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        ...activeFilters.map((filter) => Chip(
          label: Text(filter),
          onDeleted: () => onRemoveFilter?.call(filter),
          deleteIcon: const Icon(Icons.close, size: 16),
        )),
        if (activeFilters.length > 1)
          ActionChip(
            label: const Text('Clear All'),
            onPressed: onClearAll,
            backgroundColor: Colors.red.shade50,
            side: BorderSide(color: Colors.red.shade200),
          ),
      ],
    );
  }
}