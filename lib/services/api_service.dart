import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/consumption_record.dart';
import '../models/forecast_result.dart';
import '../models/usage_summary.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String? code;
  final String message;

  const ApiException(this.message, {this.statusCode, this.code});

  bool get isSessionExpired => statusCode == 401;

  @override
  String toString() => message;
}

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000';
  static const String _tokenKey = 'auth_token';

  // Cached for synchronous access by the theme preference feature.
  // SharedPreferences remains the permanent token storage.
  static String? _cachedToken;

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(_tokenKey);
    return _cachedToken;
  }

  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    _cachedToken = token;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    _cachedToken = null;
  }

  static int? get currentUserId {
    final token = _cachedToken;
    if (token == null || token.isEmpty) return null;

    final parts = token.split('.');
    if (parts.length != 3) return null;

    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final decoded = jsonDecode(payload);

      if (decoded is Map<String, dynamic>) {
        return int.tryParse('${decoded['sub']}');
      }
    } catch (_) {
      // The token payload could not be read.
    }

    return null;
  }

  static Future<bool> testConnection() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/openapi.json'))
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username_or_email': usernameOrEmail,
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 15));

    final result = _handleResponse(response);
    final token = result['token']?.toString();

    if (token == null || token.isEmpty) {
      throw const ApiException('The server did not return an access token.');
    }

    await _saveToken(token);
    return result;
  }

  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': username,
            'email': email,
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 15));

    final result = _handleResponse(response);
    final token = result['token']?.toString();

    if (token != null && token.isNotEmpty) {
      await _saveToken(token);
    }

    return result;
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw const ApiException(
        'Your session has expired. Please log in again.',
        statusCode: 401,
        code: 'AUTHENTICATION_REQUIRED',
      );
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Retrieve the profile of the authenticated household user.
  static Future<Map<String, dynamic>> getMyProfile() async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/api/users/me'),
          headers: await _authHeaders(),
        )
        .timeout(const Duration(seconds: 15));

    return _handleResponse(response);
  }

  // Update the username and email of the authenticated household user.
  static Future<Map<String, dynamic>> updateMyProfile({
    required String username,
    required String email,
  }) async {
    final response = await http
        .put(
          Uri.parse('$baseUrl/api/users/me'),
          headers: await _authHeaders(),
          body: jsonEncode({
            'username': username.trim(),
            'email': email.trim(),
          }),
        )
        .timeout(const Duration(seconds: 15));

    return _handleResponse(response);
  }

   // -- Admin API Methods -------------------------

   // Shared method for retrieving admin lists.
   static Future<List<Map<String, dynamic>>> _getAdminList(
    String endpoint,
    String responseKey,
  ) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl$endpoint'),
          headers: await _authHeaders(),
        )
        .timeout(const Duration(seconds: 15));

    final result = _handleResponse(response);
    final items = result[responseKey];

    if (items is! List) {
      throw ApiException(
        'Invalid $responseKey response from server.',
      );
    }

    return items
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  // Retrieve all registered users.
  static Future<List<Map<String, dynamic>>> getAdminUsers() {
    return _getAdminList('/api/admin/users', 'users');
  }

  // Retrieve all registered households.
  static Future<List<Map<String, dynamic>>> getAdminHouseholds() {
    return _getAdminList('/api/admin/households', 'households');
  }

  // Retrieve all generated forecasts.
  static Future<List<Map<String, dynamic>>> getAdminForecasts() {
    return _getAdminList('/api/admin/forecasts', 'forecasts');
  }

  // Retrieve all electricity consumption records.
  static Future<List<Map<String, dynamic>>> getAdminConsumption() {
    return _getAdminList('/api/admin/consumption', 'records');
  }

    // Retrieve all electricity rate records for admin management.
  static Future<List<Map<String, dynamic>>> getAdminRates() {
    return _getAdminList('/api/admin/rates', 'rates');
  }

  // Add a new provider-specific electricity rate.
  // Existing rate records are preserved as history.
  static Future<Map<String, dynamic>> addAdminRate({
    required String provider,
    required double ratePerKwh,
    required String effectiveDate,
    String? sourceUrl,
    String? remarks,
  }) async {
    final response = await http
        .put(
          Uri.parse('$baseUrl/api/admin/rates'),
          headers: {
            ...await _authHeaders(),
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'provider': provider.trim(),
            'rate_per_kwh': ratePerKwh,
            'effective_date': effectiveDate,
            'source_url': sourceUrl?.trim(),
            'remarks': remarks?.trim(),
          }),
        )
        .timeout(const Duration(seconds: 15));

    return _handleResponse(response);
  }

  static Future<List<Map<String, dynamic>>> getHouseholds() async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/api/households'),
          headers: await _authHeaders(),
        )
        .timeout(const Duration(seconds: 15));

    final result = _handleResponse(response);
    final households = result['households'];

    if (households is! List) {
      throw const ApiException('Invalid households response from server.');
    }

    return households
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Future<Map<String, dynamic>> createHousehold({
    required String householdName,
    required String address,
    required String meterNumber,
    required int occupants,
    required String electricityProvider,
    required int billingCycleDay,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/households'),
          headers: await _authHeaders(),
          body: jsonEncode({
            'household_name': householdName,
            'address': address,
            'meter_number': meterNumber,
            'occupants': occupants,
            'electricity_provider': electricityProvider,
            'billing_cycle_day': billingCycleDay,
          }),
        )
        .timeout(const Duration(seconds: 15));

    return _handleResponse(response);
  }

  
