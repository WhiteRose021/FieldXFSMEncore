// lib/screens/dashboard_screen.dart
import 'package:fieldx_fsm/models/user.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/sidebar_menu.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  User? _currentUser;
  Map<String, dynamic>? _userInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Get current user from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      
      final userId = prefs.getString('userId');
      final username = prefs.getString('userName');
      
      if (userId == null || username == null) {
        // No valid session, redirect to login
        _redirectToLogin();
        return;
      }

      // Load user info from SharedPreferences
      final userInfo = {
        'id': userId,
        'username': username,
        'type': prefs.getString('userType') ?? 'regular',
        'firstName': prefs.getString('firstName') ?? '',
        'lastName': prefs.getString('lastName') ?? '',
        'tenantId': prefs.getString('tenantId') ?? '',
        'tenantName': prefs.getString('tenantName') ?? '',
        'permissions': {
          'isAdmin': prefs.getBool('isAdmin') ?? false,
          'isSuperAdmin': prefs.getBool('isSuperAdmin') ?? false,
          'canExport': prefs.getBool('canExport') ?? false,
          'canMassUpdate': prefs.getBool('canMassUpdate') ?? false,
          'canAudit': prefs.getBool('canAudit') ?? false,
          'canManageUsers': prefs.getBool('canManageUsers') ?? false,
        },
        'teams': prefs.getStringList('teamNames') ?? [],
        'roles': prefs.getStringList('roleNames') ?? [],
        'technicianFlags': {
          'autopsy': prefs.getBool('isTechnicianAutopsy') ?? false,
          'splicer': prefs.getBool('isTechnicianSplicer') ?? false,
          'construct': prefs.getBool('isTechnicianConstruct') ?? false,
          'earthworker': prefs.getBool('isTechnicianEarthworker') ?? false,
        },
      };

      setState(() {
        _userInfo = userInfo;
        _isLoading = false;
      });

      print("✅ Dashboard loaded for user: $username");
      print("🎭 User permissions loaded: ${userInfo['permissions']}");
      
    } catch (e) {
      print("❌ Error loading user data: $e");
      _redirectToLogin();
    }
  }

  void _redirectToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const EnhancedLoginScreen(),
      ),
    );
  }

  Future<void> _logout() async {
    try {
      // Clear stored data
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      _redirectToLogin();
    } catch (e) {
      print("❌ Logout error: $e");
      // Still redirect to login even if logout fails
      _redirectToLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_userInfo == null) {
      return const Scaffold(
        body: Center(
          child: Text('No user data available'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('FieldX Dashboard'),
        backgroundColor: const Color(0xFF0071BC),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => _showComingSoon('Notifications'),
            tooltip: 'Notifications',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: const SidebarMenu(currentRoute: '/dashboard'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Stats Summary at the top
            _buildQuickStatsSummary(),
            const SizedBox(height: 16),
            
            // Your existing detailed cards
            _buildUserInfoCard(),
            const SizedBox(height: 16),
            _buildPermissionsCard(),
            const SizedBox(height: 16),
            if (_userInfo != null) ...[
              _buildRolesCard(),
              const SizedBox(height: 16),
              _buildTeamsCard(),
              const SizedBox(height: 16),
            ],
            
            // Quick Actions
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsSummary() {
    final permissions = _userInfo!['permissions'] as Map<String, dynamic>;
    final roles = _userInfo!['roles'] as List<String>;
    final teams = _userInfo!['teams'] as List<String>;
    
    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0071BC),
              Color(0xFF005A94),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, ${_getDisplayName(_userInfo!)}!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tenant: ${_userInfo!['tenantName']?.isNotEmpty == true ? _userInfo!['tenantName'] : 'Default'}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            
            // Quick stats row
            Row(
              children: [
                Expanded(
                  child: _buildStatChip(
                    'Roles', 
                    roles.length.toString(), 
                    Icons.group,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatChip(
                    'Teams', 
                    teams.length.toString(), 
                    Icons.people,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatChip(
                    'Access Level', 
                    permissions['isSuperAdmin'] ? 'Super' : permissions['isAdmin'] ? 'Admin' : 'User',
                    Icons.security,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.flash_on,
                  color: Color(0xFF0071BC),
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Action buttons grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: [
                _buildActionButton(
                  'View Autopsies',
                  Icons.medical_services,
                  Colors.blue,
                  () => Navigator.pushNamed(context, '/autopsies'),
                ),
                _buildActionButton(
                  'Analytics',
                  Icons.analytics,
                  Colors.green,
                  () => _showComingSoon('Analytics'),
                ),
                _buildActionButton(
                  'Settings',
                  Icons.settings,
                  Colors.grey,
                  () => _showComingSoon('Settings'),
                ),
                _buildActionButton(
                  'Export Data',
                  Icons.file_download,
                  Colors.purple,
                  () => _showComingSoon('Export Data'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    final userInfo = _userInfo!;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.person,
                  color: Color(0xFF0071BC),
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'User Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Username', userInfo['username']),
            _buildInfoRow('Display Name', _getDisplayName(userInfo)),
            _buildInfoRow('User Type', userInfo['type'].toString().toUpperCase()),
            _buildInfoRow('Tenant', userInfo['tenantName']?.isNotEmpty == true ? userInfo['tenantName'] : 'Default'),
          ],
        ),
      ),
    );
  }

  String _getDisplayName(Map<String, dynamic> userInfo) {
    final firstName = userInfo['firstName'] as String? ?? '';
    final lastName = userInfo['lastName'] as String? ?? '';
    final username = userInfo['username'] as String? ?? '';
    
    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      return '$firstName $lastName'.trim();
    }
    return username;
  }

  Widget _buildPermissionsCard() {
    final permissions = _userInfo!['permissions'] as Map<String, dynamic>;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.security,
                  color: Color(0xFF0071BC),
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Permissions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPermissionRow('Administrator', permissions['isAdmin'] ?? false),
            _buildPermissionRow('Super Administrator', permissions['isSuperAdmin'] ?? false),
            _buildPermissionRow('Export Data', permissions['canExport'] ?? false),
            _buildPermissionRow('Mass Update', permissions['canMassUpdate'] ?? false),
            _buildPermissionRow('Audit Access', permissions['canAudit'] ?? false),
            _buildPermissionRow('Manage Users', permissions['canManageUsers'] ?? false),
          ],
        ),
      ),
    );
  }

  Widget _buildRolesCard() {
    final roles = _userInfo!['roles'] as List<String>;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.group,
                  color: Color(0xFF0071BC),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Roles (${roles.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (roles.isEmpty)
              const Text(
                'No roles assigned',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              ...roles.map((role) => _buildRoleItem(role)),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamsCard() {
    final teams = _userInfo!['teams'] as List<String>;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.people,
                  color: Color(0xFF0071BC),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Teams (${teams.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (teams.isEmpty)
              const Text(
                'No teams assigned',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              ...teams.map((team) => _buildTeamItem(team)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionRow(String permission, bool hasPermission) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            hasPermission ? Icons.check_circle : Icons.cancel,
            color: hasPermission ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              permission,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: hasPermission ? Colors.green[700] : Colors.red[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleItem(String roleName) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.badge,
            color: Color(0xFF0071BC),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              roleName,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamItem(String teamName) {
    // Default role for teams when we only have the name
    Color roleColor = Colors.blue;
    IconData roleIcon = Icons.person;
    String roleText = 'MEMBER';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: roleColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: roleColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            roleIcon,
            color: roleColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teamName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  roleText,
                  style: TextStyle(
                    fontSize: 12,
                    color: roleColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$feature Coming Soon'),
        content: Text('The $feature feature is currently under development.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}