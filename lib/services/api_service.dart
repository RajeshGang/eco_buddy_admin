import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Service for making API calls to external backend services
/// This is separate from Firebase and can be used to integrate with your eco_buddy backend
class ApiService {
  // Base URL for your API - update this with your actual API endpoint
  static const String baseUrl = 'https://your-api-endpoint.com/api';
  
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Generic GET request
  Future<Map<String, dynamic>> get(String endpoint, {Map<String, String>? headers}) async {
    try {
      final uri = Uri.parse('$baseUrl/$endpoint');
      final response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          ...?headers,
        },
      );

      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('API GET Error: $e');
      }
      rethrow;
    }
  }

  /// Generic POST request
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/$endpoint');
      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          ...?headers,
        },
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('API POST Error: $e');
      }
      rethrow;
    }
  }

  /// Generic PUT request
  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/$endpoint');
      final response = await _client.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          ...?headers,
        },
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('API PUT Error: $e');
      }
      rethrow;
    }
  }

  /// Generic DELETE request
  Future<Map<String, dynamic>> delete(String endpoint, {Map<String, String>? headers}) async {
    try {
      final uri = Uri.parse('$baseUrl/$endpoint');
      final response = await _client.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          ...?headers,
        },
      );

      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('API DELETE Error: $e');
      }
      rethrow;
    }
  }

  /// Handle API response
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {'success': true};
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw ApiException(
        'API request failed with status ${response.statusCode}',
        response.statusCode,
        response.body,
      );
    }
  }

  /// Get user analytics from API
  Future<Map<String, dynamic>> getUserAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, String>{};
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String();
    }

    final queryString = queryParams.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    final endpoint = 'analytics/users${queryString.isNotEmpty ? '?$queryString' : ''}';
    return await get(endpoint);
  }

  /// Get performance metrics from API
  Future<Map<String, dynamic>> getPerformanceMetrics() async {
    return await get('metrics/performance');
  }

  /// Get A/B test results from API
  Future<Map<String, dynamic>> getABTestResults(String testId) async {
    return await get('ab-tests/$testId/results');
  }

  /// Update feature flag via API
  Future<Map<String, dynamic>> updateFeatureFlag(
    String flagId,
    Map<String, dynamic> updates,
  ) async {
    return await put('feature-flags/$flagId', updates);
  }

  void dispose() {
    _client.close();
  }
}

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? responseBody;

  ApiException(this.message, [this.statusCode, this.responseBody]);

  @override
  String toString() => 'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

