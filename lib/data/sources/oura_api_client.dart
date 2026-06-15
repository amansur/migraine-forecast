import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:migraine_forecast/data/models/oura_models.dart';

class RateLimitException implements Exception {
  final String? retryAfter;

  RateLimitException(this.retryAfter);

  @override
  String toString() => 'RateLimitException: Rate limit exceeded. '
      '${retryAfter != null ? 'Retry after: $retryAfter seconds' : 'No retry information available'}';
}

class OuraAuthException implements Exception {
  final String message;

  OuraAuthException(this.message);

  @override
  String toString() => 'OuraAuthException: $message';
}

class OuraApiClient {
  static const String _baseUrl = 'https://api.ouraring.com/v2/usercollection';

  final Future<String?> Function() tokenProvider;
  final http.Client _httpClient;

  OuraApiClient({
    required this.tokenProvider,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  Future<Map<String, String>> _getHeaders() async {
    final token = await tokenProvider();
    if (token == null) {
      throw OuraAuthException('No access token available');
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Future<OuraSleepData> getSleep({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final url = Uri.parse(
      '$_baseUrl/sleep?start_date=${_formatDate(startDate)}&end_date=${_formatDate(endDate)}',
    );

    final response = await _httpClient.get(url, headers: await _getHeaders());
    return _handleResponse<OuraSleepData>(
      response,
      (json) => OuraSleepData.fromJson(json),
    );
  }

  Future<OuraDailySleepData> getDailySleep({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final url = Uri.parse(
      '$_baseUrl/daily_sleep?start_date=${_formatDate(startDate)}&end_date=${_formatDate(endDate)}',
    );

    final response = await _httpClient.get(url, headers: await _getHeaders());
    return _handleResponse<OuraDailySleepData>(
      response,
      (json) => OuraDailySleepData.fromJson(json),
    );
  }

  Future<OuraActivityData> getActivity({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final url = Uri.parse(
      '$_baseUrl/daily_activity?start_date=${_formatDate(startDate)}&end_date=${_formatDate(endDate)}',
    );

    final response = await _httpClient.get(url, headers: await _getHeaders());
    return _handleResponse<OuraActivityData>(
      response,
      (json) => OuraActivityData.fromJson(json),
    );
  }

  Future<OuraReadinessData> getReadiness({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final url = Uri.parse(
      '$_baseUrl/daily_readiness?start_date=${_formatDate(startDate)}&end_date=${_formatDate(endDate)}',
    );

    final response = await _httpClient.get(url, headers: await _getHeaders());
    return _handleResponse<OuraReadinessData>(
      response,
      (json) => OuraReadinessData.fromJson(json),
    );
  }

  T _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>) parser,
  ) {
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return parser(json);
    } else if (response.statusCode == 401) {
      throw OuraAuthException('Unauthorized: access token is invalid or expired');
    } else if (response.statusCode == 429) {
      throw RateLimitException(response.headers['retry-after']);
    } else {
      throw Exception('Failed to load Oura data: ${response.statusCode}');
    }
  }
}
