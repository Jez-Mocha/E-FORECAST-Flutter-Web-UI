import 'dart:convert';

import 'package:e_forecast/models/household.dart';
import 'package:e_forecast/screens/record_consumption_screen.dart';
import 'package:e_forecast/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'api_service_test.dart' show jsonResponse, testToken;

const role = 'HOUSEHOLD_USER';
const household = Household(
  id: 7,
  name: 'Test home',
  street: 'Test street',
  city: 'Test city',
  numberOfAppliances: 2,
  provider: 'ANECO',
  ratePerKwh: null,
  billingCycleDay: 25,
);

String iso(DateTime date) => date.toIso8601String().split('T').first;

Finder field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

Future<Future<bool?>> openForm(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1440, 1150);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await ApiService.login(usernameOrEmail: 'example', password: 'test input');
  final navigator = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    MaterialApp(navigatorKey: navigator, home: const Scaffold()),
  );
  final result = navigator.currentState!.push<bool>(
    MaterialPageRoute(
      builder: (_) => const RecordConsumptionScreen(household: household),
    ),
  );
  await tester.pumpAndSettle();
  return result;
}

Future<void> submit(WidgetTester tester) async {
  final button = find.widgetWithText(ElevatedButton, 'Record Consumption');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> confirmSuccess(WidgetTester tester, Future<bool?> result) async {
  expect(find.text('Consumption recorded successfully.'), findsOneWidget);
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
  expect(await result, isTrue);
  ApiService.logout();
}

void main() {
  tearDown(ApiService.logout);

  testWidgets('uses actual meter baseline and sends both dates', (
    tester,
  ) async {
    final now = DateTime.now();
    final previousDate = DateTime(now.year, now.month, now.day - 1);
    final client = MockClient((request) async {
      switch (request.url.path) {
        case '/api/auth/login':
          return jsonResponse({'token': testToken(role), 'role': role}, 200);
        case '/api/consumption/latest-meter':
          return jsonResponse({
            'has_previous_record': true,
            'last_meter_reading': 12.25,
            'last_consumption_date': iso(previousDate),
          }, 200);
        case '/api/consumption':
          expect(jsonDecode(request.body), {
            'household_id': 7,
            'consumption_date': iso(now),
            'previous_reading_date': iso(previousDate),
            'meter_previous': 12.25,
            'meter_current': 15,
          });
          return jsonResponse({'kwh': 2.75}, 201);
        default:
          fail('Unexpected request ${request.url}');
      }
    });

    await http.runWithClient(() async {
      final result = await openForm(tester);
      final previous = tester.widget<TextField>(
        field('Previous meter reading'),
      );
      expect(previous.readOnly, isTrue);
      expect(previous.controller?.text, '12.25');
      final baseline = tester.widget<TextField>(field('Previous reading date'));
      expect(baseline.controller?.text, isNotEmpty);
      expect(baseline.onTap, isNull);
      await tester.enterText(field('Current meter reading'), '15');
      await submit(tester);
      await confirmSuccess(tester, result);
    }, () => client);
  });

  testWidgets('prefilling today’s reading does not show premature errors', (
    tester,
  ) async {
    final client = MockClient((request) async {
      if (request.url.path == '/api/auth/login') {
        return jsonResponse({'token': testToken(role), 'role': role}, 200);
      }
      expect(request.url.path, '/api/consumption/latest-meter');
      return jsonResponse({
        'has_previous_record': true,
        'last_meter_reading': 15,
        'last_consumption_date': iso(DateTime.now()),
      }, 200);
    });

    await http.runWithClient(() async {
      await openForm(tester);
      expect(find.textContaining('Choose a date after'), findsNothing);
      expect(find.text('Enter the current meter reading'), findsNothing);
      await tester.enterText(field('Current meter reading'), '16');
      await submit(tester);
      expect(find.textContaining('Choose a date after'), findsOneWidget);
      expect(find.text('Must be before the consumption date'), findsNothing);
      ApiService.logout();
      await tester.pumpWidget(const SizedBox());
    }, () => client);
  });

  testWidgets(
    'first meter reading requires a manually selected baseline date',
    (tester) async {
      final now = DateTime.now();
      final previousDate = DateTime(now.year, now.month, now.day - 1);
      var attempts = 0;
      final client = MockClient((request) async {
        if (request.url.path == '/api/auth/login') {
          return jsonResponse({'token': testToken(role), 'role': role}, 200);
        }
        if (request.url.path == '/api/consumption/latest-meter') {
          return jsonResponse({'has_previous_record': false}, 200);
        }
        attempts++;
        expect(request.url.path, '/api/consumption');
        expect(
          jsonDecode(request.body)['previous_reading_date'],
          iso(previousDate),
        );
        return jsonResponse({'kwh': 1.25}, 201);
      });

      await http.runWithClient(() async {
        final result = await openForm(tester);
        await tester.enterText(field('Previous meter reading'), '9');
        await tester.enterText(field('Current meter reading'), '10.25');
        await submit(tester);
        expect(find.text('Choose the previous reading date'), findsOneWidget);
        expect(attempts, 0);
        await tester.tap(field('Previous reading date'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        await submit(tester);
        expect(attempts, 1);
        await confirmSuccess(tester, result);
      }, () => client);
    },
  );

  testWidgets(
    'Direct kWh works without meter history and shows backend errors',
    (tester) async {
      final now = DateTime.now();
      final month = DateTime(now.year, now.month);
      var attempts = 0;
      final client = MockClient((request) async {
        if (request.url.path == '/api/auth/login') {
          return jsonResponse({'token': testToken(role), 'role': role}, 200);
        }
        if (request.url.path == '/api/consumption/latest-meter') {
          return jsonResponse({
            'error': {'message': 'History unavailable'},
          }, 503);
        }
        expect(request.url.path, '/api/monthly-consumption');
        expect(jsonDecode(request.body), {
          'household_id': 7,
          'billing_month': iso(month),
          'consumption_kwh': 42.5,
        });
        if (attempts++ == 0) {
          return jsonResponse({
            'error': {
              'code': 'DUPLICATE_MONTHLY_CONSUMPTION',
              'message': 'A record already exists for this billing month.',
            },
          }, 409);
        }
        return jsonResponse({
          'billing_month': iso(month).substring(0, 7),
          'consumption_kwh': 42.5,
        }, 201);
      });

      await http.runWithClient(() async {
        final result = await openForm(tester);
        expect(find.text('Retry meter history'), findsOneWidget);
        await tester.tap(find.text('Direct kWh'));
        await tester.pumpAndSettle();
        expect(field('Previous meter reading'), findsNothing);
        await tester.enterText(field('Consumption in kWh'), '42.5');
        await submit(tester);
        expect(
          find.text('A record already exists for this billing month.'),
          findsOneWidget,
        );
        expect(
          tester
              .widget<TextField>(field('Consumption in kWh'))
              .controller
              ?.text,
          '42.5',
        );
        await submit(tester);
        await confirmSuccess(tester, result);
      }, () => client);
    },
  );
}
