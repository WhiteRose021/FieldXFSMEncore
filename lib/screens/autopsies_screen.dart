// lib/screens/autopsies_screen.dart - Enhanced with permissions
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../repositories/autopsy_repository.dart';
import '../services/permissions_manager.dart'; // 🔥 ENHANCED: Already imported
import '../models/autopsy_models.dart';
import '../widgets/professional_autopsy_list_item.dart';
import '../widgets/permission_guard.dart'; // 🔥 NEW: Add permission guard

class AutopsiesScreen extends StatefulWidget {
  const AutopsiesScreen({super.key});

  @override
  State<AutopsiesScreen> createState() => _AutopsiesScreenState();
}

class _AutopsiesScreenState extends State<AutopsiesScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String? _selectedStatusFilter;
  String? _selectedCategoryFilter;

  @override
  void initState() {
    super.initState();
    _setupScrollListener();
    // 🔥 FIX: Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 🔥 ENHANCED: Initialize with permission-aware loading
  void _initializeData() async {
    final repository = context.read<AutopsyRepository>();
    final permissionsManager = context.read<PermissionsManager>();
    
    debugPrint('🔄 AutopsiesScreen: Initializing with permissions...');
    
    // Load permissions first
    if (!permissionsManager.hasPermissions) {
      debugPrint('🔐 Loading permissions...');
      await permissionsManager.loadPermissions();
      debugPrint('✅ Permissions loaded - canCreate: ${permissionsManager.canCreate}');
    }
    
    // 🔥 NEW: Get permission-aware query parameters
    final permissionParams = permissionsManager.getUserQueryParameters();
    debugPrint('📋 Permission parameters available: $permissionParams');
    
    // Then load autopsies with permission filtering
    await repository.loadAutopsies(
      refresh: true,
      additionalParams: permissionParams,
    );
    
    debugPrint('✅ AutopsiesScreen initialized with ${repository.autopsies.length} autopsies');
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= 
          _scrollController.position.maxScrollExtent * 0.8) {
        // Load more when 80% scrolled
        final repository = context.read<AutopsyRepository>();
        if (repository.hasMore && !repository.isLoadingMore) {
          repository.loadMoreAutopsies();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // App Bar
          _buildSliverAppBar(),
          
          // Search and Filters
          SliverToBoxAdapter(
            child: _buildSearchAndFilters(),
          ),
          
          // Statistics Header with Permissions Info
          SliverToBoxAdapter(
            child: _buildStatisticsHeader(),
          ),
          
          // 🔥 NEW: Permission Status Indicator
          SliverToBoxAdapter(
            child: _buildPermissionStatusIndicator(),
          ),
          
          // Autopsy List
          _buildAutopsyList(),
          
          // Loading More Indicator
          SliverToBoxAdapter(
            child: _buildLoadMoreIndicator(),
          ),
          
          // Bottom Padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
      
      // 🔥 ENHANCED: Permission-aware Floating Action Button
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.blue.shade700,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Field Service Requests',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade700,
                Colors.blue.shade900,
              ],
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.engineering,
              size: 80,
              color: Colors.white24,
            ),
          ),
        ),
      ),
      actions: [
        // Refresh Button
        IconButton(
          onPressed: _refreshData,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
        ),
        
        // Filter Button
        IconButton(
          onPressed: _showFilterDialog,
          icon: const Icon(Icons.filter_list),
          tooltip: 'Filter',
        ),
        
        // More Options with Permission Info
        PopupMenuButton<String>(
          onSelected: _handleMenuSelection,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.download, size: 20),
                  SizedBox(width: 8),
                  Text('Export'),
                ],
              ),
            ),
            // 🔥 NEW: Permission info menu item
            const PopupMenuItem(
              value: 'permissions',
              child: Row(
                children: [
                  Icon(Icons.security, size: 20),
                  SizedBox(width: 8),
                  Text('Permission Info'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings, size: 20),
                  SizedBox(width: 8),
                  Text('Settings'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by customer, address, or SR number...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: _clearSearch,
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            onChanged: _onSearchChanged,
            onSubmitted: _performSearch,
          ),
          
          const SizedBox(height: 12),
          
          // Quick Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', null, _selectedStatusFilter),
                const SizedBox(width: 8),
                _buildFilterChip('New', 'new', _selectedStatusFilter),
                const SizedBox(width: 8),
                _buildFilterChip('In Progress', 'in_progress', _selectedStatusFilter),
                const SizedBox(width: 8),
                _buildFilterChip('Completed', 'autopsy_completed', _selectedStatusFilter),
                const SizedBox(width: 8),
                _buildFilterChip('On Hold', 'on_hold', _selectedStatusFilter),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value, String? currentValue) {
    final isSelected = currentValue == value;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatusFilter = selected ? value : null;
        });
        _applyFilters();
      },
      backgroundColor: Colors.grey.shade100,
      selectedColor: Colors.blue.shade100,
      checkmarkColor: Colors.blue.shade700,
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue.shade700 : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildStatisticsHeader() {
    return Consumer<AutopsyRepository>(
      builder: (context, repository, _) {
        if (repository.isLoading && repository.autopsies.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total',
                  repository.totalCount.toString(),
                  Icons.list_alt,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Loaded',
                  repository.autopsies.length.toString(),
                  Icons.download_done,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Today',
                  _getTodayCount(repository.autopsies).toString(),
                  Icons.today,
                  Colors.orange,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 🔥 NEW: Permission status indicator
  Widget _buildPermissionStatusIndicator() {
    return Consumer<PermissionsManager>(
      builder: (context, permissionsManager, _) {
        if (!permissionsManager.hasPermissions) {
          return Container(
            color: Colors.orange.shade50,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Permissions not loaded. Some features may be limited.',
                    style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
                  ),
                ),
                TextButton(
                  onPressed: () => permissionsManager.refreshPermissions(),
                  child: Text('Retry', style: TextStyle(color: Colors.orange.shade800)),
                ),
              ],
            ),
          );
        }

        // Show permission summary in debug mode
        return Container(
          color: Colors.blue.shade50,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.security, color: Colors.blue.shade600, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Permissions: ${_getPermissionSummary(permissionsManager)}',
                  style: TextStyle(color: Colors.blue.shade800, fontSize: 11),
                ),
              ),
              if (permissionsManager.error != null)
                Icon(Icons.error, color: Colors.red.shade600, size: 16),
            ],
          ),
        );
      },
    );
  }

  // 🔥 NEW: Get permission summary text
  String _getPermissionSummary(PermissionsManager manager) {
    final permissions = <String>[];
    if (manager.canCreate) permissions.add('Create');
    if (manager.canEdit) permissions.add('Edit');
    if (manager.canDelete) permissions.add('Delete');
    
    if (permissions.isEmpty) return 'Read Only';
    return permissions.join(', ');
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.shade700 ?? color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutopsyList() {
    return Consumer<AutopsyRepository>(
      builder: (context, repository, _) {
        if (repository.isLoading && repository.autopsies.isEmpty) {
          return const SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading service requests...'),
                ],
              ),
            ),
          );
        }

        if (repository.error != null) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Something went wrong',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    repository.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red.shade600),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _refreshData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (repository.autopsies.isEmpty) {
          return SliverFillRemaining(
            child: _buildEmptyState(), // 🔥 ENHANCED: Use permission-aware empty state
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final autopsy = repository.autopsies[index];
              return _buildAutopsyTileWithPermissions(autopsy); // 🔥 ENHANCED
            },
            childCount: repository.autopsies.length,
          ),
        );
      },
    );
  }

  // 🔥 NEW: Enhanced autopsy tile with permission checks
  Widget _buildAutopsyTileWithPermissions(CAutopsy autopsy) {
    return Consumer<PermissionsManager>(
      builder: (context, permissionsManager, _) {
        // Check record-level permissions
        final autopsyMap = autopsy.toJson();
        final canEdit = permissionsManager.canEditRecord(autopsyMap);
        final canDelete = permissionsManager.canDeleteRecord(autopsyMap);
        
        return ProfessionalAutopsyListItem(
          autopsy: autopsy,
          onTap: () => _openAutopsyDetails(autopsy),
          onEdit: canEdit ? () => _editAutopsy(autopsy) : null, // 🔥 NEW: Conditional edit
          onCall: () => _callCustomer(autopsy),
          onNavigate: () => _navigateToAddress(autopsy),
          // 🔥 NOTE: onDelete and permissionStatus can be added when ProfessionalAutopsyListItem supports them
        );
      },
    );
  }

  // 🔥 NEW: Permission-aware empty state
  Widget _buildEmptyState() {
    return Consumer<PermissionsManager>(
      builder: (context, permissionsManager, _) {
        final canCreate = permissionsManager.canCreate;
        
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.inbox_outlined,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'No service requests found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                canCreate 
                    ? 'Try adjusting your search or filters, or create a new request'
                    : 'Try adjusting your search or filters',
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              if (canCreate) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _createNewAutopsy,
                  icon: const Icon(Icons.add),
                  label: const Text('Create New Request'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Consumer<AutopsyRepository>(
      builder: (context, repository, _) {
        if (!repository.isLoadingMore) return const SizedBox.shrink();
        
        return const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Loading more...'),
              ],
            ),
          ),
        );
      },
    );
  }

  // 🔥 ENHANCED: Permission-aware floating action button
  Widget _buildFloatingActionButton() {
    return PermissionGuard.create(
      child: FloatingActionButton.extended(
        onPressed: _createNewAutopsy,
        icon: const Icon(Icons.add),
        label: const Text('New SR'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      fallback: const SizedBox.shrink(), // Hide if no create permission
    );
  }

  // Helper Methods
  int _getTodayCount(List<CAutopsy> autopsies) {
    final today = DateTime.now();
    return autopsies.where((autopsy) {
      if (autopsy.createdAt == null) return false;
      final created = autopsy.createdAt!;
      return created.year == today.year &&
             created.month == today.month &&
             created.day == today.day;
    }).length;
  }

  // 🔥 ENHANCED: Event Handlers with permission awareness
  void _refreshData() async {
    final repository = context.read<AutopsyRepository>();
    final permissionsManager = context.read<PermissionsManager>();
    
    // Refresh permissions first
    await permissionsManager.refreshPermissions();
    
    // Get updated permission parameters
    final permissionParams = permissionsManager.getUserQueryParameters();
    
    // Then refresh autopsies with updated permissions
    await repository.refreshAutopsies(additionalParams: permissionParams);
  }

  void _clearSearch() {
    _searchController.clear();
    _performSearch('');
  }

  void _onSearchChanged(String value) {
    // Debounced search will be implemented here
  }

  void _performSearch(String query) async {
    final repository = context.read<AutopsyRepository>();
    await repository.searchAutopsies(query);
  }

  void _applyFilters() async {
    final repository = context.read<AutopsyRepository>();
    final permissionsManager = context.read<PermissionsManager>();
    
    // Get permission parameters for filtering
    final permissionParams = permissionsManager.getUserQueryParameters();
    
    await repository.applyFilters(
      status: _selectedStatusFilter,
      category: _selectedCategoryFilter,
      additionalParams: permissionParams, // ✅ REQUIRED by your repository
    );
  }

  void _showFilterDialog() {
    // Implement advanced filter dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Advanced Filters'),
        content: const Text('Advanced filtering options will be implemented here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // 🔥 ENHANCED: Handle menu selection with permission info
  void _handleMenuSelection(String value) {
    switch (value) {
      case 'export':
        // Check export permission
        final permissionsManager = context.read<PermissionsManager>();
        if (permissionsManager.canPerformAction('read')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Export functionality coming soon')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You don\'t have permission to export data'),
              backgroundColor: Colors.red,
            ),
          );
        }
        break;
      case 'permissions':
        _showPermissionInfo(); // 🔥 NEW
        break;
      case 'settings':
        // Navigate to settings
        break;
    }
  }

  // 🔥 NEW: Show permission information dialog
  void _showPermissionInfo() {
    final permissionsManager = context.read<PermissionsManager>();
    final debugInfo = permissionsManager.getDebugSummary();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.security, color: Colors.blue),
            SizedBox(width: 8),
            Text('Permission Information'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ...debugInfo.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          '${entry.key}:',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: Text('${entry.value}'),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              permissionsManager.refreshPermissions();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Permissions refreshed')),
              );
            },
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  void _openAutopsyDetails(CAutopsy autopsy) {
    // Navigate to autopsy details screen
    Navigator.pushNamed(context, '/autopsy-details', arguments: autopsy.id);
  }

  void _editAutopsy(CAutopsy autopsy) {
    // Navigate to edit screen
    Navigator.pushNamed(context, '/autopsy-edit', arguments: autopsy.id).then((_) {
      _refreshData(); // Refresh list when returning
    });
  }

  void _callCustomer(CAutopsy autopsy) async {
    final phone = autopsy.autopsyCustomerMobile;
    if (phone?.isNotEmpty == true) {
      final uri = Uri.parse('tel:$phone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  void _navigateToAddress(CAutopsy autopsy) async {
    final address = autopsy.fullAddress;
    if (address.isNotEmpty) {
      final uri = Uri.parse('https://maps.google.com/search/?api=1&query=${Uri.encodeComponent(address)}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  void _createNewAutopsy() {
    // Navigate to create autopsy screen
    Navigator.pushNamed(context, '/autopsy-create').then((_) {
      _refreshData(); // Refresh list when returning
    });
  }

  // 🔥 NEW: Confirm delete with permission check
  void _confirmDeleteAutopsy(CAutopsy autopsy) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Service Request'),
        content: Text('Are you sure you want to delete "${autopsy.effectiveDisplayName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAutopsy(autopsy);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // 🔥 NEW: Delete autopsy
  Future<void> _deleteAutopsy(CAutopsy autopsy) async {
    try {
      final repository = context.read<AutopsyRepository>();
      // You'll need to add this method to your repository
      // await repository.deleteAutopsy(autopsy.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service request deleted successfully')),
      );
      
      _refreshData(); // Refresh list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting service request: $e')),
      );
    }
  }
}

// Fix for the missing shade700 extension
extension ColorExtension on Color {
  Color? get shade700 {
    if (this == Colors.red) return Colors.red.shade700;
    if (this == Colors.blue) return Colors.blue.shade700;
    if (this == Colors.green) return Colors.green.shade700;
    if (this == Colors.orange) return Colors.orange.shade700;
    return null;
  }
}