import 'dart:io';
import 'package:flutter_user_management/core/api/api_client.dart';
import 'package:flutter_user_management/features/users/models/user_model.dart';

class UserRepository {
  final ApiClient apiClient;

  UserRepository({required this.apiClient});

  // Verifies internet connectivity before making requests
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

  // Fetches users with pagination and optional search
  Future<Map<String, dynamic>> getUsers({
    required int limit,
    required int skip,
    String? searchQuery,
  }) async {
    try {
      // Ensure we have internet before making the request
      await _checkInternetConnection();

      // Build the endpoint URL based on whether we're searching or just fetching
      String endpoint = '/users?limit=$limit&skip=$skip';
      if (searchQuery != null && searchQuery.isNotEmpty) {
        // Split the search query into parts and search for each part
        final searchParts = searchQuery.toLowerCase().split(' ');
        List<User> allUsers = [];
        int total = 0;

        for (final part in searchParts) {
          final encodedQuery = Uri.encodeComponent(part);
          final searchEndpoint = '/users/search?q=$encodedQuery';
          final searchResponse = await apiClient.get(searchEndpoint);

          final List<User> users = (searchResponse['users'] as List)
              .map((userData) => User.fromJson(userData))
              .toList();

          // Add users that match any part of the search query
          for (final user in users) {
            if (!allUsers.any((u) => u.id == user.id)) {
              allUsers.add(user);
            }
          }

          total = searchResponse['total'] as int;
        }

        // Sort users by how well they match the search query
        allUsers.sort((a, b) {
          final aFullName = '${a.firstName} ${a.lastName}'.toLowerCase();
          final bFullName = '${b.firstName} ${b.lastName}'.toLowerCase();
          final aMatch = searchQuery
              .toLowerCase()
              .split(' ')
              .where((part) => aFullName.contains(part))
              .length;
          final bMatch = searchQuery
              .toLowerCase()
              .split(' ')
              .where((part) => bFullName.contains(part))
              .length;
          return bMatch.compareTo(aMatch);
        });

        return {
          'users': allUsers,
          'total': allUsers.length,
          'limit': limit,
          'skip': skip,
        };
      }

      final response = await apiClient.get(endpoint);

      // Convert the response data into User objects
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
      // Handle specific error cases with user-friendly messages
      if (e is SocketException || e.toString().contains('SocketException')) {
        throw Exception(
            'No internet connection available. Please check your connection and try again.');
      } else if (e.toString().contains('Failed to load data: 404')) {
        throw Exception(
            'Unable to find users. The search may not have returned any results.');
      } else if (e.toString().contains('No internet connection available')) {
        throw Exception(
            'No internet connection available. Please check your connection and try again.');
      } else if (e.toString().contains('Connection refused') ||
          e.toString().contains('Connection reset') ||
          e.toString().contains('Network is unreachable')) {
        throw Exception(
            'Unable to connect to the server. Please check your internet connection and try again.');
      } else {
        throw Exception('Unable to load users. Please try again later.');
      }
    }
  }

  // Fetches a single user by their ID
  Future<User> getUserById(int userId) async {
    try {
      // Ensure we have internet before making the request
      await _checkInternetConnection();

      final response = await apiClient.get('/users/$userId');
      return User.fromJson(response);
    } catch (e) {
      if (e is SocketException || e.toString().contains('SocketException')) {
        throw Exception(
            'No internet connection available. Please check your connection and try again.');
      } else if (e.toString().contains('Failed to load data: 404')) {
        throw Exception(
            'User not found. They may have been removed or their account is no longer active.');
      } else {
        throw Exception('Unable to load user details. Please try again later.');
      }
    }
  }
}