static Future<Map<String, dynamic>?> getLastMeterReading(
  int householdId,
) async {
  final response = await http
      .get(
        Uri.parse('$baseUrl/api/consumption/latest-meter').replace(
          queryParameters: {'household_id': '$householdId'},
        ),
        headers: await _authHeaders(),
      )
      .timeout(const Duration(seconds: 15));

  final decoded = _handleResponse(response);

  if (decoded['has_previous_record'] != true) {
    return null;
  }

  return {
    'meter_reading': _toDouble(decoded['last_meter_reading']),
    'reading_date': decoded['last_consumption_date'],
  };
}

  // Retrieve the current provider-specific electricity rate.
  static Future<Map<String, dynamic>> getCurrentElectricityRate(
    int householdId,
  ) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/api/electricity-rates/current').replace(
            queryParameters: {
              'household_id': '$householdId',
            },
          ),
          headers: await _authHeaders(),
        )
        .timeout(const Duration(seconds: 15));

    final decoded = _handleResponse(response);

    if (decoded['rate_per_kwh'] == null ||
        decoded['provider'] == null) {
      throw const ApiException(
        'The server returned incomplete electricity rate information.',
      );
    }

    return decoded;
  }


  static Future<List<ConsumptionRecord>> getConsumptionHistory(
    int householdId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final query = <String, String>{'household_id': '$householdId'};

    if (startDate != null) query['start_date'] = _formatDate(startDate);
    if (endDate != null) query['end_date'] = _formatDate(endDate);

    final response = await http
        .get(
          Uri.parse('$baseUrl/api/consumption/history')
              .replace(queryParameters: query),
          headers: await _authHeaders(),
        )
        .timeout(const Duration(seconds: 15));

    final decoded = _handleResponse(response);
    final records = decoded['records'];

    if (records is! List) {
      throw const ApiException('The server sent an unexpected response.');
    }

    final result = <ConsumptionRecord>[];

    for (final item in records) {
      if (item is! Map) continue;

      final record = ConsumptionRecord.tryParse(item);
      if (record != null) result.add(record);
    }

    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  static Future<UsageSummary> getUsageSummary({
    required int householdId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/api/usage/summary').replace(
            queryParameters: {
              'household_id': '$householdId',
              'start_date': _formatDate(startDate),
              'end_date': _formatDate(endDate),
            },
          ),
          headers: await _authHeaders(),
        )
        .timeout(const Duration(seconds: 15));

    return UsageSummary.fromJson(_handleResponse(response));
  }

  static Future<Map<String, dynamic>> recordConsumption({
    required int householdId,
    required DateTime consumptionDate,
    DateTime? previousReadingDate,
    required double meterPrevious,
    required double meterCurrent,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/consumption'),
          headers: await _authHeaders(),
          body: jsonEncode({
            'household_id': householdId,
            'consumption_date': _formatDate(consumptionDate),
            'previous_reading_date': previousReadingDate != null
                ? _formatDate(previousReadingDate)
                : null,
            'meter_previous': meterPrevious,
            'meter_current': meterCurrent,
          }),
        )
        .timeout(const Duration(seconds: 15));

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> recordMonthlyConsumption({
    required int householdId,
    required DateTime billingMonth,
    required double consumptionKwh,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/monthly-consumption'),
          headers: await _authHeaders(),
          body: jsonEncode({
            'household_id': householdId,
            'billing_month': _formatDate(
              DateTime(billingMonth.year, billingMonth.month, 1),
            ),
            'consumption_kwh': consumptionKwh,
          }),
        )
        .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
  }


  static Future<ForecastResult> generateForecast({
    required int householdId,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/forecasts'),
          headers: await _authHeaders(),
          body: jsonEncode({'household_id': householdId}),
        )
        .timeout(const Duration(seconds: 30));

    return ForecastResult.fromJson(_handleResponse(response));
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    final decoded = _tryDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic>) return decoded;
      return {'data': decoded};
    }

    throw _buildApiException(response);
  }

  static ApiException _buildApiException(http.Response response) {
    String? code;
    String? backendMessage;

    final decoded = _tryDecode(response.body);

    if (decoded is Map<String, dynamic>) {
      final error = decoded['error'] ?? decoded['detail'];

      if (error is Map) {
        code = error['code']?.toString();
        backendMessage = error['message']?.toString();
      } else if (error is String) {
        backendMessage = error;
      }
    }

    final status = response.statusCode;
    String message;

    if (status == 401) {
      message = 'Your session has expired. Please log in again.';
    } else if (status == 400) {
      message = backendMessage ??
          'The request was not valid. Please check your entries.';
    } else if (status == 403) {
      message = backendMessage ?? 'You do not have access to this household.';
    } else if (status == 404) {
      message = backendMessage ?? 'The requested record was not found.';
    } else if (status == 409) {
      message = backendMessage ??
          'A record with these details already exists.';
    } else if (status == 422) {
      message = backendMessage ??
          'Some of the submitted information is not valid.';
    } else if (status >= 500) {
      message = 'The server had a problem. Please try again later.';
    } else {
      message = backendMessage ?? 'Something went wrong (error $status).';
    }

    return ApiException(message, statusCode: status, code: code);
  }

  static dynamic _tryDecode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse('$value');
  }

  static String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
