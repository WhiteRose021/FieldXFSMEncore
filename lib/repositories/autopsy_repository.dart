// lib/repositories/autopsy_repository.dart - FIXED VERSION
// Updated import and types to use AutopsyService

import 'package:flutter/material.dart';
import '../models/autopsy_models.dart';
import '../services/autopsy_service.dart';  // FIXED: Updated import

/// Repository for managing autopsy data and state
/// Acts as an intermediary between UI and AutopsyService
class AutopsyRepository extends ChangeNotifier {
  final AutopsyService _client;  // FIXED: Updated type

  List<CAutopsy> _autopsies = [];
  CAutopsy? _currentAutopsy;
  bool _isLoading = false;
  String? _error;
  int _totalCount = 0;
  int _currentPage = 0;
  final int _pageSize = 20;

  // Filtering and searching
  String _searchQuery = '';
  String? _statusFilter;
  String? _categoryFilter;
  bool _includeDeleted = false;

  AutopsyRepository({required AutopsyService client}) : _client = client;  // FIXED: Updated type

  // Getters
  List<CAutopsy> get autopsies => List.unmodifiable(_autopsies);
  CAutopsy? get currentAutopsy => _currentAutopsy;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalCount => _totalCount;
  int get currentPage => _currentPage;
  bool get hasMorePages => (_currentPage + 1) * _pageSize < _totalCount;
  
  // ADDED: Missing getters for compatibility
  bool get hasMore => hasMorePages;
  bool get isLoadingMore => _isLoading && _autopsies.isNotEmpty;
  
  // Filter getters
  String get searchQuery => _searchQuery;
  String? get statusFilter => _statusFilter;
  String? get categoryFilter => _categoryFilter;
  bool get includeDeleted => _includeDeleted;

  /// Load autopsies with current filters
  Future<void> loadAutopsies({bool refresh = false}) async {
    if (_isLoading && !refresh) return;

    try {
      _setLoading(true);
      _clearError();

      if (refresh) {
        _currentPage = 0;
        _autopsies.clear();
      }

      final params = ListAutopsyParams(
        limit: _pageSize,
        offset: _currentPage * _pageSize,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        status: _statusFilter,
        category: _categoryFilter,
        includeDeleted: _includeDeleted,
        orderBy: 'modifiedAt',
        orderDirection: 'DESC',
      );

      final response = await _client.listAutopsies(params);

      if (refresh) {
        _autopsies = response.data;
      } else {
        _autopsies.addAll(response.data);
      }

      _totalCount = response.total;
      _currentPage++;

    } catch (error) {
      _setError(_getErrorMessage(error));
    } finally {
      _setLoading(false);
    }
  }

  /// Load more autopsies for pagination
  Future<void> loadMoreAutopsies() async {
    if (!hasMorePages || _isLoading) return;
    await loadAutopsies();
  }

  /// Refresh autopsy list
  Future<void> refreshAutopsies() async {
    await loadAutopsies(refresh: true);
  }

  /// Search autopsies
  Future<void> searchAutopsies(String query) async {
    if (_searchQuery == query) return;

    _searchQuery = query;
    await loadAutopsies(refresh: true);
  }

  /// Apply status filter
  Future<void> filterByStatus(String? status) async {
    if (_statusFilter == status) return;

    _statusFilter = status;
    await loadAutopsies(refresh: true);
  }

  /// Apply category filter
  Future<void> filterByCategory(String? category) async {
    if (_categoryFilter == category) return;

    _categoryFilter = category;
    await loadAutopsies(refresh: true);
  }

  /// Toggle deleted items visibility
  Future<void> toggleIncludeDeleted() async {
    _includeDeleted = !_includeDeleted;
    await loadAutopsies(refresh: true);
  }

  /// Clear all filters
  Future<void> clearFilters() async {
    bool hasFilters = _searchQuery.isNotEmpty || 
                     _statusFilter != null || 
                     _categoryFilter != null ||
                     _includeDeleted;

    if (!hasFilters) return;

    _searchQuery = '';
    _statusFilter = null;
    _categoryFilter = null;
    _includeDeleted = false;

    await loadAutopsies(refresh: true);
  }

  /// ADDED: Clear search (alias for searchAutopsies with empty string)
  Future<void> clearSearch() async {
    await searchAutopsies('');
  }

