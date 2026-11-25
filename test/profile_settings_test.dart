import 'dart:async';
import 'dart:convert';

import 'package:e_forecast/screens/home_screen.dart';
import 'package:e_forecast/screens/profile_settings_screen.dart';
import 'package:e_forecast/services/api_service.dart';
import 'package:e_forecast/theme/landing_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service_test.dart' show jsonResponse, testToken;

const role = 'HOUSEHOLD_USER';
const initial = {'username': 'original', 'email': 'original@gmail.com'};

Finder field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

Future<void> openProfile(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1440, 1150);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  SharedPreferences.setMockInitialValues({});
  await ApiService.login(usernameOrEmail: 'example', password: 'test input');
  await tester.pumpWidget(const MaterialApp(home: ProfileSettingsScreen()));
}

void main() {
  tearDown(ApiService.logout);

  testWidgets(
    'loads the real profile, validates edits and uses the saved server response',
    (tester) async {
      final loading = Completer<http.Response>();
      final saving = Completer<http.Response>();
      var writes = 0;
      final client = MockClient((request) async {
        if (request.url.path == '/api/auth/login') {
          return jsonResponse({'token': testToken(role), 'role': role}, 200);
        }
        expect(request.url.path, '/api/users/me');
        expect(
          request.headers['authorization'],
          'Bearer ${ApiService.session!.token}',
        );
        if (request.method == 'GET') return loading.future;
        expect(request.method, 'PUT');
        final payload = jsonDecode(request.body) as Map<String, dynamic>;
        if (writes++ == 0) {
          expect(payload, {'username': 'taken', 'email': 'edited@gmail.com'});
          return jsonResponse({
            'error': {
              'code': 'USERNAME_ALREADY_EXISTS',
              'message': 'This username is already in use.',
            },
          }, 409);
        }
        expect(payload, {'username': 'edited', 'email': 'edited@gmail.com'});
        return saving.future;
      });

      await http.runWithClient(() async {
        await openProfile(tester);
        expect(find.text('Loading profile…'), findsOneWidget);
        loading.complete(jsonResponse(initial, 200));
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextField>(field('Username')).controller?.text,
          'original',
        );
        expect(tester.widget<TextField>(field('Username')).readOnly, isTrue);

        await tester.tap(find.text('Edit Profile'));
        await tester.pumpAndSettle();
        await tester.enterText(field('Username'), 'ab');
        await tester.enterText(field('Email'), 'edited@example.org');
        await tester.tap(find.text('Save Changes'));
        await tester.pump();
        expect(find.text('Use 3–50 characters.'), findsOneWidget);
        expect(find.textContaining('Enter a valid Gmail'), findsOneWidget);
        expect(writes, 0);

        await tester.enterText(field('Username'), 'taken');
        await tester.enterText(field('Email'), ' EDITED@Gmail.com ');
        await tester.tap(find.text('Save Changes'));
        await tester.pumpAndSettle();
        expect(find.text('This username is already in use.'), findsOneWidget);

        await tester.enterText(field('Username'), '  edited  ');
        await tester.tap(find.text('Save Changes'));
        await tester.pump();
        expect(find.text('Saving…'), findsOneWidget);
        saving.complete(
          jsonResponse({
            'username': 'edited',
            'email': 'edited@gmail.com',
          }, 200),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Profile updated successfully.'), findsOneWidget);
        expect(
          tester.widget<TextField>(field('Email')).controller?.text,
          'edited@gmail.com',
        );
        expect(tester.widget<TextField>(field('Username')).readOnly, isTrue);
        ApiService.logout();
        await tester.pumpWidget(const SizedBox());
      }, () => client);
    },
  );

  testWidgets(
    'retries loading, discards cancelled edits, and keeps theme and logout',
    (tester) async {
      var reads = 0;
      final client = MockClient((request) async {
        if (request.url.path == '/api/auth/login') {
          return jsonResponse({'token': testToken(role), 'role': role}, 200);
        }
        expect(request.method, 'GET');
        expect(request.url.path, '/api/users/me');
        if (reads++ == 0) {
          return jsonResponse({
            'error': {'message': 'Service unavailable'},
          }, 503);
        }
        return jsonResponse(initial, 200);
      });

      await http.runWithClient(() async {
        await openProfile(tester);
        await tester.pumpAndSettle();
        expect(find.text('Retry'), findsOneWidget);
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Edit Profile'));
        await tester.pumpAndSettle();
        await tester.enterText(field('Email'), 'unsaved@gmail.com');
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextField>(field('Email')).controller?.text,
          'original@gmail.com',
        );

        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();
        expect(ThemeController.isDark, isTrue);
        await tester.tap(find.text('Logout'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(ApiService.session, isNull);
        expect(ThemeController.isDark, isFalse);
        await tester.pumpWidget(const SizedBox());
      }, () => client);
    },
  );
}
