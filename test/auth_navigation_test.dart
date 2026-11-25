import 'package:e_forecast/main.dart';
import 'package:e_forecast/screens/admin_dashboard_screen.dart';
import 'package:e_forecast/screens/dashboard_screen.dart';
import 'package:e_forecast/screens/home_screen.dart';
import 'package:e_forecast/screens/login_screen.dart';
import 'package:e_forecast/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service_test.dart' show jsonResponse, testToken;

void main() {
  tearDown(ApiService.logout);

  for (final role in ['ADMIN', 'HOUSEHOLD_USER']) {
    testWidgets('$role signs in through its destination', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 950);
      // The widget-test font has wider glyphs than the browser's font.
      tester.platformDispatcher.textScaleFactorTestValue = 0.8;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      SharedPreferences.setMockInitialValues({});
      var rejectAdminRequests = false;
      final client = MockClient((request) async {
        if (request.url.path == '/api/auth/login') {
          return jsonResponse({'role': role, 'token': testToken(role)}, 200);
        }
        if (request.url.path == '/api/households') {
          return jsonResponse({'households': []}, 200);
        }
        if (request.url.path.startsWith('/api/admin/') &&
            !rejectAdminRequests) {
          final resource = request.url.pathSegments.last;
          return jsonResponse({
            resource == 'consumption' ? 'records' : resource: [],
          }, 200);
        }
        return jsonResponse({
          'error': {'code': 'INVALID_TOKEN', 'message': 'Invalid token'},
        }, 401);
      });
      await http.runWithClient(() async {
        await tester.pumpWidget(const EForecastApp());
        Navigator.of(tester.element(find.byType(HomeScreen)))
            .push(MaterialPageRoute<void>(builder: (_) => const LoginScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        final signIn = find.byKey(const ValueKey('signin'));
        final fields = find.descendant(
          of: signIn,
          matching: find.byType(TextField),
        );
        await tester.enterText(fields.at(0), 'example');
        await tester.enterText(fields.at(1), 'test input');
        await tester.tap(
          find.descendant(of: signIn, matching: find.text('Sign In')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(seconds: 3));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();

        if (role == 'ADMIN') {
          expect(find.byType(AdminDashboardScreen), findsOneWidget);

          // Reject the bearer through the public client, then return to sign-in.
          rejectAdminRequests = true;
          await expectLater(
            ApiService.getAdminRates(),
            throwsA(isA<ApiException>()),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          expect(find.byType(LoginScreen), findsOneWidget);
          expect(
            find.byType(AdminDashboardScreen, skipOffstage: false),
            findsNothing,
          );
          expect(ApiService.session, isNull);
        } else {
          expect(find.byType(DashboardScreen), findsOneWidget);
        }
        ApiService.logout();
        await tester.pumpWidget(const SizedBox());
      }, () => client);
    });
  }
}
