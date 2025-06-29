// lib/screens/debug_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  Map<String, dynamic> _allPrefs = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAllPreferences();
  }

  Future<void> _loadAllPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    Map<String, dynamic> allPrefs = {};
    for (String key in keys) {
      final value = prefs.get(key);
      allPrefs[key] = value;
    }
    
    setState(() {
      _allPrefs = allPrefs;
    });
  }

  Future<void> _clearAllData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All cached data cleared!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Reload preferences
      await _loadAllPreferences();
      
      // Navigate back to start fresh
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error clearing data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearAuthData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Clear all authentication-related keys
      final authKeys = [
        'isLoggedIn',
        'authToken',
        'userName',
        'userId', 
        'userType',
        'crmDomain',
        'password',
        'userLogin',
        'tenantName',
        'teamNames',
        'teamIds',
        'roleNames',
      ];
      
      for (String key in authKeys) {
        await prefs.remove(key);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication data cleared!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Reload preferences
      await _loadAllPreferences();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error clearing auth data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug & Settings'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Actions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _clearAuthData,
                        icon: const Icon(Icons.logout),
                        label: const Text('Clear Auth Data & Force Login'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _clearAllData,
                        icon: const Icon(Icons.delete_forever),
                        label: const Text('Clear All Cached Data'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _loadAllPreferences,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh Data'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Current Settings
            const Text(
              'Current Cached Data:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _allPrefs.isEmpty
                      ? const Center(child: Text('No cached data found'))
                      : ListView.builder(
                          itemCount: _allPrefs.length,
                          itemBuilder: (context, index) {
                            final key = _allPrefs.keys.elementAt(index);
                            final value = _allPrefs[key];
                            
                            return ListTile(
                              title: Text(
                                key,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                value.toString(),
                                style: const TextStyle(fontFamily: 'monospace'),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, size: 16),
                                onPressed: () async {
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.remove(key);
                                  _loadAllPreferences();
                                },
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),
            
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}