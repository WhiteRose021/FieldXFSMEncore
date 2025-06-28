// lib/repositories/autopsy_repository.dart
import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../models/autopsy_models.dart';
import '../services/autopsy_client.dart';
// Add the following import if AutopsyResponse is defined elsewhere:
import '../models/autopsy_models.dart';

/// State management and business logic for autopsies
class AutopsyRepository extends ChangeNotifier {
  final AutopsyClient _client;
  
  // List state
  List<CAutopsy> _autopsies = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  int _pageSize = 20;
  int _totalCount = 0;
  bool _hasMore = true;
  
  // Filters and search
  String? _searchQuery;
  String? _statusFilter;
  String? _categoryFilter;
  
  // Detail state
  final Map<String, CAutopsy> _detailCache = {};
  final Set<String> _loadingDetails = {};
  
  // Permissions
  AutopsyPermissions? _permissions;
  DateTime? _permissionsLoadedAt;
  final Duration _permissionsCacheDuration = const Duration(minutes: 5);
  
  // Selected items for bulk operations
  final Set<String> _selectedItems = {};

  AutopsyRepository({required AutopsyClient client}) : _client = client;

  // ============= GETTERS =============

  List<CAutopsy> get autopsies => List.unmodifiable(_autopsies);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalCount => _totalCount;
  bool get hasMore => _hasMore;
  
  String? get searchQuery => _searchQuery;
  String? get statusFilter => _statusFilter;
  String? get categoryFilter => _categoryFilter;
  
  AutopsyPermissions? get permissions => _permissions;
  bool get hasPermissions => _permissions != null;
  
  Set<String> get selectedItems => Set.unmodifiable(_selectedItems);
  bool get hasSelectedItems => _selectedItems.isNotEmpty;
  int get selectedCount => _selectedItems.length;

  // Permission getters with defaults
  bool get canCreate => _permissions?.canCreate ?? false;
  bool get canEdit => _permissions?.canEdit ?? false;
  bool get canDelete => _permissions?.canDelete ?? false;
  bool get canRestore => _permissions?.canRestore ?? false;
  bool get canViewDeleted => _permissions?.canViewDeleted ?? false;

  // ============= LIST OPERATIONS =============

  /// Load initial autopsy list
Future<void> loadAutopsies({
  bool refresh = false,
  String? search,
  String? status,
  String? category,
}) async {
  if (_isLoading && !refresh) return;

  try {
    _setLoading(true);
    _setError(null);

    // Update filters if provided
    if (search != _searchQuery || 
        status != _statusFilter || 
        category != _categoryFilter) {
      _searchQuery = search;
      _statusFilter = status;
      _categoryFilter = category;
      _currentPage = 1;
      if (!refresh) _autopsies.clear();
    }

    final params = ListAutopsyParams(
      limit: _pageSize,
      offset: refresh ? 0 : (_currentPage - 1) * _pageSize,
      orderBy: 'modified_at',
      orderDirection: 'DESC',
      search: _searchQuery,
      status: _statusFilter,
      category: _categoryFilter,
    );

    // FIX: Use AutopsyResponse instead of ListAutopsyResponse
    final AutopsyResponse response = await _client.listAutopsies(params);
    
    if (response.data.isEmpty && _currentPage > 1) {
      // No more data available, reset pagination
      _currentPage--;
      _hasMore = false;
    }
    
    if (refresh || _currentPage == 1) {
      _autopsies = response.data;
    } else {
      _autopsies.addAll(response.data);
    }

    _totalCount = response.total;
    _hasMore = _autopsies.length < _totalCount;
    
    if (refresh) _currentPage = 1;

    _debugLog('✅ Loaded autopsies', {
      'count': response.data.length,
      'total': _totalCount,
      'page': _currentPage,
      'hasMore': _hasMore,
    });

  } catch (error) {
    _setError('Failed to load autopsies: ${error.toString()}');
    _debugLog('❌ Failed to load autopsies', error);
  } finally {
    _setLoading(false);
  }
}


