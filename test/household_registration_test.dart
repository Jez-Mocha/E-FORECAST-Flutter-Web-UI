import 'dart:convert';

import 'package:e_forecast/models/household.dart';
import 'package:e_forecast/screens/add_household_screen.dart';
import 'package:e_forecast/screens/household_dashboard_screen.dart';
import 'package:e_forecast/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'api_service_test.dart' show jsonResponse, testToken;

void main() {
  tearDown(ApiService.logout);

  testWidgets('saves provider and billing settings and shows the server rate', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1100);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    const role = 'HOUSEHOLD_USER';
    final client = MockClient((request) async {
      switch (request.url.path) {
        case '/api/auth/login':
          return jsonResponse({'token': testToken(role), 'role': role}, 200);
        case '/api/households':
          final payload = jsonDecode(request.body) as Map<String, dynamic>;
          expect(payload, {
            'household_name': 'Test home',
            'meter_number': 'TEST-METER',
            'address': 'Example street, Example city',
            'occupants': 4,
            'electricity_provider': 'ANECO',
            'billing_cycle_day': 31,
          });
          return jsonResponse({
            ...payload,
            'household_id': 7,
            'rate_per_kwh': null,
          }, 201);
        case '/api/electricity-rates/current':
          expect(request.url.queryParameters['household_id'], '7');
          return jsonResponse({
            'rate_id': 9,
            'provider': 'ANECO',
            'rate_per_kwh': 8.125,
            'effective_date': '2026-11-01',
          }, 200);
        default:
          fail('Unexpected request ${request.url}');
      }
    });

    await http.runWithClient(() async {
      await ApiService.login(
        usernameOrEmail: 'example',
        password: 'test input',
      );
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(navigatorKey: navigator, home: const Scaffold()),
      );
      final saved = navigator.currentState!.push<Household>(
        MaterialPageRoute(builder: (_) => const AddHouseholdScreen()),
      );
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      for (final entry in [
        'Test home',
        'TEST-METER',
        'Example street',
        'Example city',
        '4',
        '31',
      ].indexed) {
        await tester.enterText(fields.at(entry.$1), entry.$2);
      }
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ANECO').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Household'));
      await tester.pumpAndSettle();
      final household = (await saved)!;
      expect(household.ratePerKwh, isNull);

      await tester.pumpWidget(
        MaterialApp(home: HouseholdDashboardScreen(household: household)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('₱8.125', findRichText: true), findsOneWidget);
      ApiService.logout();
      await tester.pumpWidget(const SizedBox());
    }, () => client);
  });

  testWidgets('adds missing billing settings to an existing household', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 950);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final household = Household.fromJson({
      'household_id': 7,
      'household_name': 'Legacy home',
      'address': 'Example street',
      'rate_per_kwh': 1.25,
    });
    Household? updated;
    final client = MockClient((request) async {
      switch (request.url.path) {
        case '/api/auth/login':
          const role = 'HOUSEHOLD_USER';
          return jsonResponse({'token': testToken(role), 'role': role}, 200);
        case '/api/households/7/billing':
          expect(request.method, 'PUT');
          final payload = jsonDecode(request.body) as Map<String, dynamic>;
          expect(payload, {
            'electricity_provider': 'ANECO',
            'billing_cycle_day': 15,
          });
          return jsonResponse({
            'household_id': 7,
            'household_name': 'Legacy home',
            'address': 'Example street',
            ...payload,
          }, 200);
        case '/api/electricity-rates/current':
          return jsonResponse({
            'rate_id': 9,
            'provider': 'ANECO',
            'rate_per_kwh': 8.125,
            'effective_date': '2026-11-01',
          }, 200);
        default:
          fail('Unexpected request ${request.url}');
      }
    });
    await http.runWithClient(() async {
      await ApiService.login(
        usernameOrEmail: 'example',
        password: 'test input',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: HouseholdDashboardScreen(
            household: household,
            onBillingUpdated: (household) => updated = household,
          ),
        ),
      );
      expect(find.text('Rate unavailable'), findsOneWidget);
      expect(find.textContaining('₱1.25', findRichText: true), findsNothing);
      expect(find.text('Not set'), findsWidgets);
      await tester.tap(find.text('Edit Billing Settings'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '15');
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ANECO').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Billing Settings'));
      await tester.pumpAndSettle();
      expect(updated?.id, 7);
      expect(updated?.billingCycleDay, 15);
      expect(find.textContaining('₱8.125', findRichText: true), findsOneWidget);

      await tester.tap(find.text('Edit Billing Settings'));
      await tester.pumpAndSettle();
      expect(find.text('15'), findsOneWidget);
      expect(find.text('ANECO'), findsWidgets);
      ApiService.logout();
      await tester.pumpWidget(const SizedBox());
    }, () => client);
  });
}
