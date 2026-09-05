import '../config/api_config.dart';
import '../models/user.dart';
import 'api_service.dart';
import '../models/package_plan.dart';

class AdminService {
  final ApiService _api;

  AdminService(this._api);

  Future<Map<String, dynamic>?> getDashboard() async {
    final response = await _api.get(ApiConfig.adminDashboard);
    if (response.success) return response.data as Map<String, dynamic>?;
    return null;
  }

  Future<List<User>> getUsers() async {
    final response = await _api.get(ApiConfig.adminUsers);
    if (!response.success) {
      throw Exception(response.message ?? 'Unable to load users');
    }
    if (response.data == null) throw Exception('Invalid users response');
    final rawList = response.data is Map
        ? (response.data['users'] as List<dynamic>? ?? const [])
        : (response.data as List<dynamic>);
    return rawList
        .whereType<Map>()
        .map((u) => User.fromJson(Map<String, dynamic>.from(u)))
        .toList();
  }

  Future<ApiResponse> deleteUser(int id) async {
    return await _api.delete('${ApiConfig.adminUsers}/$id');
  }

  Future<ApiResponse> createUser(Map<String, dynamic> data) async {
    return await _api.post(ApiConfig.adminUsers, body: data);
  }

  Future<ApiResponse> updateUserRole(int id, String role) async {
    return await _api.put('${ApiConfig.adminUsers}/$id', body: {'role': role});
  }

  Future<Map<String, dynamic>?> getReports() async {
    final response = await _api.get(ApiConfig.reports);
    if (response.success) return response.data as Map<String, dynamic>?;
    return null;
  }

  Future<ApiResponse> updateBugReportStatus(int id, String status) async {
    return await _api.put(
      '/api/reports/$id/status',
      body: {'status': status},
    );
  }

  Future<List<dynamic>> getContent() async {
    final response = await _api.get(ApiConfig.adminContent);
    if (response.success && response.data != null) {
      return response.data is Map
          ? (response.data['content'] as List<dynamic>? ?? [])
          : (response.data as List<dynamic>);
    }
    return [];
  }

  Future<ApiResponse> deleteContent(int id) async {
    return await _api.delete('${ApiConfig.adminContent}/$id');
  }

  Future<List<PackagePlan>> getPackages() async {
    final response = await _api.get(ApiConfig.packages);
    if (response.success && response.data is Map) {
      return ((response.data['packages'] as List<dynamic>?) ?? []).map((p) => PackagePlan.fromJson(p)).toList();
    }
    return [];
  }

  Future<ApiResponse> createPackage(Map<String, dynamic> data) => _api.post(ApiConfig.adminPackages, body: data);
  Future<ApiResponse> updatePackage(int id, Map<String, dynamic> data) => _api.put('${ApiConfig.adminPackages}/$id', body: data);
  Future<ApiResponse> deletePackage(int id) => _api.delete('${ApiConfig.adminPackages}/$id');
}
