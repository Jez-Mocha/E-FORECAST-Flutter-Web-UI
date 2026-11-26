import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/account_profile.dart';
import '../models/auth_session.dart';
import '../models/billing_data.dart';
import '../models/consumption_record.dart';
import '../models/forecast_result.dart';
import '../models/household.dart';
import '../models/usage_summary.dart';

/// Backend error with a message safe to display.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.code});

  final String message;
  final int? statusCode;
  final String? code;

  bool get isSessionExpired =>
      statusCode == 401 && code != 'INVALID_CREDENTIALS';

  @override
  String toString() => message;
}

class ApiService {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static AuthSession? _session;
  static Timer? _expiryTimer;
  static final _expired = StreamController<void>.broadcast();

  static AuthSession? get session => _session;
  static int? get currentUserId => _session?.userId;
  static Stream<void> get sessionExpired => _expired.stream;

  static const _sessionExpired = ApiException(
    'Your session has expired. Please log in again.',
    statusCode: 401,
    code: 'AUTHENTICATION_REQUIRED',
  );
  static const _unexpected = ApiException(
    'The server sent an unexpected response. Please try again.',
  );

  static Future<bool> testConnection() async {
    try {
      return (await _request('/api/health', authenticated: false))['status'] ==
          'ok';
    } on ApiException {
      return false;
    }
  }

  static Future<AuthSession> login({
    required String usernameOrEmail,
    required String password,
  }) => _authenticate('/api/auth/login', {
    'username_or_email': usernameOrEmail.trim(),
    'password': password,
  });

  static Future<AuthSession> register({
    required String username,
    required String email,
    required String password,
  }) => _authenticate('/api/auth/register', {
    'username': username.trim(),
    'email': email.trim().toLowerCase(),
    'password': password,
  });

  static Future<AuthSession> _authenticate(
    String path,
    Map<String, dynamic> body,
  ) async {
    final result = await _request(path, body: body, authenticated: false);
    final session = _parse(() => AuthSession.fromJson(result));
    _expiryTimer?.cancel();
    _session = session;
    _expiryTimer = Timer(
      session.expiresAt.difference(DateTime.now()),
      () => _expire(session),
    );
    return session;
  }

  static void logout() {
    _expiryTimer?.cancel();
    _expiryTimer = null;
    _session = null;
  }

  static void _expire(AuthSession session) {
    if (!identical(_session, session)) return;
    logout();
    _expired.add(null);
  }

  static Future<List<Map<String, dynamic>>> getHouseholds() =>
      _getList('/api/households', 'households');

  static Future<Household> createHousehold({
    required String householdName,
    required String address,
    required String meterNumber,
    required int occupants,
    required String electricityProvider,
    required int billingCycleDay,
  }) async {
    final result = await _request(
      '/api/households',
      body: {
        'household_name': householdName,
        'address': address,
        'meter_number': meterNumber,
        'occupants': occupants,
        'electricity_provider': electricityProvider,
        'billing_cycle_day': billingCycleDay,
      },
    );
    final household = _parse(() => Household.fromJson(result));
    if (household.id == null) {
      throw const ApiException(
        'The server did not confirm the household. Check My Households before retrying.',
      );
    }
    return household;
  }

  static Future<Household> updateHouseholdBilling({
    required int householdId,
    required String electricityProvider,
    required int billingCycleDay,
  }) async {
    final result = await _request(
      '/api/households/$householdId/billing',
      method: 'PUT',
      body: {
        'electricity_provider': electricityProvider,
        'billing_cycle_day': billingCycleDay,
      },
    );
    final household = _parse(() => Household.fromJson(result));
    if (household.id != householdId) throw _unexpected;
    return household;
  }

  static Future<MeterReading?> getLatestMeterReading(int householdId) async {
    final result = await _request(
      '/api/consumption/latest-meter',
      query: {'household_id': '$householdId'},
    );
    if (result['has_previous_record'] == false) return null;
    return _parse(
      () => (
        value: (result['last_meter_reading'] as num).toDouble(),
        date: DateTime.parse(result['last_consumption_date'] as String),
      ),
    );
  }

