
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  // Send a login request to FastAPI.
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

    final data = _decodeResponse(response);

    if (response.statusCode == 200) {
      await _saveToken(data['token'].toString());
      return data;
    }

    throw Exception(_getErrorMessage(data));
  }

  // Send a registration request to FastAPI.
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

    final data = _decodeResponse(response);

    if (response.statusCode == 201) {
      await _saveToken(data['token'].toString());
      return data;
    }

    throw Exception(_getErrorMessage(data));
  }

  // Register a complete household under the authenticated user's account.
  static Future<Map<String, dynamic>> createHousehold({
    required String householdName,
    required String address,
    required String meterNumber,
    required int occupants,
    required String electricityProvider,
    required double ratePerKwh,
    required int billingCycleDay,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/households'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'household_name': householdName,
        'address': address,
        'meter_number': meterNumber,
        'occupants': occupants,
        'electricity_provider': electricityProvider,
        'rate_per_kwh': ratePerKwh,
        'billing_cycle_day': billingCycleDay,
      }),
    );

    final data = _decodeResponse(response);

    if (response.statusCode == 201) {
      return data;
    }

    throw Exception(_getErrorMessage(data));
  }

  // Retrieve all households belonging to the authenticated user.
  static Future<List<Map<String, dynamic>>> getHouseholds() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/households'),
      headers: await _authHeaders(),
    );

    final data = _decodeResponse(response);

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(
        data['households'] ?? [],
      );
    }

    throw Exception(_getErrorMessage(data));
  }

  // Add the JWT token to protected API requests.
  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Authentication required. Please log in again.',
      );
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Save the JWT token locally.
  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Retrieve the saved JWT token.
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Remove the saved JWT token during logout.
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Safely decode the API response.
  static Map<String, dynamic> _decodeResponse(
    http.Response response,
  ) {
    final decoded = jsonDecode(response.body);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw Exception('Invalid response from server.');
  }

  // Read the error message returned by FastAPI.
  static String _getErrorMessage(Map<String, dynamic> data) {
    final error = data['error'];

    if (error is Map<String, dynamic>) {
      return error['message']?.toString() ?? 'Request failed.';
    }

    if (error is String) {
      return error;
    }

    if (data['detail'] is Map<String, dynamic>) {
      return data['detail']['message']?.toString() ??
          'Request failed.';
    }

    return data['detail']?.toString() ?? 'Request failed.';
  }
}
