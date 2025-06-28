// lib/screens/autopsy_detail_screen.dart - Minimal FSM Design

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/autopsy_repository.dart';
import '../services/permissions_manager.dart';
import '../models/autopsy_models.dart';
import '../utils/error_handler.dart';
import '../utils/permissions_helper.dart';

class AutopsyDetailScreen extends StatefulWidget {
  final String autopsyId;

  const AutopsyDetailScreen({
    super.key,
    required this.autopsyId,
  });

  @override
  State<AutopsyDetailScreen> createState() => _AutopsyDetailScreenState();
}

class _AutopsyDetailScreenState extends State<AutopsyDetailScreen> {
  CAutopsy? _autopsy;
  bool _isLoading = true;
  String? _error;

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

      final permissionsManager = context.read<PermissionsManager>();
      await PermissionsHelper.ensurePermissionsLoaded(permissionsManager);

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
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : _autopsy == null
                  ? _buildNotFoundState()
                  : _buildDetailContent(),
    );
  }

  Widget _buildDetailContent() {
    final statusColor = _getStatusColor(_autopsy!.autopsyStatus);
    final statusLabel = _getStatusLabel(_autopsy!.autopsyStatus);

    return CustomScrollView(
      slivers: [
        // Custom App Bar with Gradient
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1565C0), // Deep blue
                    Color(0xFF1976D2), // Material blue
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 60, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              statusLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Title
                      Text(
                        _autopsy!.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_autopsy!.autopsyCustomerName?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          _autopsy!.autopsyCustomerName!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          actions: [
            Consumer<PermissionsManager>(
              builder: (context, permissions, child) {
                if (!permissions.hasPermissions) return const SizedBox.shrink();
                
                return PopupMenuButton<String>(
                  onSelected: _handleMenuAction,
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (context) => [
                    if (permissions.canEdit)
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Edit'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    if (permissions.canDelete)
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete_outline),
                          title: Text('Delete'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuickInfoCards(),
                const SizedBox(height: 16),
                _buildBasicInfoCard(),
                const SizedBox(height: 16),
                _buildCustomerInfoCard(),
                const SizedBox(height: 16),
                _buildTechnicalInfoCard(),
                const SizedBox(height: 16),
                _buildStatusHistoryCard(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickInfoCards() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickInfoCard(
            'Category',
            _autopsy!.autopsyCategory ?? 'Not set',
            Icons.category_outlined,
            const Color(0xFF1565C0),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickInfoCard(
            'Created',
            _autopsy!.createdAt != null
                ? _formatDate(_autopsy!.createdAt!)
                : 'Unknown',
            Icons.calendar_today_outlined,
            const Color(0xFF4CAF50),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickInfoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF2E3A59),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return _buildInfoCard(
      'Basic Information',
      Icons.info_outline,
      [
        if (_autopsy!.name?.isNotEmpty == true)
          _buildInfoRow('Name', _autopsy!.name!),
        if (_autopsy!.description?.isNotEmpty == true)
          _buildInfoRow('Description', _autopsy!.description!),
        if (_autopsy!.fullAddress.isNotEmpty)
          _buildInfoRow('Address', _autopsy!.fullAddress),
        if (_autopsy!.autopsyOrderNumber?.isNotEmpty == true)
          _buildInfoRow('Order Number', _autopsy!.autopsyOrderNumber!),
        if (_autopsy!.buildingId?.isNotEmpty == true)
          _buildInfoRow('Building ID', _autopsy!.buildingId!),
      ],
    );
  }

  Widget _buildCustomerInfoCard() {
    return _buildInfoCard(
      'Customer Information',
      Icons.person_outline,
      [
        if (_autopsy!.autopsyCustomerName?.isNotEmpty == true)
          _buildInfoRow('Customer Name', _autopsy!.autopsyCustomerName!),
        if (_autopsy!.autopsyCustomerEmail?.isNotEmpty == true)
          _buildInfoRow('Email', _autopsy!.autopsyCustomerEmail!),
        if (_autopsy!.autopsyCustomerMobile?.isNotEmpty == true)
          _buildInfoRow('Mobile', _autopsy!.autopsyCustomerMobile!),
        if (_autopsy!.autopsyLandlinePhoneNumber?.isNotEmpty == true)
          _buildInfoRow('Landline', _autopsy!.autopsyLandlinePhoneNumber!),
        if (_autopsy!.autopsyCustomerFloor?.isNotEmpty == true)
          _buildInfoRow('Floor', _autopsy!.autopsyCustomerFloor!),
      ],
    );
  }

  Widget _buildTechnicalInfoCard() {
    return _buildInfoCard(
      'Technical Information',
      Icons.engineering_outlined,
      [
        if (_autopsy!.technicalCheckStatus?.isNotEmpty == true)
          _buildStatusRow('Technical Check', _autopsy!.technicalCheckStatus!),
        if (_autopsy!.soilWorkStatus?.isNotEmpty == true)
          _buildStatusRow('Soil Work', _autopsy!.soilWorkStatus!),
        if (_autopsy!.constructionStatus?.isNotEmpty == true)
          _buildStatusRow('Construction', _autopsy!.constructionStatus!),
        if (_autopsy!.splicingStatus?.isNotEmpty == true)
          _buildStatusRow('Splicing', _autopsy!.splicingStatus!),
        if (_autopsy!.billingStatus?.isNotEmpty == true)
          _buildStatusRow('Billing', _autopsy!.billingStatus!),
        if (_autopsy!.autopsyOutOfSystem == true)
          _buildInfoRow('Out of System', 'Yes', color: Colors.orange),
      ],
    );
  }

  Widget _buildStatusHistoryCard() {
    return _buildInfoCard(
      'Status History',
      Icons.timeline_outlined,
      [
        _buildStatusRow('Current Status', _autopsy!.autopsyStatus ?? 'Unknown'),
        if (_autopsy!.createdAt != null)
          _buildInfoRow('Created', _formatDateTime(_autopsy!.createdAt!)),
        if (_autopsy!.modifiedAt != null)
          _buildInfoRow('Last Modified', _formatDateTime(_autopsy!.modifiedAt!)),
      ],
    );
  }

  Widget _buildInfoCard(String title, IconData icon, List<Widget> children) {
    if (children.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: const Color(0xFF1565C0), size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E3A59),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color ?? const Color(0xFF2E3A59),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String status) {
    final statusColor = _getStatusColor(status);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Text(
                _getStatusLabel(status),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        title: const Text('Loading...'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
            ),
            SizedBox(height: 16),
            Text(
              'Loading autopsy details...',
              style: TextStyle(
                color: Color(0xFF2E3A59),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        title: const Text('Error'),
      ),
      body: Center(
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
                'Failed to load autopsy',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? 'Unknown error occurred',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadAutopsy,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
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
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        title: const Text('Not Found'),
      ),
      body: Center(
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
                'Autopsy not found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The requested autopsy could not be found or you don\'t have permission to view it.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        // Navigate to edit screen
        break;
      case 'delete':
        _showDeleteDialog();
        break;
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Delete Autopsy',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to delete this autopsy? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                final repository = context.read<AutopsyRepository>();
                await repository.deleteAutopsy(widget.autopsyId);
                if (mounted) {
                  Navigator.of(context).pop();
                }
              } catch (error) {
                if (mounted) {
                  ErrorHandler.showErrorSnackBar(context, error);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}