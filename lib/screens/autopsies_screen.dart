// lib/screens/autopsies_screen.dart - Complete Working Version

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/autopsy_repository.dart';
import '../services/permissions_manager.dart';
import '../models/autopsy_models.dart';
import '../utils/error_handler.dart';
import '../utils/permissions_helper.dart';
import 'autopsy_detail_screen.dart';
import '../widgets/sidebar_menu.dart';

class AutopsiesScreen extends StatefulWidget {
  const AutopsiesScreen({super.key});

  @override
  State<AutopsiesScreen> createState() => _AutopsiesScreenState();
}

class _AutopsiesScreenState extends State<AutopsiesScreen> {
  bool _isInitialized = false;
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Dropdown states
  bool _isSearchExpanded = false;
  bool _isStatusExpanded = false;
  String? _selectedStatus;

  // FSM Theme Colors
  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color backgroundColor = Color(0xFFF5F6FA);
  static const Color primaryText = Color(0xFF2E3A59);
  static const Color secondaryText = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      final permissionsManager = context.read<PermissionsManager>();
      await PermissionsHelper.ensurePermissionsLoaded(permissionsManager);
      
      // ignore: use_build_context_synchronously
      final repository = context.read<AutopsyRepository>();
      await repository.loadAutopsies(refresh: true);
      
