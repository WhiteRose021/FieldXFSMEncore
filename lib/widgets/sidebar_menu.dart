// lib/widgets/sidebar_menu.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/autopsies_screen.dart';
import '../screens/fetch_data_screen.dart';
import '../screens/login_screen.dart';
import '../screens/dashboard_screen.dart';

class SidebarMenu extends StatefulWidget {
  final String currentRoute;
  
  const SidebarMenu({
    super.key,
    required this.currentRoute,
  });

  @override
  State<SidebarMenu> createState() => _SidebarMenuState();
}

class _SidebarMenuState extends State<SidebarMenu> with TickerProviderStateMixin {
  String _userName = '';
  String _tenantName = '';
  bool _isAdmin = false;
  bool _isSuperAdmin = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      _userName = prefs.getString('userName') ?? 'User';
      _tenantName = prefs.getString('tenantName') ?? 'Default';
      _isAdmin = prefs.getBool('isAdmin') ?? false;
      _isSuperAdmin = prefs.getBool('isSuperAdmin') ?? false;
    });
  }

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const EnhancedLoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      print("❌ Logout error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFF8FAFC),
      elevation: 0,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Column(
            children: [
              // Modern Header
              _buildModernHeader(),
              
              // Scrollable Menu Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      
                      // Main Navigation
                      _buildNavigationSection(),
                      
                      const SizedBox(height: 24),
                      
                      // Admin Section (if applicable)
                      if (_isAdmin || _isSuperAdmin) ...[
                        _buildAdminSection(),
                        const SizedBox(height: 24),
                      ],
                      
                      // Reports Section
                      _buildReportsSection(),
                      
                      const SizedBox(height: 24),
                      
                      // Help & Support
                      _buildHelpSection(),
                      
                      const SizedBox(height: 100), // Bottom padding for scroll
                    ],
                  ),
                ),
              ),
              
              // Fixed Bottom Section
              _buildModernFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0071BC),
            Color(0xFF005A94),
            Color(0xFF004A7C),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0071BC).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.business_center,
              color: Colors.white,
              size: 28,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // App Name
          const Text(
            'FieldX FSM',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // User Info Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  _userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_tenantName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _tenantName,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Admin Badge
          if (_isSuperAdmin || _isAdmin) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _isSuperAdmin ? Colors.amber.withOpacity(0.9) : Colors.green.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _isSuperAdmin ? 'SUPER ADMIN' : 'ADMIN',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavigationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Navigation'),
        const SizedBox(height: 12),
        _buildModernMenuItem(
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard,
          title: 'Dashboard',
          route: '/dashboard',
          onTap: () => _navigateTo(context, const DashboardScreen()),
        ),
        const SizedBox(height: 8),
        _buildModernMenuItem(
          icon: Icons.medical_services_outlined,
          activeIcon: Icons.medical_services,
          title: 'Autopsies',
          route: '/autopsies',
          onTap: () => _navigateTo(context, const AutopsiesScreen()),
        ),
      ],
    );
  }

  Widget _buildAdminSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Administration'),
        const SizedBox(height: 12),
        _buildModernMenuItem(
          icon: Icons.settings_outlined,
          activeIcon: Icons.settings,
          title: 'Settings',
          route: '/settings',
          onTap: () => _showComingSoon(context, 'Settings'),
        ),
        if (_isSuperAdmin) ...[
          const SizedBox(height: 8),
          _buildModernMenuItem(
            icon: Icons.admin_panel_settings_outlined,
            activeIcon: Icons.admin_panel_settings,
            title: 'Admin Panel',
            route: '/admin',
            onTap: () => _showComingSoon(context, 'Admin Panel'),
          ),
        ],
      ],
    );
  }

  Widget _buildReportsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Reports'),
        const SizedBox(height: 12),
        _buildModernMenuItem(
          icon: Icons.analytics_outlined,
          activeIcon: Icons.analytics,
          title: 'Analytics',
          route: '/analytics',
          onTap: () => _showComingSoon(context, 'Analytics'),
        ),
        const SizedBox(height: 8),
        _buildModernMenuItem(
          icon: Icons.file_download_outlined,
          activeIcon: Icons.file_download,
          title: 'Export Data',
          route: '/export',
          onTap: () => _showComingSoon(context, 'Export Data'),
        ),
      ],
    );
  }

  Widget _buildHelpSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Support'),
        const SizedBox(height: 12),
        _buildModernMenuItem(
          icon: Icons.help_outline,
          activeIcon: Icons.help,
          title: 'Help & Support',
          route: '/help',
          onTap: () => _showComingSoon(context, 'Help & Support'),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildModernMenuItem({
    required IconData icon,
    required IconData activeIcon,
    required String title,
    required String route,
    required VoidCallback onTap,
  }) {
    final isSelected = widget.currentRoute == route;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF0071BC).withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF0071BC).withOpacity(0.3) : Colors.transparent,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).pop();
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isSelected ? activeIcon : icon,
                    key: ValueKey(isSelected),
                    color: isSelected ? const Color(0xFF0071BC) : Colors.grey[600],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF0071BC) : Colors.grey[800],
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0071BC),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernFooter() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logout Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showLogoutDialog,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: Colors.red[600],
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.red[600],
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.red[400],
                      size: 12,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Version Info
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.grey[400],
                size: 12,
              ),
              const SizedBox(width: 4),
              Text(
                'Version 1.0.0',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.rocket_launch, color: Colors.orange[600], size: 24),
            const SizedBox(width: 8),
            Text('$feature Coming Soon'),
          ],
        ),
        content: Text(
          'The $feature feature is currently under development and will be available in a future update.',
          style: TextStyle(color: Colors.grey[600]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF0071BC),
            ),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('Logout'),
          ],
        ),
        content: const Text('Are you sure you want to logout from your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}