  /// ADDED: Apply filters (combined method for compatibility)
  Future<void> applyFilters({String? status, String? category, String? search}) async {
    bool needsRefresh = false;

    if (status != _statusFilter) {
      _statusFilter = status;
      needsRefresh = true;
    }

    if (category != _categoryFilter) {
      _categoryFilter = category;
      needsRefresh = true;
    }

    if (search != null && search != _searchQuery) {
      _searchQuery = search;
      needsRefresh = true;
    }

    if (needsRefresh) {
      await loadAutopsies(refresh: true);
    }
  }

  /// ADDED: Clear caches method for compatibility
  Future<void> clearCaches() async {
    _autopsies.clear();
    _currentAutopsy = null;
    _currentPage = 0;
    _totalCount = 0;
    _clearError();
    notifyListeners();
  }

  /// Get single autopsy by ID
  Future<void> getAutopsy(String id) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _client.getAutopsy(id);
      _currentAutopsy = response.data;

    } catch (error) {
      _setError(_getErrorMessage(error));
      _currentAutopsy = null;
    } finally {
      _setLoading(false);
    }
  }

  /// Create new autopsy
  Future<bool> createAutopsy(CreateAutopsyRequest request) async {
    try {
      _setLoading(true);
      _clearError();

      final newAutopsy = await _client.createAutopsy(request);
      
      // Add to the beginning of the list
      _autopsies.insert(0, newAutopsy);
      _totalCount++;
      
      notifyListeners();
      return true;

    } catch (error) {
      _setError(_getErrorMessage(error));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update existing autopsy
  Future<bool> updateAutopsy(String id, UpdateAutopsyRequest request) async {
    try {
      _setLoading(true);
      _clearError();

      final updatedAutopsy = await _client.updateAutopsy(id, request);
      
      // Update in the list
      final index = _autopsies.indexWhere((a) => a.id == id);
      if (index != -1) {
        _autopsies[index] = updatedAutopsy;
      }

      // Update current autopsy if it's the same
      if (_currentAutopsy?.id == id) {
        _currentAutopsy = updatedAutopsy;
      }

      notifyListeners();
      return true;

    } catch (error) {
      _setError(_getErrorMessage(error));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete autopsy
  Future<bool> deleteAutopsy(String id) async {
    try {
      _setLoading(true);
      _clearError();

      await _client.deleteAutopsy(id);
      
      if (!_includeDeleted) {
        // Remove from list if not showing deleted items
        _autopsies.removeWhere((a) => a.id == id);
        _totalCount--;
      } else {
        // Mark as deleted in the list
        final index = _autopsies.indexWhere((a) => a.id == id);
        if (index != -1) {
          _autopsies[index] = _autopsies[index].copyWith(deleted: true);
        }
      }

      notifyListeners();
      return true;

    } catch (error) {
      _setError(_getErrorMessage(error));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Restore deleted autopsy
  Future<bool> restoreAutopsy(String id) async {
    try {
      _setLoading(true);
      _clearError();

      final restoredAutopsy = await _client.restoreAutopsy(id);
      
      // Update in the list
      final index = _autopsies.indexWhere((a) => a.id == id);
      if (index != -1) {
        _autopsies[index] = restoredAutopsy;
      }

      notifyListeners();
      return true;

    } catch (error) {
      _setError(_getErrorMessage(error));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get autopsy permissions
  Future<AutopsyPermissions?> getPermissions() async {
    try {
      return await _client.getPermissions();
    } catch (error) {
      _setError(_getErrorMessage(error));
      return null;
    }
  }

  /// Get display formatted data for an autopsy
  Map<String, String> getAutopsyDisplayData(CAutopsy autopsy) {
    return {
      'displayName': _client.getAutopsyDisplayName(autopsy),
      'address': _client.getFormattedAddress(autopsy) ?? 'No address',
      'statusLabel': _client.getStatusLabel(autopsy.autopsyStatus),
      'categoryLabel': _client.getCategoryLabel(autopsy.autopsyCategory),
    };
  }

  /// Get status options for dropdowns
  List<AutopsyStatusOption> getStatusOptions() {
    return _client.getStatusOptions();
  }

  /// Get category options for dropdowns
  List<AutopsyCategoryOption> getCategoryOptions() {
    return _client.getCategoryOptions();
  }

  /// Clear current autopsy
  void clearCurrentAutopsy() {
    _currentAutopsy = null;
    notifyListeners();
  }

  /// Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  /// Helper method to extract error messages
  String _getErrorMessage(dynamic error) {
    if (error is AutopsyException) {
      return error.message;
    } else if (error is Exception) {
      return error.toString();
    } else {
      return 'An unexpected error occurred: $error';
    }
  }

  @override
  void dispose() {
    _autopsies.clear();
    _currentAutopsy = null;
    super.dispose();
  }
}