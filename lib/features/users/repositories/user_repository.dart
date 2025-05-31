import 'package:flutter_user_management/core/api/api_client.dart';
import 'package:flutter_user_management/features/users/models/user_model.dart';

class UserRepository {
  final ApiClient apiClient;

  UserRepository({required this.apiClient});

  // Fetch users with pagination and optional search
  Future<Map<String, dynamic>> getUsers({
    required int limit,
    required int skip,
    String? searchQuery,
  }) async {
    try {
      String endpoint = '/users?limit=$limit&skip=$skip';

      // Use search endpoint if query is provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        endpoint = '/users/search?q=$searchQuery';
      }

      final response = await apiClient.get(endpoint);
      final List<User> users = (response['users'] as List)
          .map((userData) => User.fromJson(userData))
          .toList();

      return {
        'users': users,
        'total': response['total'],
        'limit': response['limit'],
        'skip': response['skip'],
      };
    } catch (e) {
      // Handle different types of errors with user-friendly messages
      if (e.toString().contains('Network error') ||
          e.toString().contains('SocketException')) {
        throw Exception('No internet connection');
      } else if (e.toString().contains('Failed to load data: 404')) {
        throw Exception('User not found');
      } else {
        throw Exception('Unable to load users');
      }
    }
  }

  // Get a single user by their ID
  Future<User> getUserById(int userId) async {
    try {
      final response = await apiClient.get('/users/$userId');
      return User.fromJson(response);
    } catch (e) {
      // Handle different types of errors with user-friendly messages
      if (e.toString().contains('Network error') ||
          e.toString().contains('SocketException')) {
        throw Exception('No internet connection');
      } else if (e.toString().contains('Failed to load data: 404')) {
        throw Exception('User not found');
      } else {
        throw Exception('Unable to load user');
      }
    }
  }
}
