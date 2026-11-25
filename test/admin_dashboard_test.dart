import 'dart:async';
import 'dart:convert';

import 'package:e_forecast/screens/admin_dashboard_screen.dart';
import 'package:e_forecast/services/api_service.dart';
import 'package:e_forecast/theme/landing_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service_test.dart' show jsonResponse, testToken;

const adminRole = 'ADMIN';

http.Response adminLogin([String role = adminRole]) =>
    jsonResponse({'token': testToken(role), 'role': role}, 200);

http.Response emptyCollection(String path) {
  final name = path.split('/').last;
  return jsonResponse({name == 'consumption' ? 'records' : name: []}, 200);
}

Future<void> openDashboard(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1440, 1250);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  SharedPreferences.setMockInitialValues({});
  await ApiService.login(usernameOrEmail: 'example', password: 'test input');
  await tester.pumpWidget(const MaterialApp(home: AdminDashboardScreen()));
}

Finder field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

Future<void> tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  tearDown(ApiService.logout);

  testWidgets(
    'renders admin records, counts, and rate history from authenticated APIs',
    (tester) async {
      final requests = <String>[];
      final client = MockClient((request) async {
        final path = request.url.path;
        if (path == '/api/auth/login') return adminLogin();
        expect(request.method, 'GET');
        expect(request.headers['authorization'], startsWith('Bearer '));
        requests.add(path);
        return switch (path) {
          '/api/admin/users' => jsonResponse({
            'users': [
              {
                'user_id': 7,
                'username': 'test-user',
                'email': 'example@gmail.com',
                'role': 'HOUSEHOLD_USER',
                'created_at': '2026-11-01T00:00:00',
              },
            ],
          }, 200),
          '/api/admin/households' => jsonResponse({
            'households': [
              {
                'household_id': 12,
                'household_name': 'Test home',
                'address': 'Test street',
                'owner': 'test-user',
                'email': 'example@gmail.com',
                'consumption_records': 1,
                'total_kwh': 2.5,
              },
            ],
          }, 200),
          '/api/admin/consumption' => jsonResponse({
            'records': [
              {
                'consumption_id': 4,
                'household': 'Test home',
                'date': '2026-11-15',
                'meter_previous': null,
                'meter_current': 20,
                'kwh': 2.5,
              },
            ],
          }, 200),
          '/api/admin/forecasts' => jsonResponse({
            'forecasts': [
              {
                'forecast_id': 8,
                'household': 'Test home',
                'forecast_type': 'daily',
                'forecast_date': '2026-11-16',
                'predicted_kwh': 3,
                'estimated_bill': 25,
                'created_at': '2026-11-15T10:00:00',
              },
              {
                'forecast_id': 9,
                'household': 'Test home',
                'forecast_type': 'monthly',
                'forecast_date': '2026-12-01',
                'predicted_kwh': 124,
                'estimated_bill': 825,
                'created_at': '2026-11-15T10:00:00',
              },
            ],
          }, 200),
          '/api/admin/rates' => jsonResponse({
            'rates': [
              {
                'rate_id': 4,
                'provider': 'ANECO',
                'rate_per_kwh': 6.25,
                'effective_date': '2026-11-01',
                'source_url': 'https://example.org/rates',
                'remarks': 'Test notice',
                'created_at': null,
              },
              {
                'rate_id': 3,
                'provider': null,
                'rate_per_kwh': 5,
                'effective_date': '2026-10-01',
              },
            ],
          }, 200),
          _ => fail('Unexpected request $path'),
        };
      });

      await http.runWithClient(() async {
        await openDashboard(tester);
        await tester.pumpAndSettle();
        expect(find.text('Overview'), findsOneWidget);
        expect(find.text('1'), findsNWidgets(3));
        expect(find.text('2'), findsOneWidget);
        await tap(tester, find.text('User Management'));
        expect(find.text('test-user'), findsOneWidget);
        await tap(tester, find.text('Household Monitoring'));
        expect(find.text('Test street'), findsOneWidget);
        await tap(tester, find.text('Consumption Records'));
        expect(find.text('Previous Meter'), findsOneWidget);
        await tap(tester, find.text('Forecast Records'));
        expect(find.text('Legacy daily'), findsOneWidget);
        expect(find.text('December 2026'), findsOneWidget);
        await tap(tester, find.text('Electricity Rates'));
        expect(find.text('Rate History'), findsOneWidget);
        expect(find.text('https://example.org/rates'), findsOneWidget);
        expect(find.text('Legacy / Unassigned'), findsOneWidget);
        expect(requests.toSet().length, 5);
        expect(requests.length, 5);
        await tap(tester, find.byTooltip('Switch to dark mode'));
        expect(
          Theme.of(tester.element(find.text('Overview'))).brightness,
          Brightness.dark,
        );
        tester.view.physicalSize = const Size(390, 850);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        ThemeController.resetToLight();
        ApiService.logout();
        await tester.pumpWidget(const SizedBox());
      }, () => client);
    },
  );

  testWidgets(
    'saves a provider rate with its effective date and refreshes history',
    (tester) async {
      Map<String, dynamic>? savedRate;
      var rateReads = 0;
      final client = MockClient((request) async {
        final path = request.url.path;
        if (path == '/api/auth/login') return adminLogin();
        if (path != '/api/admin/rates') return emptyCollection(path);
        if (request.method == 'GET') {
          rateReads++;
          return jsonResponse({
            'rates': [?savedRate],
          }, 200);
        }
        expect(request.method, 'PUT');
        expect(request.headers['authorization'], startsWith('Bearer '));
        final payload = jsonDecode(request.body) as Map<String, dynamic>;
        final today = DateTime.now();
        expect(payload, {
          'provider': 'ANECO',
          'rate_per_kwh': 8.125,
          'effective_date': DateTime(
            today.year,
            today.month,
            today.day,
          ).toIso8601String().split('T').first,
          'source_url': 'https://example.org/notice',
          'remarks': 'Test notice',
        });
        savedRate = {...payload, 'rate_id': 4};
        return jsonResponse(savedRate!, 200);
      });

      await http.runWithClient(() async {
        await openDashboard(tester);
        await tester.pumpAndSettle();
        await tap(tester, find.text('Electricity Rates'));
        expect(find.text('No rate records found.'), findsOneWidget);
        await tap(tester, find.text('Save Rate'));
        expect(find.text('Choose a provider.'), findsOneWidget);
        expect(find.text('Choose the effective date.'), findsOneWidget);
        expect(savedRate, isNull);
        await tap(tester, find.byType(DropdownButtonFormField<String>));
        await tap(tester, find.text('ANECO').last);
        await tester.enterText(field('Rate per kWh (₱)'), '8.125');
        await tap(tester, field('Effective Date'));
        await tap(tester, find.text('OK'));
        await tester.enterText(
          field('Official Source URL (optional)'),
          'https://example.org/notice',
        );
        await tester.enterText(field('Remarks (optional)'), 'Test notice');
        await tap(tester, find.text('Save Rate'));
        expect(rateReads, 2);
        expect(find.text('8.1250'), findsOneWidget);
        expect(find.text('https://example.org/notice'), findsOneWidget);
        expect(find.text('Electricity rate saved.'), findsOneWidget);
        expect(
          tester
              .widget<FormField<String>>(
                find.byType(DropdownButtonFormField<String>),
              )
              .initialValue,
          isNull,
        );
        ApiService.logout();
        await tester.pumpWidget(const SizedBox());
      }, () => client);
    },
  );

  testWidgets('shows loading and retries only the failed resource', (
    tester,
  ) async {
    final pending = Completer<http.Response>();
    var users = 0;
    var households = 0;
    final client = MockClient((request) async {
      final path = request.url.path;
      if (path == '/api/auth/login') return adminLogin();
      if (path == '/api/admin/households') households++;
      if (path == '/api/admin/users' && users++ == 0) return pending.future;
      return emptyCollection(path);
    });

    await http.runWithClient(() async {
      await openDashboard(tester);
      expect(find.text('Loading'), findsWidgets);
      pending.complete(
        jsonResponse({
          'error': {'message': 'Unavailable'},
        }, 503),
      );
      await tester.pumpAndSettle();
      await tap(tester, find.text('User Management'));
      expect(
        find.text('The server had a problem. Please try again later.'),
        findsOneWidget,
      );
      await tap(tester, find.text('Retry'));
      expect(find.text('No users found.'), findsOneWidget);
      expect(users, 2);
      expect(households, 1);
      ApiService.logout();
      await tester.pumpWidget(const SizedBox());
    }, () => client);
  });

  for (final role in ['HOUSEHOLD_USER', adminRole]) {
    testWidgets('blocks admin views when access is denied for $role', (
      tester,
    ) async {
      var requests = 0;
      final client = MockClient((request) async {
        if (request.url.path == '/api/auth/login') return adminLogin(role);
        requests++;
        return jsonResponse({
          'error': {
            'code': 'FORBIDDEN',
            'message': 'You do not have permission for this action',
          },
        }, 403);
      });

      await http.runWithClient(() async {
        await openDashboard(tester);
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Administrator access required'),
          findsOneWidget,
        );
        expect(find.text('Overview'), findsNothing);
        expect(find.text('Electricity Rates'), findsNothing);
        expect(requests, role == adminRole ? 5 : 0);
        ApiService.logout();
        await tester.pumpWidget(const SizedBox());
      }, () => client);
    });
  }
}
