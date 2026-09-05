import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/api_service.dart';
import '../services/admin_service.dart';
import '../models/package_plan.dart';

class AdminProvider extends ChangeNotifier {
  final AdminService _service;

  AdminProvider(this._service);

  Map<String, dynamic>? _dashboardData;
  bool _isDashboardLoading = false;
  bool _dashboardLoaded = false;
  List<User> _users = [];
  bool _isUsersLoading = false;
  bool _usersLoaded = false;
  String? _usersError;
  Map<String, dynamic>? _reportsData;
  bool _isReportsLoading = false;
  bool _reportsLoaded = false;
  List<dynamic> _content = [];
  bool _isContentLoading = false;
  bool _contentLoaded = false;
  String? _error;
  List<PackagePlan> _packages = [];
  bool _packagesLoaded = false;

  Map<String, dynamic>? get dashboardData => _dashboardData;
  bool get isDashboardLoading => _isDashboardLoading;
  bool get dashboardLoaded => _dashboardLoaded;
  List<User> get users => _users;
  bool get isUsersLoading => _isUsersLoading;
  bool get usersLoaded => _usersLoaded;
  String? get usersError => _usersError;
  Map<String, dynamic>? get reportsData => _reportsData;
  bool get isReportsLoading => _isReportsLoading;
  bool get reportsLoaded => _reportsLoaded;
  List<dynamic> get content => _content;
  bool get isContentLoading => _isContentLoading;
  bool get contentLoaded => _contentLoaded;
  String? get error => _error;
  List<PackagePlan> get packages => _packages;
  bool get packagesLoaded => _packagesLoaded;

  Future<void> loadDashboard() async {
    _isDashboardLoading = true;
    notifyListeners();
    try {
      _dashboardData = await _service.getDashboard();
    } catch (_) {
      _dashboardData = null;
    } finally {
      _dashboardLoaded = true;
      _isDashboardLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUsers() async {
    _isUsersLoading = true;
    _usersError = null;
    notifyListeners();
    try {
      _users = await _service.getUsers();
    } catch (error) {
      _users = [];
      _usersError = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _usersLoaded = true;
      _isUsersLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteUser(int id) async {
    final response = await _service.deleteUser(id);
    if (response.success) {
      await loadUsers();
      return true;
    }
    return false;
  }

  Future<ApiResponse> createUser(Map<String, dynamic> data) async {
    final response = await _service.createUser(data);
    if (response.success) {
      await loadUsers();
    }
    return response;
  }

  Future<bool> updateUserRole(int id, String role) async {
    final response = await _service.updateUserRole(id, role);
    if (response.success) {
      await loadUsers();
      return true;
    }
    return false;
  }

  Future<void> loadReports() async {
    _isReportsLoading = true;
    notifyListeners();
    try {
      _reportsData = await _service.getReports();
    } catch (_) {
      _reportsData = null;
    } finally {
      _reportsLoaded = true;
      _isReportsLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateBugReportStatus(int id, String status) async {
    final response = await _service.updateBugReportStatus(id, status);
    if (response.success) {
      await loadReports();
    }
    return response.success;
  }

  Future<void> loadContent() async {
    _isContentLoading = true;
    notifyListeners();
    try {
      _content = await _service.getContent();
    } catch (_) {
      _content = [];
    } finally {
      _contentLoaded = true;
      _isContentLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteContent(int id) async {
    final response = await _service.deleteContent(id);
    if (response.success) {
      await loadContent();
      return true;
    }
    return false;
  }

  Future<void> loadPackages() async {
    _packages = await _service.getPackages();
    _packagesLoaded = true;
    notifyListeners();
  }
  Future<bool> createPackage(Map<String, dynamic> data) async {
    final result = await _service.createPackage(data);
    if (result.success) await loadPackages();
    return result.success;
  }
  Future<bool> updatePackage(int id, Map<String, dynamic> data) async {
    final result = await _service.updatePackage(id, data);
    if (result.success) await loadPackages();
    return result.success;
  }
  Future<bool> deletePackage(int id) async {
    final result = await _service.deletePackage(id);
    if (result.success) await loadPackages();
    return result.success;
  }
}