      setState(() {
        _isInitialized = true;
      });
    } catch (error) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, error);
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const SidebarMenu(), // 👈 ADD THIS LINE
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text(
          'Autopsies',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          Consumer<AutopsyRepository>(
            builder: (context, repository, child) {
              return IconButton(
                onPressed: repository.isLoading ? null : () {
                  repository.refreshAutopsies();
                },
                icon: repository.isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withOpacity(0.8),
                          ),
                        ),
                      )
                    : const Icon(Icons.refresh),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: !_isInitialized
          ? _buildLoadingState()
          : Column(
              children: [
                _buildHeader(),
                _buildSearchSection(),
                _buildStatusSection(),
                Expanded(child: _buildAutopsyList()),
              ],
            ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildHeader() {
    return Consumer<AutopsyRepository>(
      builder: (context, repository, child) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          decoration: const BoxDecoration(color: primaryBlue),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${repository.totalCount} Total',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Field Service Autopsies',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assignment,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isSearchExpanded = !_isSearchExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.search, color: primaryBlue, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Search Autopsies',
                      style: TextStyle(
                        color: primaryText,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Icon(
                    _isSearchExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: secondaryText,
                  ),
                ],
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isSearchExpanded ? null : 0,
            child: _isSearchExpanded
                ? Container(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [
                        const Divider(),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            Future.delayed(const Duration(milliseconds: 500), () {
                              if (_searchController.text == value) {
                                _performSearch(value);
                              }
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search by name, customer, address...',
                            hintStyle: TextStyle(color: Colors.grey.shade500),
                            prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      _performSearch('');
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: primaryBlue, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isStatusExpanded = !_isStatusExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.filter_list, color: primaryBlue, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedStatus != null
                          ? 'Filter: ${_getStatusLabel(_selectedStatus!)}'
                          : 'Filter by Status',
                      style: const TextStyle(
                        color: primaryText,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (_selectedStatus != null) ...[
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        setState(() {
                          _selectedStatus = null;
                        });
                        _filterByStatus(null);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Icon(
                    _isStatusExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: secondaryText,
                  ),
                ],
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isStatusExpanded ? null : 0,
            child: _isStatusExpanded
                ? Container(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [
                        const Divider(),
                        const SizedBox(height: 8),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 4,
                          children: [
                            _buildStatusOption('All', null),
                            ...AutopsyOptions.statusOptions.map((status) =>
                                _buildStatusOption(status.label, status.value),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOption(String label, String? value) {
    final isSelected = _selectedStatus == value;
    final statusColor = value != null ? _getStatusColor(value) : primaryBlue;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedStatus = value;
          _isStatusExpanded = false;
        });
        _filterByStatus(value);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? statusColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? statusColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (value != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? statusColor : primaryText,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
          ),
          SizedBox(height: 16),
          Text(
            'Loading autopsies...',
            style: TextStyle(
              color: primaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutopsyList() {
    return Consumer<AutopsyRepository>(
      builder: (context, repository, child) {
        if (repository.isLoading && repository.autopsies.isEmpty) {
          return _buildLoadingState();
        }

        if (repository.error != null && repository.autopsies.isEmpty) {
          return _buildErrorState(repository.error!, repository);
        }

        if (repository.autopsies.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: repository.refreshAutopsies,
          color: primaryBlue,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: repository.autopsies.length + (repository.hasMore ? 1 : 0),
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == repository.autopsies.length) {
                return _buildLoadMoreButton(repository);
              }

              final autopsy = repository.autopsies[index];
              return _buildAutopsyCard(autopsy);
            },
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String error, AutopsyRepository repository) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: repository.refreshAutopsies,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No autopsies found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutopsyCard(CAutopsy autopsy) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToDetail(autopsy),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        autopsy.displayName ?? 'Autopsy ${autopsy.id}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryText,
                        ),
                      ),
                    ),
                    _buildStatusBadge(autopsy.autopsyStatus ?? 'unknown'),
                  ],
                ),
                const SizedBox(height: 12),
                // Customer info
                if (autopsy.autopsyCustomerName?.isNotEmpty == true)
                  _buildInfoRow(
                    'Customer',
                    autopsy.autopsyCustomerName!,
                    Icons.person_outline,
                  ),
                // Address
                if (autopsy.fullAddress.isNotEmpty)
                  _buildInfoRow(
                    'Address',
                    autopsy.fullAddress,
                    Icons.location_on_outlined,
                  ),
                // Category and date
                Row(
                  children: [
                    if (autopsy.autopsyCategory?.isNotEmpty == true) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          autopsy.autopsyCategory!,
                          style: const TextStyle(
                            color: primaryBlue,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const Spacer(),
                    ],
                    if (autopsy.createdAt != null)
                      Text(
                        _formatDate(autopsy.createdAt! as DateTime),
                        style: const TextStyle(
                          color: secondaryText,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);
    final label = _getStatusLabel(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: primaryText,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton(AutopsyRepository repository) {
    if (repository.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ElevatedButton(
        onPressed: repository.loadMoreAutopsies,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: primaryBlue,
          elevation: 0,
          side: const BorderSide(color: primaryBlue),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text(
          'Load More',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget? _buildFAB() {
    return Consumer<PermissionsManager>(
      builder: (context, permissions, child) {
        if (!permissions.canCreate) return const SizedBox.shrink();

        return FloatingActionButton.extended(
          onPressed: () {
            // Navigate to create autopsy screen
          },
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text(
            'New Autopsy',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        );
      },
    );
  }

  // Helper methods
  Color _getStatusColor(String? status) {
    switch (status) {
      case 'new':
        return const Color(0xFF2196F3);
      case 'autopsy_scheduled':
        return const Color(0xFFFF9800);
      case 'autopsy_in_progress':
        return const Color(0xFFFFC107);
      case 'autopsy_completed':
        return const Color(0xFF4CAF50);
      case 'technical_check_pending':
        return const Color(0xFF9C27B0);
      case 'technical_check_rejected':
        return const Color(0xFFF44336);
      case 'technical_check_approved':
        return const Color(0xFF4CAF50);
      case 'work_orders_created':
        return const Color(0xFF3F51B5);
      case 'job_completed':
        return const Color(0xFF4CAF50);
      case 'job_cancelled':
        return const Color(0xFF9E9E9E);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  String _getStatusLabel(String? status) {
    final option = AutopsyOptions.statusOptions.cast<AutopsyStatusOption?>().firstWhere(
      (opt) => opt?.value == status,
      orElse: () => null,
    );
    return option?.label ?? status ?? 'Unknown';
  }

  String _formatDate(DateTime date) {
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
  }

  void _performSearch(String query) {
    final repository = context.read<AutopsyRepository>();
    if (query.isEmpty) {
      repository.clearSearch();
    } else {
      repository.searchAutopsies(query);
    }
  }

  void _filterByStatus(String? status) {
    final repository = context.read<AutopsyRepository>();
    repository.applyFilters(status: status);
  }

  void _navigateToDetail(CAutopsy autopsy) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AutopsyDetailScreen(autopsyId: autopsy.id),
      ),
    );
  }
}