import 'dart:io';
import 'package:flutter_user_management/core/api/api_client.dart';
import 'package:flutter_user_management/features/users/models/user_model.dart';

class UserRepository {
  final ApiClient apiClient;

  UserRepository({required this.apiClient});

  Future<void> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        throw Exception('No internet connection available');
      }
    } on SocketException catch (_) {
      throw Exception('No internet connection available');
    }
  }

  Future<Map<String, dynamic>> getUsers({
    required int limit,
    required int skip,
    String? searchQuery,
  }) async {
    try {
      // Check internet connection first
      await _checkInternetConnection();

      String endpoint = '/users?limit=$limit&skip=$skip';

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
      print('Error fetching users: $e');
      if (e is SocketException || e.toString().contains('SocketException')) {
        throw Exception(
            'No internet connection available. Please check your connection and try again.');
      } else if (e.toString().contains('No internet connection available')) {
        throw Exception(
            'No internet connection available. Please check your connection and try again.');
      } else if (e.toString().contains('Connection refused') ||
          e.toString().contains('Connection reset') ||
          e.toString().contains('Network is unreachable')) {
        throw Exception(
            'Unable to connect to the server. Please check your internet connection and try again.');
      } else if (e.toString().contains('Failed to load data: 404')) {
        throw Exception('Unable to find users. Please try again later.');
      } else {
        throw Exception('Unable to load users. Please try again later.');
      }
    }
  }

  Future<User> getUserById(int userId) async {
    try {
      // Check internet connection first
      await _checkInternetConnection();

      final response = await apiClient.get('/users/$userId');
      return User.fromJson(response);
    } catch (e) {
      print('Error fetching user: $e');
      if (e is SocketException || e.toString().contains('SocketException')) {
        throw Exception(
            'No internet connection available. Please check your connection and try again.');
      } else if (e.toString().contains('No internet connection available')) {
        throw Exception(
            'No internet connection available. Please check your connection and try again.');
      } else if (e.toString().contains('Connection refused') ||
          e.toString().contains('Connection reset') ||
          e.toString().contains('Network is unreachable')) {
        throw Exception(
            'Unable to connect to the server. Please check your internet connection and try again.');
      } else if (e.toString().contains('Failed to load data: 404')) {
        throw Exception('User not found. They may have been removed.');
      } else {
        throw Exception('Unable to load user details. Please try again later.');
      }
    }
  }
}
