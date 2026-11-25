import 'dart:convert';

import 'package:e_forecast/models/auth_session.dart';
import 'package:e_forecast/models/household.dart';
import 'package:e_forecast/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

String testToken(String role) {
  final claims = base64Url.encode(
    utf8.encode(
      jsonEncode({
        'sub': '17',
        'role': role,
        'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
      }),
    ),
  );
  return 'header.$claims.signature';
}

http.Response jsonResponse(Object data, int status) =>
    http.Response(jsonEncode(data), status);

void main() {
  tearDown(ApiService.logout);

  test('loads latest reading and writes required recording fields', () async {
    const role = 'HOUSEHOLD_USER';
    final token = testToken(role);
    final client = MockClient((request) async {
      if (request.url.path == '/api/auth/login') {
        return jsonResponse({'role': role, 'token': token}, 200);
      }
      expect(request.headers['authorization'], 'Bearer $token');
      if (request.url.path == '/api/consumption/latest-meter') {
        expect(request.url.queryParameters['household_id'], '2');
        return jsonResponse({
          'has_previous_record': true,
          'last_meter_reading': 12.25,
          'last_consumption_date': '2026-11-20',
        }, 200);
      }
      expect(jsonDecode(request.body), {
        'household_id': 2,
        'consumption_date': '2026-11-25',
        'previous_reading_date': '2026-11-20',
        'meter_previous': 12.25,
        'meter_current': 15,
      });
      return jsonResponse({'consumption_id': 1, 'kwh': 2.75}, 201);
    });

    await http.runWithClient(() async {
      final session = await ApiService.login(
        usernameOrEmail: 'user',
        password: 'test',
      );
      expect(session.role, AccountRole.household);
      final latest = (await ApiService.getLatestMeterReading(2))!;
      expect(latest.value, 12.25);
      await ApiService.recordConsumption(
        householdId: 2,
        consumptionDate: DateTime(2026, 11, 25),
        previousReadingDate: latest.date,
        meterPrevious: latest.value,
        meterCurrent: 15,
      );
    }, () => client);
  });

  test('keeps backend error codes and clears a rejected session', () async {
    const role = 'ADMIN';
    final client = MockClient((request) async {
      if (request.url.path == '/api/auth/login') {
        return jsonResponse({'role': role, 'token': testToken(role)}, 200);
      }
      if (request.url.path == '/api/electricity-rates/current') {
        return jsonResponse({
          'error': {'code': 'RATE_NOT_FOUND', 'message': 'No applicable rate'},
        }, 404);
      }
      return jsonResponse({
        'error': {'code': 'INVALID_TOKEN', 'message': 'Invalid token'},
      }, 401);
    });
    await http.runWithClient(() async {
      expect(
        (await ApiService.login(
          usernameOrEmail: 'admin',
          password: 'test',
        )).role,
        AccountRole.admin,
      );
      await expectLater(
        ApiService.getCurrentElectricityRate(2),
        throwsA(
          isA<ApiException>().having(
            (error) => error.code,
            'code',
            'RATE_NOT_FOUND',
          ),
        ),
      );
      expect(ApiService.session, isNotNull);
      await expectLater(
        ApiService.getAdminRates(),
        throwsA(
          isA<ApiException>().having(
            (error) => error.isSessionExpired,
            'expired',
            true,
          ),
        ),
      );
      expect(ApiService.session, isNull);
    }, () => client);
  });

  test('legacy households do not receive an invented rate or billing day', () {
    final household = Household.fromJson({
      'household_id': 1,
      'household_name': 'Example',
      'address': 'Test street',
      'billing_cycle_day': null,
      'rate_per_kwh': null,
    });
    expect(household.address, 'Test street');
    expect(household.billingCycleDay, isNull);
    expect(household.ratePerKwh, isNull);
  });
}
