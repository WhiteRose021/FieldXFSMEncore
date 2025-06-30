// lib/widgets/professional_autopsy_list_item.dart - Professional FSM UI
import 'package:flutter/material.dart';
import '../models/autopsy_models.dart';

class ProfessionalAutopsyListItem extends StatelessWidget {
  final CAutopsy autopsy;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onCall;
  final VoidCallback? onNavigate;

  const ProfessionalAutopsyListItem({
    Key? key,
    required this.autopsy,
    this.onTap,
    this.onEdit,
    this.onCall,
    this.onNavigate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: SR Number + Priority + Status
              _buildHeaderRow(theme),
              
              const SizedBox(height: 12),
              
              // Customer Information
              _buildCustomerInfo(theme),
              
              const SizedBox(height: 12),
              
              // Address Section
              _buildAddressSection(theme),
              
              const SizedBox(height: 12),
              
              // Service Details
              _buildServiceDetails(theme),
              
              const SizedBox(height: 12),
              
              // Status Timeline
              _buildStatusTimeline(theme),
              
              const SizedBox(height: 12),
              
              // Bottom Actions + Metadata
              _buildBottomSection(theme, context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow(ThemeData theme) {
    return Row(
      children: [
        // Service Request Number
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SR #${autopsy.name ?? autopsy.id.substring(0, 8)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
              if (autopsy.autopsyCategory != null) ...[
                const SizedBox(height: 2),
                Text(
                  AutopsyOptions.getCategoryLabel(autopsy.autopsyCategory!) ?? autopsy.autopsyCategory!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        
        // Priority Indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getPriorityColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _getPriorityColor().withOpacity(0.3)),
          ),
          child: Text(
            _getPriorityLabel(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _getPriorityColor(),
            ),
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Status Chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _getStatusColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _getStatusColor().withOpacity(0.3)),
          ),
          child: Text(
            AutopsyOptions.getStatusLabel(autopsy.autopsyStatus) ?? autopsy.autopsyStatus ?? 'Unknown',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _getStatusColor(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerInfo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, size: 18, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                'Customer Information',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Customer Name
          if (autopsy.autopsyCustomerName?.isNotEmpty == true)
            _buildInfoRow(
              Icons.account_circle_outlined,
              'Name',
              autopsy.autopsyCustomerName!,
              theme,
            ),
          
          // Customer Email  
          if (autopsy.autopsyCustomerEmail?.isNotEmpty == true)
            _buildInfoRow(
              Icons.email_outlined,
              'Email',
              autopsy.autopsyCustomerEmail!,
              theme,
            ),
          
          // Customer Mobile
          if (autopsy.autopsyCustomerMobile?.isNotEmpty == true)
            _buildInfoRow(
              Icons.phone_outlined,
              'Mobile',
              autopsy.autopsyCustomerMobile!,
              theme,
            ),
        ],
      ),
    );
  }

  Widget _buildAddressSection(ThemeData theme) {
    final address = autopsy.fullAddress;
    if (address.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, size: 18, color: Colors.green.shade700),
              const SizedBox(width: 8),
              Text(
                'Service Location',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            address,
            style: theme.textTheme.bodyMedium,
          ),
          if (autopsy.autopsyMunicipality?.isNotEmpty == true ||
              autopsy.autopsyPostalCode?.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                if (autopsy.autopsyMunicipality?.isNotEmpty == true)
                  Text(
                    autopsy.autopsyMunicipality!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (autopsy.autopsyPostalCode?.isNotEmpty == true) ...[
                  const SizedBox(width: 8),
                  Text(
                    autopsy.autopsyPostalCode!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServiceDetails(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.build, size: 18, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Text(
                'Service Details',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          Row(
            children: [
              Expanded(
                child: _buildDetailChip('Technical Check', autopsy.technicalCheckStatus, Colors.blue),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDetailChip('Soil Work', autopsy.soilWorkStatus, Colors.brown),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Row(
            children: [
              Expanded(
                child: _buildDetailChip('Construction', autopsy.constructionStatus, Colors.purple),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDetailChip('Splicing', autopsy.splicingStatus, Colors.teal),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(String label, String? status, Color color) {
    final displayStatus = status ?? 'pending';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color.shade700,
            ),
          ),
          Text(
            displayStatus.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: color.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline, size: 18, color: Colors.grey.shade700),
              const SizedBox(width: 8),
              Text(
                'Timeline',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          Row(
            children: [
              Expanded(
                child: _buildTimelineItem(
                  'Created',
                  autopsy.createdAt,
                  Icons.add_circle_outline,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTimelineItem(
                  'Last Modified',
                  autopsy.updatedAt,
                  Icons.edit_outlined,
                  Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String label, DateTime? date, IconData icon, Color color) {
    final formattedDate = date != null
        ? '${date.day}/${date.month}/${date.year}'
        : '—';
        
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                formattedDate,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSection(ThemeData theme, BuildContext context) {
    return Row(
      children: [
        // Billing Status
        if (autopsy.billingStatus != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: _getBillingStatusColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: _getBillingStatusColor().withOpacity(0.3)),
            ),
            child: Text(
              'Bill: ${autopsy.billingStatus!.toUpperCase()}',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: _getBillingStatusColor(),
              ),
            ),
          ),
        
        const Spacer(),
        
        // Action Buttons
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Call Button
            if (autopsy.autopsyCustomerMobile?.isNotEmpty == true)
              IconButton(
                onPressed: onCall,
                icon: const Icon(Icons.phone, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.green.shade100,
                  foregroundColor: Colors.green.shade700,
                  padding: const EdgeInsets.all(8),
                ),
                tooltip: 'Call Customer',
              ),
            
            // Navigate Button  
            if (autopsy.fullAddress.isNotEmpty)
              IconButton(
                onPressed: onNavigate,
                icon: const Icon(Icons.navigation, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.blue.shade100,
                  foregroundColor: Colors.blue.shade700,
                  padding: const EdgeInsets.all(8),
                ),
                tooltip: 'Navigate',
              ),
            
            // Edit Button
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: Colors.orange.shade100,
                foregroundColor: Colors.orange.shade700,
                padding: const EdgeInsets.all(8),
              ),
              tooltip: 'Edit',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Helper Methods for Colors and Labels
  Color _getStatusColor() {
    switch (autopsy.autopsyStatus?.toLowerCase()) {
      case 'new':
      case 'pending':
        return Colors.orange;
      case 'in_progress':
      case 'assigned':
        return Colors.blue;
      case 'completed':
      case 'autopsy_completed':
        return Colors.green;
      case 'cancelled':
      case 'rejected':
        return Colors.red;
      case 'on_hold':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor() {
    // You can implement priority logic based on age, status, etc.
    final daysSinceCreated = autopsy.createdAt != null
        ? DateTime.now().difference(autopsy.createdAt!).inDays
        : 0;
        
    if (daysSinceCreated > 7) return Colors.red;
    if (daysSinceCreated > 3) return Colors.orange;
    return Colors.green;
  }

  String _getPriorityLabel() {
    final daysSinceCreated = autopsy.createdAt != null
        ? DateTime.now().difference(autopsy.createdAt!).inDays
        : 0;
        
    if (daysSinceCreated > 7) return 'HIGH';
    if (daysSinceCreated > 3) return 'MED';
    return 'LOW';
  }

  Color _getBillingStatusColor() {
    switch (autopsy.billingStatus?.toLowerCase()) {
      case 'ready':
      case 'completed':
        return Colors.green;
      case 'not_ready':
      case 'pending':
        return Colors.orange;
      case 'blocked':
      case 'error':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

extension on Color {
  get shade700 => null;
  
  get shade800 => null;
}