import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/consumption_record.dart';
import '../models/forecast_result.dart';
import '../models/usage_summary.dart';

/// An error from the backend with a message that is safe to show the user.
/// Used by the consumption and household-saving methods. Other methods still
/// throw a plain Exception, as before.
class ApiException implements Exception {
  /// HTTP status code, e.g. 409. Null if the server could not be reached.
  final int? statusCode;

  /// Backend error code, e.g. "DUPLICATE_CONSUMPTION_RECORD".
  final String? code;

  /// Friendly message to show on screen.
  final String message;

  const ApiException(this.message, {this.statusCode, this.code});

  /// True when the login token is missing or expired (HTTP 401).
  bool get isSessionExpired => statusCode == 401;

  @override
  String toString() => message;
}

class ApiService {
  // Flutter Web running in Chrome on the same PC.
  static const String baseUrl = 'http://127.0.0.1:8000';

  // Stores the token while the app is running.
  static String? accessToken;

  static Future<bool> testConnection() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/openapi.json'))
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Register a new user.
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    final result = _handleResponse(response);

    // The backend logs the new user in: keep the token it returns.
    accessToken = result['token']?.toString();

    return result;
  }

  // Log in and save the authentication token.
  static Future<Map<String, dynamic>> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username_or_email': usernameOrEmail,
        'password': password,
      }),
    );

    final result = _handleResponse(response);

    accessToken = result['token']?.toString();

    return result;
  }

  // The id of the logged-in user, read from the login token (the backend
  // puts it in the token's "sub" field). Null if nobody is logged in or the
  // token cannot be read. Only used to name browser-saved preferences. It is
  // not proof of identity.
  static int? get currentUserId {
    final token = accessToken;
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
      // Fall through: the id could not be read.
    }

    return null;
  }

  // Log out: forget the authentication token kept in memory.
  static void logout() {
    accessToken = null;
  }

  // Fetch households belonging to the authenticated user.
  static Future<List<Map<String, dynamic>>> getHouseholds() async {
    if (accessToken == null || accessToken!.isEmpty) {
      throw Exception('Please log in before loading households.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/api/households'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    final result = _handleResponse(response);
    final households = result['households'];

    if (households is! List) {
      throw Exception('Invalid households response from server.');
    }

    return households.whereType<Map<String, dynamic>>().toList();
  }

  // Register a new household on the server.
  // Success (201) returns: {household_id, meter_number, message}.
  // On failure this throws an [ApiException] with a friendly message.
  static Future<Map<String, dynamic>> createHousehold({
    required String householdName,
    required String address,
    required String meterNumber,
  }) async {
    if (accessToken == null || accessToken!.isEmpty) {
      throw const ApiException(
        'Your session has expired. Please log in again.',
        statusCode: 401,
        code: 'AUTHENTICATION_REQUIRED',
      );
    }

    final http.Response response;

    try {
      response = await http
          .post(
            Uri.parse('$baseUrl/api/households'),
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'household_name': householdName,
              'address': address,
              'meter_number': meterNumber,
            }),
          )
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw const ApiException(
        'The server took too long to respond. Please try again.',
      );
    } catch (e) {
      throw const ApiException(
        'Could not reach the server. Check that the backend is running.',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final dynamic decoded = _tryDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return {'data': decoded};
    }

    final error = _buildApiException(response);

    if (error.statusCode == 409) {
      throw ApiException(
        'This meter number is already registered to a household.',
        statusCode: 409,
        code: error.code,
      );
    }

    if (error.statusCode == 422) {
      throw ApiException(
        'Please check the household name, address and meter number.',
        statusCode: 422,
        code: error.code,
      );
    }

    throw error;
  }

  // Get the household's most recent saved meter reading (its meter_current).
  // Returns null if the household has no saved readings yet.
  // The newest record is chosen by its date, so the order of the list from
  // the server does not matter.
  // On failure this throws an [ApiException] with a friendly message.
  static Future<double?> getLastMeterReading(int householdId) async {
    if (accessToken == null || accessToken!.isEmpty) {
      throw const ApiException(
        'Your session has expired. Please log in again.',
        statusCode: 401,
        code: 'AUTHENTICATION_REQUIRED',
      );
    }

    final http.Response response;

    try {
      response = await http
          .get(
            Uri.parse('$baseUrl/api/consumption/history')
                .replace(queryParameters: {'household_id': '$householdId'}),
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw const ApiException(
        'The server took too long to respond. Please try again.',
      );
    } catch (e) {
      throw const ApiException(
        'Could not reach the server. Check that the backend is running.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _buildApiException(response);
    }

    final dynamic decoded = _tryDecode(response.body);

    if (decoded is! Map<String, dynamic>) return null;

    final records = decoded['records'];

    if (records is! List) return null;

    double? latestReading;
    DateTime? latestDate;

    for (final record in records) {
      if (record is! Map) continue;

      final date = DateTime.tryParse('${record['date'] ?? ''}');
      final reading = _toDouble(record['meter_current']);

      // Skip records that have no date or no current reading.
      if (date == null || reading == null) continue;

      if (latestDate == null || date.isAfter(latestDate)) {
        latestDate = date;
        latestReading = reading;
      }
    }

    return latestReading;
  }

  // Get saved meter readings for a household, newest first.
  // By default every reading is returned. Pass [startDate] and/or [endDate]
  // to get only the readings inside that range (both days included). A date
  // that is left out (null) is simply not sent to the server.
  // Records that cannot be read (for example, with no valid date) are
  // skipped, so one bad record never breaks the whole list.
  // Returns an empty list if there are no saved readings.
  // On failure this throws an [ApiException] with a friendly message.
  static Future<List<ConsumptionRecord>> getConsumptionHistory(
    int householdId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (accessToken == null || accessToken!.isEmpty) {
      throw const ApiException(
        'Your session has expired. Please log in again.',
        statusCode: 401,
        code: 'AUTHENTICATION_REQUIRED',
      );
    }

    // household_id is always sent. The dates are added only when given.
    final query = <String, String>{'household_id': '$householdId'};

    if (startDate != null) query['start_date'] = _formatDate(startDate);
    if (endDate != null) query['end_date'] = _formatDate(endDate);

    final http.Response response;

    try {
      response = await http
          .get(
            Uri.parse('$baseUrl/api/consumption/history')
                .replace(queryParameters: query),
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw const ApiException(
        'The server took too long to respond. Please try again.',
      );
    } catch (e) {
      throw const ApiException(
        'Could not reach the server. Check that the backend is running.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _buildApiException(response);
    }

    final dynamic decoded = _tryDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw const ApiException(
        'The server sent an unexpected response. Please try again.',
      );
    }

    final records = decoded['records'];

    if (records is! List) {
      throw const ApiException(
        'The server sent an unexpected response. Please try again.',
      );
    }

    final result = <ConsumptionRecord>[];

    for (final item in records) {
      if (item is! Map) continue;

      final record = ConsumptionRecord.tryParse(item);

      // Skip records that cannot be read.
      if (record != null) result.add(record);
    }

    // Newest first, so the order from the server does not matter.
    result.sort((a, b) => b.date.compareTo(a.date));

    return result;
  }

  // Get the usage totals (total kWh, average kWh per reading and number of
  // readings) for one household between two dates, both days included.
  // If there are no readings in that range, the server returns zeros.
  // On failure this throws an [ApiException] with a friendly message.
  static Future<UsageSummary> getUsageSummary({
    required int householdId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (accessToken == null || accessToken!.isEmpty) {
      throw const ApiException(
        'Your session has expired. Please log in again.',
        statusCode: 401,
        code: 'AUTHENTICATION_REQUIRED',
      );
    }

    final http.Response response;

    try {
      response = await http
          .get(
            Uri.parse('$baseUrl/api/usage/summary').replace(
              queryParameters: {
                'household_id': '$householdId',
                'start_date': _formatDate(startDate),
                'end_date': _formatDate(endDate),
              },
            ),
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw const ApiException(
        'The server took too long to respond. Please try again.',
      );
    } catch (e) {
      throw const ApiException(
        'Could not reach the server. Check that the backend is running.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _buildApiException(response);
    }

    final dynamic decoded = _tryDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw const ApiException(
        'The server sent an unexpected response. Please try again.',
      );
    }

    return UsageSummary.fromJson(decoded);
  }

  // Record one meter reading for a household.
  // The backend calculates the kWh (current - previous) and returns it.
  // Success (201) returns: {consumption_id, kwh, status, message}.
  // On failure this throws an [ApiException] with a friendly message.
  static Future<Map<String, dynamic>> recordConsumption({
    required int householdId,
    required DateTime consumptionDate,
    required double meterPrevious,
    required double meterCurrent,
  }) async {
    if (accessToken == null || accessToken!.isEmpty) {
      throw const ApiException(
        'Your session has expired. Please log in again.',
        statusCode: 401,
        code: 'AUTHENTICATION_REQUIRED',
      );
    }

    final http.Response response;

    try {
      response = await http
          .post(
            Uri.parse('$baseUrl/api/consumption'),
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'household_id': householdId,
              'consumption_date': _formatDate(consumptionDate),
              'meter_previous': meterPrevious,
              'meter_current': meterCurrent,
            }),
          )
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw const ApiException(
        'The server took too long to respond. Please try again.',
      );
    } catch (e) {
      throw const ApiException(
        'Could not reach the server. Check that the backend is running.',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final dynamic decoded = _tryDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return {'data': decoded};
    }

    throw _buildApiException(response);
  }

  // Ask the backend for a forecast for one household.
  // It predicts the use for the day after the latest reading and the
  // estimated bill. Success (200) returns: {forecast_id,
  // predicted_consumption_kwh, estimated_bill, message}.
  // If the household has fewer than 7 readings, the server answers 422 and
  // this throws an [ApiException] with code INSUFFICIENT_HISTORICAL_DATA.
  // On any failure this throws an [ApiException] with a friendly message.
  static Future<ForecastResult> generateForecast({
    required int householdId,
  }) async {
    if (accessToken == null || accessToken!.isEmpty) {
      throw const ApiException(
        'Your session has expired. Please log in again.',
        statusCode: 401,
        code: 'AUTHENTICATION_REQUIRED',
      );
    }

    final http.Response response;

    try {
      response = await http
          .post(
            Uri.parse('$baseUrl/api/forecasts'),
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'household_id': householdId}),
          )
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw const ApiException(
        'The server took too long to respond. Please try again.',
      );
    } catch (e) {
      throw const ApiException(
        'Could not reach the server. Check that the backend is running.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _buildApiException(response);
    }

    final dynamic decoded = _tryDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw const ApiException(
        'The server sent an unexpected response. Please try again.',
      );
    }

    return ForecastResult.fromJson(decoded);
  }

  // Handle successful responses and API errors.
  static Map<String, dynamic> _handleResponse(http.Response response) {
    final dynamic decoded = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return {'data': decoded};
    }

    throw Exception('API error (${response.statusCode}): ${response.body}');
  }

  // Turns a failed response into an [ApiException] with a friendly message.
  // The backend sends errors as {"error": {"code": "...", "message": "..."}}.
  static ApiException _buildApiException(http.Response response) {
    String? code;
    String? backendMessage;

    final dynamic decoded = _tryDecode(response.body);

    if (decoded is Map<String, dynamic>) {
      final error = decoded['error'];

      if (error is Map) {
        code = error['code']?.toString();
        backendMessage = error['message']?.toString();
      }
    }

    final status = response.statusCode;
    final String message;

    if (status == 401) {
      message = 'Your session has expired. Please log in again.';
    } else if (status == 400) {
      message =
          backendMessage ??
          'The request was not valid. Please check your entries.';
    } else if (status == 403) {
      message = backendMessage ?? 'You do not have access to this household.';
    } else if (status == 404) {
      message = backendMessage ?? 'The household was not found.';
    } else if (status == 409) {
      message =
          backendMessage ?? 'A reading for this date has already been saved.';
    } else if (status == 422) {
      message = backendMessage ?? 'Some of the readings are not valid.';
    } else if (status >= 500) {
      message = 'The server had a problem. Please try again later.';
    } else {
      message = backendMessage ?? 'Something went wrong (error $status).';
    }

    return ApiException(message, statusCode: status, code: code);
  }

  // Decodes JSON without crashing if the body is empty or not JSON.
  static dynamic _tryDecode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  // Turns a JSON number (or a numeric string) into a double.
  // Returns null if the value is missing or not a number.
  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse('$value');
  }

  // Formats a date the way the backend expects, e.g. "2026-11-01".
  static String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }
}