  /// Returns saved readings newest first. Unusable legacy records are skipped.
  static Future<List<ConsumptionRecord>> getConsumptionHistory(
    int householdId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final rows = await _getList(
      '/api/consumption/history',
      'records',
      query: {
        'household_id': '$householdId',
        if (startDate != null) 'start_date': _formatDate(startDate),
        if (endDate != null) 'end_date': _formatDate(endDate),
      },
    );
    return rows.map(ConsumptionRecord.tryParse).nonNulls.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static Future<UsageSummary> getUsageSummary({
    required int householdId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final result = await _request(
      '/api/usage/summary',
      query: {
        'household_id': '$householdId',
        'start_date': _formatDate(startDate),
        'end_date': _formatDate(endDate),
      },
    );
    return _parse(() => UsageSummary.fromJson(result));
  }

  static Future<Map<String, dynamic>> recordConsumption({
    required int householdId,
    required DateTime consumptionDate,
    required DateTime previousReadingDate,
    required double meterPrevious,
    required double meterCurrent,
  }) => _request(
    '/api/consumption',
    body: {
      'household_id': householdId,
      'consumption_date': _formatDate(consumptionDate),
      'previous_reading_date': _formatDate(previousReadingDate),
      'meter_previous': meterPrevious,
      'meter_current': meterCurrent,
    },
  );

  static Future<MonthlyConsumption> recordMonthlyConsumption({
    required int householdId,
    required DateTime billingMonth,
    required double consumptionKwh,
  }) async {
    final result = await _request(
      '/api/monthly-consumption',
      body: {
        'household_id': householdId,
        'billing_month': _formatDate(
          DateTime(billingMonth.year, billingMonth.month),
        ),
        'consumption_kwh': consumptionKwh,
      },
    );
    return _parse(() => MonthlyConsumption.fromJson(result));
  }

  static Future<List<MonthlyConsumption>> getMonthlyConsumptionHistory(
    int householdId,
  ) async {
    final rows = await _getList(
      '/api/monthly-consumption/history',
      'records',
      query: {'household_id': '$householdId'},
    );
    return _parse(() => rows.map(MonthlyConsumption.fromJson).toList());
  }

  static Future<ProviderRate> getCurrentElectricityRate(int householdId) async {
    final result = await _request(
      '/api/electricity-rates/current',
      query: {'household_id': '$householdId'},
    );
    return _parse(() => ProviderRate.fromJson(result));
  }

  static Future<ForecastResult> generateForecast({
    required int householdId,
  }) async {
    final result = await _request(
      '/api/forecasts',
      body: {'household_id': householdId},
      timeout: const Duration(seconds: 30),
    );
    return _parse(() => ForecastResult.fromJson(result));
  }

  static Future<AccountProfile> getMyProfile() async {
    final result = await _request('/api/users/me');
    return _parse(() => AccountProfile.fromJson(result));
  }

  static Future<AccountProfile> updateMyProfile({
    required String username,
    required String email,
  }) async {
    final result = await _request(
      '/api/users/me',
      method: 'PUT',
      body: {'username': username.trim(), 'email': email.trim().toLowerCase()},
    );
    return _parse(() => AccountProfile.fromJson(result));
  }

  static Future<List<Map<String, dynamic>>> getAdminUsers() =>
      _getList('/api/admin/users', 'users');

  static Future<List<Map<String, dynamic>>> getAdminHouseholds() =>
      _getList('/api/admin/households', 'households');

  static Future<List<Map<String, dynamic>>> getAdminForecasts() =>
      _getList('/api/admin/forecasts', 'forecasts');

  static Future<List<Map<String, dynamic>>> getAdminConsumption() =>
      _getList('/api/admin/consumption', 'records');

  static Future<List<ProviderRate>> getAdminRates() async {
    final rows = await _getList('/api/admin/rates', 'rates');
    return _parse(() => rows.map(ProviderRate.fromJson).toList());
  }

  static Future<ProviderRate> addAdminRate({
    required String provider,
    required double ratePerKwh,
    required DateTime effectiveDate,
    String? sourceUrl,
    String? remarks,
  }) async {
    final result = await _request(
      '/api/admin/rates',
      method: 'PUT',
      body: {
        'provider': provider.trim(),
        'rate_per_kwh': ratePerKwh,
        'effective_date': _formatDate(effectiveDate),
        'source_url': sourceUrl?.trim(),
        'remarks': remarks?.trim(),
      },
    );
    return _parse(() => ProviderRate.fromJson(result));
  }

  static Future<List<Map<String, dynamic>>> _getList(
    String path,
    String key, {
    Map<String, String>? query,
  }) async {
    final result = await _request(path, query: query);
    return _parse(
      () => (result[key] as List).whereType<Map<String, dynamic>>().toList(),
    );
  }

  static Future<Map<String, dynamic>> _request(
    String path, {
    String? method,
    Map<String, String>? query,
    Map<String, dynamic>? body,
    bool authenticated = true,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final active = authenticated ? _session : null;
    if (authenticated && active == null) throw _sessionExpired;
    if (active != null && !active.expiresAt.isAfter(DateTime.now())) {
      _expire(active);
      throw _sessionExpired;
    }
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final headers = {
      if (active != null) 'Authorization': 'Bearer ${active.token}',
      if (body != null) 'Content-Type': 'application/json',
    };
    final payload = body == null ? null : jsonEncode(body);
    final http.Response response;
    try {
      response = await (switch (method) {
        'PUT' => http.put(uri, headers: headers, body: payload),
        _ when body != null => http.post(uri, headers: headers, body: payload),
        _ => http.get(uri, headers: headers),
      }).timeout(timeout);
    } on TimeoutException {
      throw const ApiException(
        'The server took too long to respond. Please try again.',
      );
    } on http.ClientException {
      throw const ApiException(
        'Could not reach the server. Check that the backend is running.',
      );
    }
    final decoded = _decode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic>) return decoded;
      throw _unexpected;
    }
    final error = decoded is Map ? decoded['error'] : null;
    final code = error is Map && error['code'] is String
        ? error['code'] as String
        : null;
    final message = error is Map && error['message'] is String
        ? error['message'] as String
        : null;
    if (response.statusCode == 401 && active != null) {
      _expire(active);
      throw ApiException(
        _sessionExpired.message,
        statusCode: 401,
        code: code ?? _sessionExpired.code,
      );
    }
    throw ApiException(
      response.statusCode >= 500
          ? 'The server had a problem. Please try again later.'
          : message ?? 'The request failed (HTTP ${response.statusCode}).',
      statusCode: response.statusCode,
      code: code,
    );
  }

  static Object? _decode(String body) {
    try {
      return jsonDecode(body);
    } on FormatException {
      return null;
    }
  }

  static T _parse<T>(T Function() parse) {
    try {
      return parse();
    } on FormatException {
      throw _unexpected;
    } on TypeError {
      throw _unexpected;
    } on ArgumentError {
      throw _unexpected;
    }
  }

  static String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
