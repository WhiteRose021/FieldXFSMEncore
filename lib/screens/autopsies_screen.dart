// lib/screens/autopsies_screen.dart - Professional List Screen
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../repositories/autopsy_repository.dart';
import '../services/permissions_manager.dart';
import '../models/autopsy_models.dart';
import '../widgets/professional_autopsy_list_item.dart';

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
    _initializeData();
    _setupScrollListener();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeData() async {
    final repository = context.read<AutopsyRepository>();
    final permissionsManager = context.read<PermissionsManager>();
    
    // Load permissions first
    await permissionsManager.loadPermissions();
    
    // Then load autopsies
    await repository.loadAutopsies(refresh: true);
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
          
          // Statistics Header
          SliverToBoxAdapter(
            child: _buildStatisticsHeader(),
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
      
      // Floating Action Button
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
        
        // More Options
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
              color: color.shade700,
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
          return const SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No service requests found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Try adjusting your search or filters',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final autopsy = repository.autopsies[index];
              return ProfessionalAutopsyListItem(
                autopsy: autopsy,
                onTap: () => _openAutopsyDetails(autopsy),
                onEdit: () => _editAutopsy(autopsy),
                onCall: () => _callCustomer(autopsy),
                onNavigate: () => _navigateToAddress(autopsy),
              );
            },
            childCount: repository.autopsies.length,
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

  Widget _buildFloatingActionButton() {
    return Consumer<PermissionsManager>(
      builder: (context, permissions, _) {
        if (!permissions.canCreate) return const SizedBox.shrink();
        
        return FloatingActionButton.extended(
          onPressed: _createNewAutopsy,
          icon: const Icon(Icons.add),
          label: const Text('New SR'),
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
        );
      },
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

  // Event Handlers
  void _refreshData() async {
    final repository = context.read<AutopsyRepository>();
    await repository.refreshAutopsies();
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
    await repository.applyFilters(
      status: _selectedStatusFilter,
      category: _selectedCategoryFilter,
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

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'export':
        // Implement export functionality
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export functionality coming soon')),
        );
        break;
      case 'settings':
        // Navigate to settings
        break;
    }
  }

  void _openAutopsyDetails(CAutopsy autopsy) {
    // Navigate to autopsy details screen
    Navigator.pushNamed(context, '/autopsy-details', arguments: autopsy.id);
  }

  void _editAutopsy(CAutopsy autopsy) {
    // Navigate to edit screen
    Navigator.pushNamed(context, '/autopsy-edit', arguments: autopsy.id);
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
    Navigator.pushNamed(context, '/autopsy-create');
  }
}

extension on Color {
  get shade700 => null;
}