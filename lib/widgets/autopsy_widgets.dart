// lib/widgets/autopsy_widgets.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/autopsy_models.dart';
import '../repositories/autopsy_repository.dart';
import '../services/permissions_manager.dart';

/// Widget for displaying a list of autopsies with search and filtering
class AutopsyListWidget extends StatefulWidget {
  final Function(CAutopsy)? onAutopsyTap;
  final bool showSearch;
  final bool showFilters;
  final bool allowSelection;

  const AutopsyListWidget({
    super.key,
    this.onAutopsyTap,
    this.showSearch = true,
    this.showFilters = true,
    this.allowSelection = false,
  });

  @override
  State<AutopsyListWidget> createState() => _AutopsyListWidgetState();
}

class _AutopsyListWidgetState extends State<AutopsyListWidget> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedStatus;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final repository = context.read<AutopsyRepository>();
    final permissionsManager = context.read<PermissionsManager>();
    
    // Load permissions first
    await permissionsManager.loadPermissions();
    
    // Then load autopsies
    await repository.loadAutopsies();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AutopsyRepository, PermissionsManager>(
      builder: (context, repository, permissions, child) {
        return Column(
          children: [
            // Search and filters
            if (widget.showSearch || widget.showFilters)
              _buildSearchAndFilters(repository, permissions),
            
            // Action bar
            if (permissions.canCreate || repository.hasSelectedItems)
              _buildActionBar(repository, permissions),
            
            // List content
            Expanded(
              child: _buildListContent(repository, permissions),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchAndFilters(AutopsyRepository repository, PermissionsManager permissions) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search bar
            if (widget.showSearch)
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search autopsies...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            repository.clearSearch();
                          },
                        )
                      : null,
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (query) {
                  repository.searchAutopsies(query);
                },
              ),
            
            // Filters
            if (widget.showFilters) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  // Status filter
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Statuses')),
                        ...repository.getStatusOptions().map(
                          (option) => DropdownMenuItem(
                            value: option.value,
                            child: Text(option.label),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value;
                        });
                        repository.applyFilters(
                          status: value,
                          category: _selectedCategory,
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Category filter
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Categories')),
                        ...repository.getCategoryOptions().map(
                          (option) => DropdownMenuItem(
                            value: option.value,
                            child: Text(option.label),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                        repository.applyFilters(
                          status: _selectedStatus,
                          category: value,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionBar(AutopsyRepository repository, PermissionsManager permissions) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            // Create button
            if (permissions.canCreate)
              ElevatedButton.icon(
                onPressed: () => _showCreateDialog(context, repository),
                icon: const Icon(Icons.add),
                label: const Text('Create Autopsy'),
              ),
            
            const Spacer(),
            
            // Selection actions
            if (repository.hasSelectedItems) ...[
              Text('${repository.selectedCount} selected'),
              const SizedBox(width: 16),
              
              if (permissions.canEdit)
                IconButton(
                  onPressed: () => _showBulkEditDialog(context, repository),
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit Selected',
                ),
              
              if (permissions.canDelete)
                IconButton(
                  onPressed: () => _showBulkDeleteDialog(context, repository),
                  icon: const Icon(Icons.delete),
                  tooltip: 'Delete Selected',
                ),
              
              IconButton(
                onPressed: repository.clearSelection,
                icon: const Icon(Icons.clear),
                tooltip: 'Clear Selection',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildListContent(AutopsyRepository repository, PermissionsManager permissions) {
    if (repository.isLoading && repository.autopsies.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (repository.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Error: ${repository.error}',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: repository.refreshAutopsies,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (repository.autopsies.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No autopsies found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: repository.refreshAutopsies,
      child: ListView.builder(
        itemCount: repository.autopsies.length + (repository.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Load more indicator
          if (index == repository.autopsies.length) {
            if (repository.isLoadingMore) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              );
            } else {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: repository.loadMoreAutopsies,
                  child: const Text('Load More'),
                ),
              );
            }
          }

          final autopsy = repository.autopsies[index];
          return AutopsyListItem(
            autopsy: autopsy,
            isSelected: widget.allowSelection ? repository.isSelected(autopsy.id) : false,
            onTap: widget.onAutopsyTap,
            onSelectionChanged: widget.allowSelection 
                ? (selected) {
                    if (selected) {
                      repository.selectAutopsy(autopsy.id);
                    } else {
                      repository.deselectAutopsy(autopsy.id);
                    }
                  }
                : null,
            permissions: permissions,
          );
        },
      ),
    );
  }

  void _showCreateDialog(BuildContext context, AutopsyRepository repository) {
    showDialog(
      context: context,
      builder: (context) => AutopsyCreateDialog(repository: repository),
    );
  }

  void _showBulkEditDialog(BuildContext context, AutopsyRepository repository) {
    showDialog(
      context: context,
      builder: (context) => AutopsyBulkEditDialog(repository: repository),
    );
  }

  void _showBulkDeleteDialog(BuildContext context, AutopsyRepository repository) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Autopsies'),
        content: Text(
          'Are you sure you want to delete ${repository.selectedCount} autopsies?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await repository.deleteSelectedAutopsies();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Autopsies deleted successfully')),
                  );
                }
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${error.toString()}')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Widget for displaying a single autopsy item in the list
class AutopsyListItem extends StatelessWidget {
  final CAutopsy autopsy;
  final bool isSelected;
  final Function(CAutopsy)? onTap;
  final Function(bool)? onSelectionChanged;
  final PermissionsManager permissions;

  const AutopsyListItem({
    super.key,
    required this.autopsy,
    required this.isSelected,
    required this.permissions,
    this.onTap,
    this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = _getDisplayName();
    final statusLabel = _getStatusLabel();
    final address = autopsy.autopsyFullAddress ?? 'No address';
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      elevation: isSelected ? 4.0 : 1.0,
      color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
      child: ListTile(
        leading: onSelectionChanged != null
            ? Checkbox(
                value: isSelected,
                onChanged: onSelectionChanged != null
                    ? (checked) => onSelectionChanged!(checked ?? false)
                    : null,
              )
            : CircleAvatar(
                child: Text(displayName.substring(0, 1).toUpperCase()),
              ),
        title: Text(
          displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (permissions.isFieldVisible('autopsyfulladdress'))
              Text(address),
            const SizedBox(height: 4),
            Row(
              children: [
                if (permissions.isFieldVisible('autopsystatus'))
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: _getStatusColor(),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (permissions.isFieldVisible('autopsycategory') && 
                    autopsy.autopsyCategory != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      autopsy.autopsyCategory!,
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: onTap != null 
            ? const Icon(Icons.chevron_right)
            : null,
        onTap: onTap != null ? () => onTap!(autopsy) : null,
      ),
    );
  }

  String _getDisplayName() {
    if (autopsy.name?.isNotEmpty == true) {
      return autopsy.name!;
    }
    if (autopsy.autopsyCustomerName?.isNotEmpty == true) {
      return 'Autopsy for ${autopsy.autopsyCustomerName}';
    }
    return 'Autopsy #${autopsy.id}';
  }

  String _getStatusLabel() {
    final statusOptions = AutopsyOptions.statusOptions;
    final option = statusOptions.cast<AutopsyStatusOption?>().firstWhere(
      (opt) => opt?.value == autopsy.autopsyStatus,
      orElse: () => null,
    );
    return option?.label ?? autopsy.autopsyStatus ?? 'Unknown';
  }

  Color _getStatusColor() {
    switch (autopsy.autopsyStatus) {
      case 'new':
        return Colors.blue;
      case 'autopsy_scheduled':
        return Colors.orange;
      case 'autopsy_in_progress':
        return Colors.yellow.shade700;
      case 'autopsy_completed':
        return Colors.green;
      case 'technical_check_rejected':
        return Colors.red;
      case 'technical_check_approved':
        return Colors.green;
      case 'job_completed':
        return Colors.green;
      case 'job_cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}

/// Widget for displaying autopsy details
class AutopsyDetailWidget extends StatefulWidget {
  final String autopsyId;
  final bool allowEdit;

  const AutopsyDetailWidget({
    super.key,
    required this.autopsyId,
    this.allowEdit = true,
  });

  @override
  State<AutopsyDetailWidget> createState() => _AutopsyDetailWidgetState();
}

class _AutopsyDetailWidgetState extends State<AutopsyDetailWidget> {
  CAutopsy? _autopsy;
  bool _isLoading = true;
  String? _error;
  bool _isEditing = false;
  final Map<String, dynamic> _editingValues = {};

  @override
  void initState() {
    super.initState();
    _loadAutopsy();
  }

  Future<void> _loadAutopsy() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final repository = context.read<AutopsyRepository>();
      final autopsy = await repository.getAutopsy(widget.autopsyId);
      
      setState(() {
        _autopsy = autopsy;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PermissionsManager>(
      builder: (context, permissions, child) {
        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text('Error: $_error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadAutopsy,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (_autopsy == null) {
          return const Center(child: Text('Autopsy not found'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with actions
              _buildHeader(permissions),
              const SizedBox(height: 24),
              
              // Basic Information
              _buildBasicInfoCard(permissions),
              const SizedBox(height: 16),
              
              // Customer Information
              if (permissions.isFieldVisible('autopsycustomername') ||
                  permissions.isFieldVisible('autopsycustomeremail'))
                _buildCustomerInfoCard(permissions),
              const SizedBox(height: 16),
              
              // Technical Information
              _buildTechnicalInfoCard(permissions),
              const SizedBox(height: 16),
              
              // Status Information
              _buildStatusCard(permissions),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(PermissionsManager permissions) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getDisplayName(),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (permissions.isFieldVisible('description') && 
                      _autopsy!.description?.isNotEmpty == true)
                    Text(
                      _autopsy!.description!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                ],
              ),
            ),
            if (widget.allowEdit && !_isEditing) ...[
              if (permissions.canEdit)
                ElevatedButton.icon(
                  onPressed: () => setState(() => _isEditing = true),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
              const SizedBox(width: 8),
              if (permissions.canDelete)
                ElevatedButton.icon(
                  onPressed: _showDeleteDialog,
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
            ],
            if (_isEditing) ...[
              ElevatedButton.icon(
                onPressed: _saveChanges,
                icon: const Icon(Icons.save),
                label: const Text('Save'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => setState(() {
                  _isEditing = false;
                  _editingValues.clear();
                }),
                child: const Text('Cancel'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoCard(PermissionsManager permissions) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            if (permissions.isFieldVisible('name'))
              _buildField('Name', 'name', _autopsy!.name, permissions),
            
            if (permissions.isFieldVisible('autopsyfulladdress'))
              _buildField('Address', 'autopsyfulladdress', 
                  _autopsy!.autopsyFullAddress, permissions),
            
            if (permissions.isFieldVisible('autopsycategory'))
              _buildField('Category', 'autopsycategory', 
                  _autopsy!.autopsyCategory, permissions),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfoCard(PermissionsManager permissions) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            if (permissions.isFieldVisible('autopsycustomername'))
              _buildField('Customer Name', 'autopsycustomername', 
                  _autopsy!.autopsyCustomerName, permissions),
            
            if (permissions.isFieldVisible('autopsycustomeremail'))
              _buildField('Customer Email', 'autopsycustomeremail', 
                  _autopsy!.autopsyCustomerEmail, permissions),
            
            if (permissions.isFieldVisible('autopsycustomermobile'))
              _buildField('Customer Mobile', 'autopsycustomermobile', 
                  _autopsy!.autopsyCustomerMobile, permissions),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicalInfoCard(PermissionsManager permissions) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Technical Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            if (permissions.isFieldVisible('autopsyordernumber'))
              _buildField('Order Number', 'autopsyordernumber', 
                  _autopsy!.autopsyOrderNumber, permissions),
            
            if (permissions.isFieldVisible('autopsybid'))
              _buildField('BID', 'autopsybid', 
                  _autopsy!.autopsyBid, permissions),
            
            if (permissions.isFieldVisible('autopsycab'))
              _buildField('CAB', 'autopsycab', 
                  _autopsy!.autopsyCab, permissions),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(PermissionsManager permissions) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            if (permissions.isFieldVisible('autopsystatus'))
              _buildField('Status', 'autopsystatus', 
                  _autopsy!.autopsyStatus, permissions),
            
            if (permissions.isFieldVisible('technicalcheckstatus'))
              _buildField('Technical Check Status', 'technicalcheckstatus', 
                  _autopsy!.technicalCheckStatus, permissions),
            
            if (permissions.isFieldVisible('autopsycomments'))
              _buildField('Comments', 'autopsycomments', 
                  _autopsy!.autopsyComments, permissions),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, String fieldName, String? value, PermissionsManager permissions) {
    if (!permissions.isFieldVisible(fieldName)) {
      return const SizedBox.shrink();
    }

    final isEditable = permissions.isFieldEditable(fieldName);
    final displayValue = value ?? 'Not set';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: _isEditing && isEditable
                ? TextFormField(
                    initialValue: _editingValues[fieldName] ?? value ?? '',
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8,
                      ),
                    ),
                    onChanged: (newValue) {
                      _editingValues[fieldName] = newValue;
                    },
                  )
                : Text(displayValue),
          ),
        ],
      ),
    );
  }

  String _getDisplayName() {
    if (_autopsy!.name?.isNotEmpty == true) {
      return _autopsy!.name!;
    }
    if (_autopsy!.autopsyCustomerName?.isNotEmpty == true) {
      return 'Autopsy for ${_autopsy!.autopsyCustomerName}';
    }
    return 'Autopsy #${_autopsy!.id}';
  }

  Future<void> _saveChanges() async {
    try {
      final repository = context.read<AutopsyRepository>();
      final request = UpdateAutopsyRequest(
        name: _editingValues['name'],
        description: _editingValues['description'],
        autopsyFullAddress: _editingValues['autopsyfulladdress'],
        autopsyStatus: _editingValues['autopsystatus'],
        autopsyComments: _editingValues['autopsycomments'],
        technicalCheckStatus: _editingValues['technicalcheckstatus'],
        autopsyCustomerMobile: _editingValues['autopsycustomermobile'],
      );

      final updatedAutopsy = await repository.updateAutopsy(_autopsy!.id, request);
      
      setState(() {
        _autopsy = updatedAutopsy;
        _isEditing = false;
        _editingValues.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Autopsy updated successfully')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${error.toString()}')),
        );
      }
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Autopsy'),
        content: const Text('Are you sure you want to delete this autopsy?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                final repository = context.read<AutopsyRepository>();
                await repository.deleteAutopsy(_autopsy!.id);
                
                if (mounted) {
                  Navigator.of(context).pop(); // Go back to list
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Autopsy deleted successfully')),
                  );
                }
              } catch (error) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${error.toString()}')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Dialog for creating new autopsy
class AutopsyCreateDialog extends StatefulWidget {
  final AutopsyRepository repository;

  const AutopsyCreateDialog({super.key, required this.repository});

  @override
  State<AutopsyCreateDialog> createState() => _AutopsyCreateDialogState();
}

class _AutopsyCreateDialogState extends State<AutopsyCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, String> _formData = {};

  @override
  Widget build(BuildContext context) {
    return Consumer<PermissionsManager>(
      builder: (context, permissions, child) {
        return AlertDialog(
          title: const Text('Create New Autopsy'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (permissions.isFieldEditable('name'))
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Name'),
                        onSaved: (value) => _formData['name'] = value ?? '',
                      ),
                    
                    if (permissions.isFieldEditable('autopsycustomername'))
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Customer Name'),
                        validator: (value) => value?.isEmpty == true ? 'Required' : null,
                        onSaved: (value) => _formData['autopsycustomername'] = value ?? '',
                      ),
                    
                    if (permissions.isFieldEditable('autopsyfulladdress'))
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Address'),
                        onSaved: (value) => _formData['autopsyfulladdress'] = value ?? '',
                      ),
                    
                    if (permissions.isFieldEditable('autopsycategory'))
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Category'),
                        items: widget.repository.getCategoryOptions().map(
                          (option) => DropdownMenuItem(
                            value: option.value,
                            child: Text(option.label),
                          ),
                        ).toList(),
                        onSaved: (value) => _formData['autopsycategory'] = value ?? '', onChanged: (String? value) {  },
                      ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _createAutopsy,
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createAutopsy() async {
    if (!_formKey.currentState!.validate()) return;
    
    _formKey.currentState!.save();
    
    try {
      final request = CreateAutopsyRequest(
        name: _formData['name'],
        autopsyCustomerName: _formData['autopsycustomername'],
        autopsyFullAddress: _formData['autopsyfulladdress'],
        autopsyCategory: _formData['autopsycategory'],
        autopsyStatus: 'new',
      );

      await widget.repository.createAutopsy(request);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Autopsy created successfully')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${error.toString()}')),
        );
      }
    }
  }
}

/// Dialog for bulk editing autopsies
class AutopsyBulkEditDialog extends StatefulWidget {
  final AutopsyRepository repository;

  const AutopsyBulkEditDialog({super.key, required this.repository});

  @override
  State<AutopsyBulkEditDialog> createState() => _AutopsyBulkEditDialogState();
}

class _AutopsyBulkEditDialogState extends State<AutopsyBulkEditDialog> {
  String? _newStatus;
  String? _newCategory;

  @override
  Widget build(BuildContext context) {
    return Consumer<PermissionsManager>(
      builder: (context, permissions, child) {
        return AlertDialog(
          title: Text('Edit ${widget.repository.selectedCount} Autopsies'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (permissions.isFieldEditable('autopsystatus'))
                DropdownButtonFormField<String>(
                  value: _newStatus,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('No Change')),
                    ...widget.repository.getStatusOptions().map(
                      (option) => DropdownMenuItem(
                        value: option.value,
                        child: Text(option.label),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _newStatus = value),
                ),
              
              if (permissions.isFieldEditable('autopsycategory'))
                DropdownButtonFormField<String>(
                  value: _newCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('No Change')),
                    ...widget.repository.getCategoryOptions().map(
                      (option) => DropdownMenuItem(
                        value: option.value,
                        child: Text(option.label),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _newCategory = value),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _updateSelected,
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateSelected() async {
    try {
      final request = UpdateAutopsyRequest(
        autopsyStatus: _newStatus,
      );

      await widget.repository.updateSelectedAutopsies(request);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Autopsies updated successfully')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${error.toString()}')),
        );
      }
    }
  }
}