import 'package:e_forecast/models/household.dart';
import 'package:e_forecast/screens/forecast_bill_screen.dart';
import 'package:e_forecast/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'api_service_test.dart' show jsonResponse, testToken;

const role = 'HOUSEHOLD_USER';
String iso(DateTime date) => date.toIso8601String().split('T').first;

Future<void> openForecast(WidgetTester tester, {int? billingDay}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1440, 1300);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await ApiService.login(usernameOrEmail: 'example', password: 'test input');
  await tester.pumpWidget(
    MaterialApp(
      home: ForecastBillScreen(
        household: Household(
          id: 7,
          name: 'Test home',
          street: 'Test street',
          city: 'Test city',
          occupants: 2,
          provider: 'ANECO',
          ratePerKwh: null,
          billingCycleDay: billingDay,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  tearDown(ApiService.logout);

  testWidgets(
    'cycle bills use actual meter coverage and stay separate from XGBoost',
    (tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final client = MockClient((request) async {
        switch (request.url.path) {
          case '/api/auth/login':
            return jsonResponse({'token': testToken(role), 'role': role}, 200);
          case '/api/electricity-rates/current':
            return jsonResponse({
              'rate_id': 2,
              'provider': 'ANECO',
              'rate_per_kwh': 10,
              'effective_date': iso(today),
            }, 200);
          case '/api/consumption/history':
            expect(request.url.queryParameters, {
              'household_id': '7',
              'start_date': iso(today),
              'end_date': iso(today),
            });
            return jsonResponse({
              'records': [
                {
                  'date': iso(today),
                  'previous_reading_date': iso(
                    DateTime(today.year, today.month, today.day - 2),
                  ),
                  'kwh': 10,
                },
              ],
            }, 200);
          case '/api/forecasts':
            expect(request.method, 'POST');
            return jsonResponse({
              'forecast_id': 3,
              'forecast_month': '2026-12',
              'predicted_consumption_kwh': 100,
              'estimated_bill': 1150,
              'provider': 'ANECO',
              'rate_per_kwh': 11.5,
              'rate_effective_date': '2026-12-01',
              'rate_message': 'Using the electricity rate effective for the forecast month.',
            }, 200);
          default:
            fail('Unexpected request ${request.url}');
        }
      });
      await http.runWithClient(() async {
        await openForecast(tester, billingDay: today.day);
        expect(find.text('Current Estimated Bill'), findsOneWidget);
        expect(find.text('₱50.00'), findsOneWidget);
        expect(find.text('Projected Cycle Bill'), findsOneWidget);
        await tester.tap(find.text('Generate Forecast'));
        await tester.pumpAndSettle();
        expect(find.text('Monthly XGBoost Forecast'), findsOneWidget);
        expect(find.text('Forecast Estimated Bill'), findsOneWidget);
        expect(find.text('₱1,150.00'), findsOneWidget);
        expect(find.text('December 2026'), findsOneWidget);
        expect(find.text('₱50.00'), findsOneWidget);
        ApiService.logout();
      }, () => client);
    },
  );

  testWidgets(
    'reports a missing provider rate and insufficient monthly history separately',
    (tester) async {
      final client = MockClient((request) async {
        switch (request.url.path) {
          case '/api/auth/login':
            return jsonResponse({'token': testToken(role), 'role': role}, 200);
          case '/api/electricity-rates/current':
            return jsonResponse({
              'error': {
                'code': 'RATE_NOT_FOUND',
                'message': 'No applicable rate.',
              },
            }, 404);
          case '/api/forecasts':
            return jsonResponse({
              'error': {
                'code': 'INSUFFICIENT_HISTORICAL_DATA',
                'message': 'At least six consecutive months of consumption records are required.',
              },
            }, 422);
          default:
            fail('Unexpected request ${request.url}');
        }
      });
      await http.runWithClient(() async {
        await openForecast(tester, billingDay: 15);
        expect(find.text('Provider rate unavailable'), findsOneWidget);
        await tester.tap(find.text('Retry Bill Estimates'));
        await tester.pumpAndSettle();
        expect(find.text('Provider rate unavailable'), findsOneWidget);
        await tester.tap(find.text('Generate Forecast'));
        await tester.pumpAndSettle();
        expect(find.text('Monthly consumption history needed'), findsOneWidget);
        expect(find.textContaining('Use Direct kWh'), findsOneWidget);
        ApiService.logout();
      }, () => client);
    },
  );
}
