import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthenticationService {
  // API-Key is **only** used for read operations and fallback
  static const String _apiKey = '5af9459182c0ae4e1606e5d65864df25';

  // Role & team constants
  static const String SPLICER_ROLE     = 'Field - Splicers';
  static const String CONSTRUCTOR_ROLE = 'Field Builders';
  static const String EARTWORKER_ROLE = 'Field - Earthworkers';
  static const String SPLICER_TEAM     = 'Technicians - Splicers';
  static const String AUTOPSY_TEAM = 'Autopsy';
  static const List<String> CONSTRUCTION_TEAMS = [
  'Technicians',
  'Technicians - Construct',
  'ΚΑΤ Δ',
  'ΚΑΤ Γ',
  'ΚΑΤ Β',
  'ΚΑΤ Α'
];


  // ──────────────────────────────────────────────────────────────────────────
  Future<String?> _getCRMBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('crmDomain');
  }

  /// Fetch detailed team information for a user
  Future<Map<String, dynamic>> _fetchUserTeamDetails(String userId, String basicAuth, String crmBaseUrl) async {
    print("🔍 Fetching detailed team information for user: $userId");
    
    Map<String, dynamic> teamDetails = {
      'teams': <Map<String, dynamic>>[],
      'teamIds': <String>[],
      'teamNames': <String>[],
      'splicerTeam': null,
      'autopsyTeam': null,
      'hasTeamAccess': false,
    };
    
    try {
      // Fetch user's team associations
      final userTeamsRes = await http.get(
        Uri.parse('$crmBaseUrl/api/v1/User/$userId/teams'),
        headers: {
          'Authorization': 'Basic $basicAuth',
          'X-Api-Key': _apiKey,
        },
      );
      
      if (userTeamsRes.statusCode == 200) {
        final userTeamsData = json.decode(userTeamsRes.body);
        final teamList = userTeamsData['list'] as List<dynamic>? ?? [];
        
        print("✅ Found ${teamList.length} team associations");
        
        for (var teamAssociation in teamList) {
          final teamId = teamAssociation['id'] as String?;
          final teamName = teamAssociation['name'] as String?;
          
          if (teamId != null && teamName != null) {
            teamDetails['teamIds'].add(teamId);
            teamDetails['teamNames'].add(teamName);
            
            // Fetch detailed information for each team
            final teamDetailRes = await http.get(
              Uri.parse('$crmBaseUrl/api/v1/Team/$teamId'),
              headers: {
                'Authorization': 'Basic $basicAuth',
                'X-Api-Key': _apiKey,
              },
            );
            
            if (teamDetailRes.statusCode == 200) {
              final teamDetail = json.decode(teamDetailRes.body);
              teamDetails['teams'].add({
                'id': teamId,
                'name': teamName,
                'description': teamDetail['description'] ?? '',
                'createdAt': teamDetail['createdAt'] ?? '',
                'modifiedAt': teamDetail['modifiedAt'] ?? '',
                'positionList': teamDetail['positionList'] ?? [],
              });
              
              print("📋 Team details: $teamName ($teamId)");
              
              // Check for specific teams we care about
              if (teamName == SPLICER_TEAM || teamName.toLowerCase().contains('splicer')) {
                teamDetails['splicerTeam'] = {
                  'id': teamId,
                  'name': teamName,
                  'description': teamDetail['description'] ?? '',
                  'positionList': teamDetail['positionList'] ?? [],
                };
                print("🔌 Splicer team found: $teamName");
              }
              
              if (teamName == AUTOPSY_TEAM || teamName.toLowerCase().contains('autopsy')) {
                teamDetails['autopsyTeam'] = {
                  'id': teamId,
                  'name': teamName,
                  'description': teamDetail['description'] ?? '',
                  'positionList': teamDetail['positionList'] ?? [],
                };
                print("🔍 Autopsy team found: $teamName");
              }
            } else {
              print("⚠️ Could not fetch details for team $teamName: ${teamDetailRes.statusCode}");
            }
          }
        }
        
        teamDetails['hasTeamAccess'] = teamDetails['teamIds'].isNotEmpty;
        
      } else {
        print("⚠️ Could not fetch user teams: ${userTeamsRes.statusCode}");
        print("📝 Response: ${userTeamsRes.body}");
      }
      
    } catch (e) {
      print("❌ Error fetching team details: $e");
    }
    
    return teamDetails;
  }

  /// Fetch team permissions for CSplicingWork entity
  Future<Map<String, dynamic>> _fetchTeamPermissions(List<String> teamIds, String basicAuth, String crmBaseUrl) async {
    print("🔒 Checking team permissions for CSplicingWork entity...");
    
    Map<String, dynamic> permissions = {
      'canReadCSplicingWork': false,
      'canEditCSplicingWork': false,
      'canCreateCSplicingWork': false,
      'canDeleteCSplicingWork': false,
      'fieldPermissions': <String, bool>{},
      'teamPermissionDetails': <Map<String, dynamic>>[],
    };
    
    try {
      // Check each team's access to CSplicingWork
      for (String teamId in teamIds) {
        final permissionRes = await http.get(
          Uri.parse('$crmBaseUrl/api/v1/Team/$teamId/acl'),
          headers: {
            'Authorization': 'Basic $basicAuth',
            'X-Api-Key': _apiKey,
          },
        );
        
        if (permissionRes.statusCode == 200) {
          final permissionData = json.decode(permissionRes.body);
          final cSplicingWorkPerms = permissionData['CSplicingWork'] as Map<String, dynamic>?;
          
          if (cSplicingWorkPerms != null) {
            permissions['teamPermissionDetails'].add({
              'teamId': teamId,
              'permissions': cSplicingWorkPerms,
            });
            
            // Update overall permissions (if any team has access, user has access)
            if (cSplicingWorkPerms['read'] == 'yes' || cSplicingWorkPerms['read'] == true) {
              permissions['canReadCSplicingWork'] = true;
            }
            if (cSplicingWorkPerms['edit'] == 'yes' || cSplicingWorkPerms['edit'] == true) {
              permissions['canEditCSplicingWork'] = true;
            }
            if (cSplicingWorkPerms['create'] == 'yes' || cSplicingWorkPerms['create'] == true) {
              permissions['canCreateCSplicingWork'] = true;
            }
            if (cSplicingWorkPerms['delete'] == 'yes' || cSplicingWorkPerms['delete'] == true) {
              permissions['canDeleteCSplicingWork'] = true;
            }
            
            print("✅ Team $teamId CSplicingWork permissions: $cSplicingWorkPerms");
          }
        } else {
          print("⚠️ Could not fetch permissions for team $teamId: ${permissionRes.statusCode}");
        }
      }
      
    } catch (e) {
      print("❌ Error fetching team permissions: $e");
    }
    
    return permissions;
  }

  /// Returns `true` only when the **real password** is correct.
  /// ENHANCED: Now fetches and stores detailed team information
  Future<bool> signIn(String username, String password) async {
    // 0. Early validation
    if (username.isEmpty || password.isEmpty) return false;

    final prefs      = await SharedPreferences.getInstance();
    var   crmBaseUrl = await _getCRMBaseUrl();
    if (crmBaseUrl == null) return false;

    // Allow plain HTTP if someone stored an HTTPS URL
    if (crmBaseUrl.startsWith('https://')) {
      crmBaseUrl = crmBaseUrl.replaceFirst('https://', 'http://');
    }

    // 1. Password check – *without* X-Api-Key (this is crucial!)
    final basicAuth = base64Encode(utf8.encode('$username:$password'));
    final authRes   = await http.get(
      Uri.parse('$crmBaseUrl/api/v1/App/user'),
      headers: {
        'Authorization': 'Basic $basicAuth',
        // ⚠️  No X-Api-Key here, otherwise the server bypasses password check
      },
    );

    if (authRes.statusCode != 200) {
      print("❌ Password verification failed: ${authRes.statusCode}");
      return false;
    }

    print("✅ Password verification successful");

    // 2. Fetch user list – now it's safe to send the key for performance
    final usersRes = await http.get(
      Uri.parse('$crmBaseUrl/api/v1/User'),
      headers: {
        'Authorization': 'Basic $basicAuth',
        'X-Api-Key': _apiKey,
      },
    );
    if (usersRes.statusCode != 200) return false;

    final usersJson = json.decode(usersRes.body);
    final list      = usersJson['list'] as List<dynamic>?;

    if (list == null) return false;

    final me = list.firstWhere(
      (u) => u['userName'].toString().toLowerCase() == username.toLowerCase(),
      orElse: () => null,
    );
    if (me == null) return false;

    final userId = me['id'] as String;

    // 3. Detailed user info
    final detailRes = await http.get(
      Uri.parse('$crmBaseUrl/api/v1/User/$userId'),
      headers: {
        'Authorization': 'Basic $basicAuth',
        'X-Api-Key': _apiKey,
      },
    );
    if (detailRes.statusCode != 200) return false;

    final details   = json.decode(detailRes.body);
    final teamNames = (details['teamsNames'] ?? {}).values.cast<String>().toList();
    final roleNames = (details['rolesNames'] ?? {}).values.cast<String>().toList();

    String displayName = details['name'] ?? details['fullName'] ?? details['firstName'] ?? me['name'];

    // 4. ENHANCED: Fetch detailed team information
    print("🔍 Fetching detailed team information...");
    final teamDetails = await _fetchUserTeamDetails(userId, basicAuth, crmBaseUrl);
    final teamPermissions = await _fetchTeamPermissions(
      teamDetails['teamIds'].cast<String>(), 
      basicAuth, 
      crmBaseUrl
    );

    // Check for specific team memberships
    bool isAutopsyUser = teamNames.contains(AUTOPSY_TEAM) || teamDetails['autopsyTeam'] != null;
    bool isSplicerUser = teamNames.contains(SPLICER_TEAM) || teamDetails['splicerTeam'] != null;
    bool isConstructionUser = false;

    for (String constructionTeam in CONSTRUCTION_TEAMS) {
      if (teamNames.contains(constructionTeam)) {
        isConstructionUser = true;
        break;
      }
    }

    if (roleNames.contains(CONSTRUCTOR_ROLE)) {
      isConstructionUser = true;
    }


    // Enhanced logging
    print("🔍 === USER AUTHENTICATION SUMMARY ===");
    print("👤 User: $displayName ($userId)");
    print("🎭 Roles: $roleNames");
    print("🏢 Teams: $teamNames");
    print("🆔 Team IDs: ${teamDetails['teamIds']}");
    print("🔌 Has Splicer Team: $isSplicerUser");
    print("🔍 Has Autopsy Team: $isAutopsyUser");
    print("📊 Team Count: ${teamDetails['teams'].length}");
    print("🔒 CSplicingWork Permissions:");
    print("   📖 Can Read: ${teamPermissions['canReadCSplicingWork']}");
    print("   ✏️  Can Edit: ${teamPermissions['canEditCSplicingWork']}");
    print("   ➕ Can Create: ${teamPermissions['canCreateCSplicingWork']}");
    print("   🗑️  Can Delete: ${teamPermissions['canDeleteCSplicingWork']}");
    
    if (teamDetails['splicerTeam'] != null) {
      print("🔌 Splicer Team Details: ${teamDetails['splicerTeam']}");
    }
    if (teamDetails['autopsyTeam'] != null) {
      print("🔍 Autopsy Team Details: ${teamDetails['autopsyTeam']}");
    }

    // 5. ENHANCED: Store everything including detailed team information
    await prefs
      ..setString('userId',   userId)
      ..setString('userName', displayName)
      ..setString('userLogin', username)
      ..setString('password', password)
      ..setString('authToken', basicAuth)
      ..setStringList('teamNames', teamNames)
      ..setStringList('teamIds', teamDetails['teamIds'].cast<String>())
      ..setStringList('roleNames', roleNames)
      ..setString('teamsDetailJson', json.encode(teamDetails['teams']))
      ..setString('teamPermissionsJson', json.encode(teamPermissions))
      ..setBool('isTechnicianSplicer', isSplicerUser || roleNames.contains(SPLICER_ROLE))
      ..setBool('isTechnicianConstruct', roleNames.contains(CONSTRUCTOR_ROLE))
      ..setBool('isTechnicianEarthworker', roleNames.contains(EARTWORKER_ROLE))
      ..setBool('isTechnicianAutopsy', isAutopsyUser)
      ..setBool('hasTeamAccess', teamDetails['hasTeamAccess'])
      ..setBool('canReadCSplicingWork', teamPermissions['canReadCSplicingWork'])
      ..setBool('canEditCSplicingWork', teamPermissions['canEditCSplicingWork']);

    // Store specific team details if available
    if (teamDetails['splicerTeam'] != null) {
      await prefs.setString('splicerTeamJson', json.encode(teamDetails['splicerTeam']));
    }
    if (teamDetails['autopsyTeam'] != null) {
      await prefs.setString('autopsyTeamJson', json.encode(teamDetails['autopsyTeam']));
    }

    print("✅ User credentials and team details stored successfully");
    print("=== END AUTHENTICATION SUMMARY ===");
    
    return true;
  }

  /// Get user's splicer team information
  static Future<Map<String, dynamic>?> getSplicerTeam() async {
    final prefs = await SharedPreferences.getInstance();
    final splicerTeamJson = prefs.getString('splicerTeamJson');
    
    if (splicerTeamJson != null) {
      try {
        return json.decode(splicerTeamJson) as Map<String, dynamic>;
      } catch (e) {
        print("❌ Error parsing splicer team JSON: $e");
      }
    }
    
    return null;
  }

  /// Get user's autopsy team information
  static Future<Map<String, dynamic>?> getAutopsyTeam() async {
    final prefs = await SharedPreferences.getInstance();
    final autopsyTeamJson = prefs.getString('autopsyTeamJson');
    
    if (autopsyTeamJson != null) {
      try {
        return json.decode(autopsyTeamJson) as Map<String, dynamic>;
      } catch (e) {
        print("❌ Error parsing autopsy team JSON: $e");
      }
    }
    
    return null;
  }

  /// Get all user team details
  static Future<List<Map<String, dynamic>>> getUserTeams() async {
    final prefs = await SharedPreferences.getInstance();
    final teamsDetailJson = prefs.getString('teamsDetailJson');
    
    if (teamsDetailJson != null) {
      try {
        final teamsList = json.decode(teamsDetailJson) as List<dynamic>;
        return teamsList.cast<Map<String, dynamic>>();
      } catch (e) {
        print("❌ Error parsing teams detail JSON: $e");
      }
    }
    
    return [];
  }

  /// Get user's CSplicingWork permissions
  static Future<Map<String, bool>> getCSplicingWorkPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    
    return {
      'canRead': prefs.getBool('canReadCSplicingWork') ?? false,
      'canEdit': prefs.getBool('canEditCSplicingWork') ?? false,
      'hasTeamAccess': prefs.getBool('hasTeamAccess') ?? false,
    };
  }

  /// Check if user has specific team access
  static Future<bool> hasTeam(String teamName) async {
    final prefs = await SharedPreferences.getInstance();
    final teamNames = prefs.getStringList('teamNames') ?? [];
    return teamNames.contains(teamName);
  }

  /// Get headers for read operations (fast, using API key)
  static Future<Map<String, String>> getReadHeaders() async {
    return {
      'X-Api-Key': _apiKey,
      'Content-Type': 'application/json',
    };
  }

  /// Get headers for write operations (proper user attribution)
  static Future<Map<String, String>> getWriteHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final userLogin = prefs.getString('userLogin');
    final password = prefs.getString('password');
    
    if (userLogin == null || password == null) {
      print("⚠️ User credentials not found, falling back to API key");
      return {
        'X-Api-Key': _apiKey,
        'Content-Type': 'application/json',
      };
    }
    
    final basicAuth = base64Encode(utf8.encode('$userLogin:$password'));
    return {
      'Authorization': 'Basic $basicAuth',
      'Content-Type': 'application/json',
      // ⚠️ Deliberately NOT including X-Api-Key here for proper user attribution
    };
  }

  /// Get fallback headers when user auth fails
  static Future<Map<String, String>> getFallbackHeaders() async {
    return {
      'X-Api-Key': _apiKey,
      'Content-Type': 'application/json',
    };
  }

  /// Sign out and clear stored credentials
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('userName');
    await prefs.remove('userLogin');
    await prefs.remove('password');
    await prefs.remove('authToken');
    await prefs.remove('teamNames');
    await prefs.remove('teamIds');
    await prefs.remove('roleNames');
    await prefs.remove('teamsDetailJson');
    await prefs.remove('teamPermissionsJson');
    await prefs.remove('splicerTeamJson');
    await prefs.remove('autopsyTeamJson');
    await prefs.remove('isTechnicianSplicer');
    await prefs.remove('isTechnicianConstruct');
    await prefs.remove('isTechnicianEarthworker');
    await prefs.remove('isTechnicianAutopsy');
    await prefs.remove('hasTeamAccess');
    await prefs.remove('canReadCSplicingWork');
    await prefs.remove('canEditCSplicingWork');
    print("✅ User signed out and credentials cleared");
  }
}