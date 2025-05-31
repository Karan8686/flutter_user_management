import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;

class ApiClient {
  final String baseUrl = 'https://dummyjson.com';
  final http.Client _httpClient = http.Client();

  Future<void> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        throw SocketException('No internet connection available');
      }
    } on SocketException catch (e) {
      throw SocketException('No internet connection available: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      // First check internet connectivity
      await _checkInternetConnection();

      final url = '$baseUrl$endpoint';
      print('Making GET request to: $url');

      final response = await _httpClient.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timed out. Please try again.');
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final decoded = json.decode(response.body);
          if (decoded is Map<String, dynamic>) {
            return decoded;
          } else {
            throw FormatException('Invalid response format');
          }
        } catch (e) {
          print('JSON decode error: $e');
          throw FormatException('Invalid response format: $e');
        }
      } else if (response.statusCode == 404) {
        throw HttpException('Resource not found (404)');
      } else if (response.statusCode >= 500) {
        throw HttpException('Server error (${response.statusCode})');
      } else {
        throw HttpException(
            'Request failed with status: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      print('Socket error: $e');
      throw SocketException(
          'No internet connection available. Please check your connection and try again.');
    } on TimeoutException catch (e) {
      print('Timeout error: $e');
      throw TimeoutException('Request timed out. Please try again.');
    } on HttpException catch (e) {
      print('HTTP error: $e');
      throw HttpException(e.message);
    } on FormatException catch (e) {
      print('Format error: $e');
      throw FormatException('Invalid response from server. Please try again.');
    } catch (e) {
      print('API Error: $e');
      if (e is SocketException ||
          e is TimeoutException ||
          e is HttpException ||
          e is FormatException) {
        rethrow;
      }
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> data) async {
    try {
      // First check internet connectivity
      await _checkInternetConnection();

      final response = await _httpClient
          .post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timed out. Please try again.');
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final decoded = json.decode(response.body);
          if (decoded is Map<String, dynamic>) {
            return decoded;
          } else {
            throw FormatException('Invalid response format');
          }
        } catch (e) {
          print('JSON decode error: $e');
          throw FormatException('Invalid response format: $e');
        }
      } else if (response.statusCode == 404) {
        throw HttpException('Resource not found (404)');
      } else if (response.statusCode >= 500) {
        throw HttpException('Server error (${response.statusCode})');
      } else {
        throw HttpException(
            'Request failed with status: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      print('Socket error: $e');
      throw SocketException(
          'No internet connection available. Please check your connection and try again.');
    } on TimeoutException catch (e) {
      print('Timeout error: $e');
      throw TimeoutException('Request timed out. Please try again.');
    } on HttpException catch (e) {
      print('HTTP error: $e');
      throw HttpException(e.message);
    } on FormatException catch (e) {
      print('Format error: $e');
      throw FormatException('Invalid response from server. Please try again.');
    } catch (e) {
      print('API Error: $e');
      if (e is SocketException ||
          e is TimeoutException ||
          e is HttpException ||
          e is FormatException) {
        rethrow;
      }
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  void dispose() {
    _httpClient.close();
  }
}