  /// Load more autopsies (pagination)
  Future<void> loadMoreAutopsies() async {
    if (_isLoadingMore || !_hasMore) return;

    try {
      _isLoadingMore = true;
      notifyListeners();

      _currentPage++;
      
      final params = ListAutopsyParams(
        limit: _pageSize,
        offset: (_currentPage - 1) * _pageSize,
        orderBy: 'modified_at',
        orderDirection: 'DESC',
        search: _searchQuery,
        status: _statusFilter,
        category: _categoryFilter,
      );

      final AutopsyResponse response = await _client.listAutopsies(params) as AutopsyResponse;
      
      _autopsies.addAll(response.data);
      _hasMore = _autopsies.length < response.total;

      _debugLog('✅ Loaded more autopsies', {
        'newCount': response.data.length,
        'totalCount': _autopsies.length,
        'hasMore': _hasMore,
      });

    } catch (error) {
      _currentPage--; // Revert page increment on error
      _setError('Failed to load more autopsies: ${error.toString()}');
      _debugLog('❌ Failed to load more autopsies', error);
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Refresh the autopsy list
  /// Refresh autopsies (public method)
  Future<void> refreshAutopsies() async {
    await loadAutopsies(refresh: true);
  }

  /// Search autopsies
  Future<void> searchAutopsies(String query) async {
    if (query.trim().isEmpty) {
      await clearSearch();
      return;
    }

    try {
      _setLoading(true);
      _setError(null);

      final params = SearchAutopsyParams(
        query: query.trim(),
        limit: _pageSize,
      );

      final response = await _client.searchAutopsies(params);
      
      _autopsies = response.data;
      _searchQuery = query.trim();
      _totalCount = response.total;
      _currentPage = 1;
      _hasMore = false; // Search results are typically not paginated

      _debugLog('✅ Search completed', {
        'query': query,
        'resultsCount': response.data.length,
      });

    } catch (error) {
      _setError('Search failed: ${error.toString()}');
      _debugLog('❌ Search failed', error);
    } finally {
      _setLoading(false);
    }
  }

  /// Clear search and reload
  Future<void> clearSearch() async {
    _searchQuery = null;
    await loadAutopsies(refresh: true);
  }

  /// Apply filters
  Future<void> applyFilters({
    String? status,
    String? category,
  }) async {
    await loadAutopsies(
      refresh: true,
      search: _searchQuery,
      status: status,
      category: category,
    );
  }

  /// Clear all filters
  Future<void> clearFilters() async {
    await loadAutopsies(refresh: true);
  }

  // ============= DETAIL OPERATIONS =============

  /// Get autopsy by ID (with caching)
  Future<CAutopsy?> getAutopsy(String id, {bool forceRefresh = false}) async {
    // Check cache first
    if (!forceRefresh && _detailCache.containsKey(id)) {
      return _detailCache[id];
    }

    // Check if already loading
    if (_loadingDetails.contains(id)) {
      // Wait for existing request
      while (_loadingDetails.contains(id)) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _detailCache[id];
    }

    try {
      _loadingDetails.add(id);
      
      final response = await _client.getAutopsy(id);
      
      if (response.data != null) {
        _detailCache[id] = response.data!;
        
        // Update list cache if item exists
        final index = _autopsies.indexWhere((a) => a.id == id);
        if (index != -1) {
          _autopsies[index] = response.data!;
          notifyListeners();
        }
        
        return response.data;
      } else if (response.permissionDenied == true) {
        throw AutopsyPermissionException(
          message: 'Permission denied to view this autopsy',
        );
      } else {
        throw AutopsyNotFoundException(
          message: 'Autopsy not found',
        );
      }
    } catch (error) {
      _debugLog('❌ Failed to get autopsy $id', error);
      rethrow;
    } finally {
      _loadingDetails.remove(id);
    }
  }

  /// Create new autopsy
  Future<CAutopsy> createAutopsy(CreateAutopsyRequest request) async {
    try {
      final autopsy = await _client.createAutopsy(request);
      
      // Add to beginning of list
      _autopsies.insert(0, autopsy);
      _totalCount++;
      
      // Cache detail
      _detailCache[autopsy.id] = autopsy;
      
      notifyListeners();
      
      _debugLog('✅ Created autopsy', {'id': autopsy.id});
      return autopsy;
    } catch (error) {
      _debugLog('❌ Failed to create autopsy', error);
      rethrow;
    }
  }

  /// Update autopsy
  Future<CAutopsy> updateAutopsy(String id, UpdateAutopsyRequest request) async {
    try {
      final updatedAutopsy = await _client.updateAutopsy(id, request);
      
      // Update in list
      final index = _autopsies.indexWhere((a) => a.id == id);
      if (index != -1) {
        _autopsies[index] = updatedAutopsy;
      }
      
      // Update detail cache
      _detailCache[id] = updatedAutopsy;
      
      notifyListeners();
      
      _debugLog('✅ Updated autopsy', {'id': id});
      return updatedAutopsy;
    } catch (error) {
      _debugLog('❌ Failed to update autopsy $id', error);
      rethrow;
    }
  }

  /// Delete autopsy
  Future<void> deleteAutopsy(String id) async {
    try {
      await _client.deleteAutopsy(id);
      
      // Remove from list
      _autopsies.removeWhere((a) => a.id == id);
      _totalCount = (_totalCount - 1).clamp(0, double.infinity).toInt();
      
      // Remove from cache
      _detailCache.remove(id);
      _selectedItems.remove(id);
      
      notifyListeners();
      
      _debugLog('✅ Deleted autopsy', {'id': id});
    } catch (error) {
      _debugLog('❌ Failed to delete autopsy $id', error);
      rethrow;
    }
  }

  /// Restore autopsy
  Future<CAutopsy> restoreAutopsy(String id) async {
    try {
      final restoredAutopsy = await _client.restoreAutopsy(id);
      
      // Update in list if exists
      final index = _autopsies.indexWhere((a) => a.id == id);
      if (index != -1) {
        _autopsies[index] = restoredAutopsy;
      } else {
        // Add back to list
        _autopsies.insert(0, restoredAutopsy);
        _totalCount++;
      }
      
      // Update detail cache
      _detailCache[id] = restoredAutopsy;
      
      notifyListeners();
      
      _debugLog('✅ Restored autopsy', {'id': id});
      return restoredAutopsy;
    } catch (error) {
      _debugLog('❌ Failed to restore autopsy $id', error);
      rethrow;
    }
  }

  // ============= PERMISSION OPERATIONS =============

  /// Load user permissions
  Future<void> loadPermissions({bool refresh = false}) async {
    // Check cache
    if (!refresh && 
        _permissions != null && 
        _permissionsLoadedAt != null &&
        DateTime.now().difference(_permissionsLoadedAt!) < _permissionsCacheDuration) {
      return;
    }

    try {
      _permissions = await _client.getPermissions();
      _permissionsLoadedAt = DateTime.now();
      notifyListeners();
      
      _debugLog('✅ Loaded permissions', {
        'canCreate': _permissions?.canCreate,
        'canEdit': _permissions?.canEdit,
        'canDelete': _permissions?.canDelete,
      });
    } catch (error) {
      _debugLog('❌ Failed to load permissions', error);
      // Set default permissions on error
      _permissions = AutopsyPermissions.defaultPermissions();
      _permissionsLoadedAt = DateTime.now();
      notifyListeners();
    }
  }

  /// Check if field is visible
  bool isFieldVisible(String fieldName) {
    if (_permissions == null) return true;
    return _permissions!.visibleFields.isEmpty || 
           _permissions!.visibleFields.contains(fieldName);
  }

  /// Check if field is editable
  bool isFieldEditable(String fieldName) {
    if (_permissions == null) return false;
    return _permissions!.editableFields.contains(fieldName);
  }

  /// Check if can perform action
  bool canPerformAction(String action) {
    if (_permissions == null) return false;
    
    switch (action) {
      case 'create':
        return _permissions!.canCreate;
      case 'read':
        return _permissions!.canRead;
      case 'edit':
        return _permissions!.canEdit;
      case 'delete':
        return _permissions!.canDelete;
      case 'restore':
        return _permissions!.canRestore;
      case 'permanent_delete':
        return _permissions!.canPermanentDelete;
      case 'view_deleted':
        return _permissions!.canViewDeleted;
      default:
        return false;
    }
  }

  // ============= SELECTION OPERATIONS =============

  /// Select autopsy
  void selectAutopsy(String id) {
    _selectedItems.add(id);
    notifyListeners();
  }

  /// Deselect autopsy
  void deselectAutopsy(String id) {
    _selectedItems.remove(id);
    notifyListeners();
  }

  /// Toggle autopsy selection
  void toggleSelection(String id) {
    if (_selectedItems.contains(id)) {
      deselectAutopsy(id);
    } else {
      selectAutopsy(id);
    }
  }

  /// Select all visible autopsies
  void selectAll() {
    _selectedItems.addAll(_autopsies.map((a) => a.id));
    notifyListeners();
  }

  /// Clear all selections
  void clearSelection() {
    _selectedItems.clear();
    notifyListeners();
  }

  /// Check if autopsy is selected
  bool isSelected(String id) {
    return _selectedItems.contains(id);
  }

  /// Get selected autopsies
  List<CAutopsy> getSelectedAutopsies() {
    return _autopsies.where((a) => _selectedItems.contains(a.id)).toList();
  }

  // ============= BULK OPERATIONS =============

  /// Delete selected autopsies
  Future<void> deleteSelectedAutopsies() async {
    if (_selectedItems.isEmpty) return;

    final ids = List<String>.from(_selectedItems);
    final errors = <String>[];

    for (final id in ids) {
      try {
        await deleteAutopsy(id);
      } catch (error) {
        errors.add('Failed to delete $id: ${error.toString()}');
      }
    }

    clearSelection();

    if (errors.isNotEmpty) {
      throw AutopsyException(
        message: 'Some deletions failed:\n${errors.join('\n')}',
      );
    }
  }

  /// Update multiple autopsies
  Future<void> updateSelectedAutopsies(UpdateAutopsyRequest request) async {
    if (_selectedItems.isEmpty) return;

    final ids = List<String>.from(_selectedItems);
    final errors = <String>[];

    for (final id in ids) {
      try {
        await updateAutopsy(id, request);
      } catch (error) {
        errors.add('Failed to update $id: ${error.toString()}');
      }
    }

    if (errors.isNotEmpty) {
      throw AutopsyException(
        message: 'Some updates failed:\n${errors.join('\n')}',
      );
    }
  }

  // ============= UTILITY METHODS =============

  /// Get autopsy by ID from current list
  CAutopsy? getAutopsyFromList(String id) {
    try {
      return _autopsies.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get status options
  List<AutopsyStatusOption> getStatusOptions() {
    return _client.getStatusOptions();
  }

  /// Get category options
  List<AutopsyCategoryOption> getCategoryOptions() {
    return _client.getCategoryOptions();
  }

  /// Get formatted status label
  String getStatusLabel(String? status) {
    return _client.getStatusLabel(status);
  }

  /// Get formatted category label
  String getCategoryLabel(String? category) {
    return _client.getCategoryLabel(category);
  }

  /// Get autopsy display name
  String getAutopsyDisplayName(CAutopsy autopsy) {
    return _client.getAutopsyDisplayName(autopsy);
  }

  /// Get formatted address
  String? getFormattedAddress(CAutopsy autopsy) {
    return _client.getFormattedAddress(autopsy);
  }

  // ============= PRIVATE METHODS =============

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

void _debugLog(String message, [dynamic data]) {
  if (kDebugMode) {
    try {
      String? dataString;
      if (data != null) {
        if (data is String) {
          dataString = data;
        } else if (data is Map || data is List) {
          try {
            dataString = jsonEncode(data);
          } catch (e) {
            // If JSON encoding fails, use toString
            dataString = data.toString();
          }
        } else {
          dataString = data.toString();
        }
      }
      
      developer.log(
        message,
        name: 'AutopsyRepository',
        error: dataString,
      );
    } catch (e) {
      // Fallback logging without data if everything fails
      developer.log(
        '$message (debug data failed to serialize)',
        name: 'AutopsyRepository',
      );
    }
  }
}

  // ============= CACHE MANAGEMENT =============

  /// Clear all caches
 void clearCaches() {
    _detailCache.clear();
    _loadingDetails.clear();
    _selectedItems.clear();
    
    // Reset pagination
    _currentPage = 1;
    _hasMore = true;
    
    _debugLog('🧹 All caches cleared');
    notifyListeners();
  }

  /// Clear only the detail cache
  void clearDetailCache() {
    _detailCache.clear();
    _loadingDetails.clear();
    _debugLog('🧹 Detail cache cleared');
  }

  /// Clear only the list cache (forces reload of list)
  void clearListCache() {
    _autopsies.clear();
    _currentPage = 1;
    _hasMore = true;
    _totalCount = 0;
    _debugLog('🧹 List cache cleared');
    notifyListeners();
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheInfo() {
    return {
      'detailCacheSize': _detailCache.length,
      'loadingDetailsCount': _loadingDetails.length,
      'selectedItemsCount': _selectedItems.length,
      'autopsiesCount': _autopsies.length,
      'currentPage': _currentPage,
      'hasMore': _hasMore,
      'totalCount': _totalCount,
      'isLoading': _isLoading,
      'isLoadingMore': _isLoadingMore,
      'searchQuery': _searchQuery,
      'statusFilter': _statusFilter,
      'categoryFilter': _categoryFilter,
    };
  }
  

  @override
  void dispose() {
    clearCaches();
    super.dispose();
  }
}