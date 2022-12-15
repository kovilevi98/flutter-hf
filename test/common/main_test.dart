import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_homework/main.dart';
import 'package:flutter_homework/network/user_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mocktail_image_network/mocktail_image_network.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDio extends Mock implements Dio {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

class RouteFake extends Fake implements Route<dynamic> {}

void main() {
  NavigatorObserver getMockNavigatorObserver() =>
      GetIt.I<List<NavigatorObserver>>().first;

  setUp(() async {
    var dioMock = MockDio();
    when(() => dioMock.options).thenReturn(BaseOptions());
    GetIt.I.registerSingleton<Dio>(dioMock);
    GetIt.I.registerSingleton<SharedPreferences>(MockSharedPreferences());
    GetIt.I.registerSingleton(<NavigatorObserver>[MockNavigatorObserver()]);
    registerFallbackValue(RouteFake());
    configureCustomDependencies();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  group('No network communication, missing token', () {
    setUp(() async {
      when(() => GetIt.I<SharedPreferences>().containsKey(any()))
          .thenReturn(false);
      when(() => GetIt.I<SharedPreferences>().getString(any()))
          .thenReturn(null);
    });
    testWidgets('MyApp loads, stays on LoginPage if token is not saved [0]',
        (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      var route =
          verify(() => getMockNavigatorObserver().didPush(captureAny(), null))
              .captured
              .first as Route;
      expect(route.settings.name, '/');
    });
    group('Incorrect field errors shown [5]', () {
      var correctEmail = 'a@a.com';
      var correctPassword = '12345678';
      var emails = [correctEmail, 'wrong_email'];
      var passwords = [correctPassword, '12'];
      for (var email in emails) {
        for (var password in passwords) {
          if (email == correctEmail && password == correctPassword) {
            continue;
          }

          testWidgets('Error field is shown, clears on change', (tester) async {
            await tester.pumpWidget(const MyApp());
            await tester.pumpAndSettle();
            await tester.enterText(find.byType(TextField).first, email);
            await tester.enterText(find.byType(TextField).last, password);
            await tester.tap(find.bySubtype<ButtonStyleButton>());
            await tester.pumpAndSettle();
            var textFields =
                tester.widgetList<TextField>(find.bySubtype<TextField>());
            expect(textFields.first.decoration?.errorText,
                email == correctEmail ? null : isNotEmpty);
            expect(textFields.last.decoration?.errorText,
                password == correctPassword ? null : isNotEmpty);

            await tester.enterText(find.byType(TextField).first, '');
            await tester.enterText(find.byType(TextField).last, '');
            await tester.pumpAndSettle();
            textFields =
                tester.widgetList<TextField>(find.bySubtype<TextField>());
            expect(textFields.first.decoration?.errorText, null);
            expect(textFields.last.decoration?.errorText, null);
          });
        }
      }
    });
  });

  group('Has correct network communication', () {
    const _testToken = 'TEST_TOKEN';
    final _testUsers = [
      for (int i = 0; i < 10; i++) UserItem('Test User $i', 'Test Image $i'),
    ];
    const _correctEmail = 'login@gmail.com';
    const _correctPassword = 'password';
    setUp(() async {
      when(
        () => GetIt.I<Dio>().post(
          '/login',
          data: {
            'email': _correctEmail,
            'password': _correctPassword,
          },
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {'token': _testToken},
          requestOptions: RequestOptions(path: '/login'),
        ),
      );
      when(() => GetIt.I<Dio>().get('/users')).thenAnswer(
        (_) async => Response(
          data: [
            for (var user in _testUsers)
              {
                'name': user.name,
                'avatarUrl': user.avatarUrl,
              }
          ],
          requestOptions: RequestOptions(path: '/users'),
        ),
      );
    });
    group('No saved token', () {
      setUp(() async {
        when(() => GetIt.I<SharedPreferences>().containsKey(any()))
            .thenReturn(false);
        when(() => GetIt.I<SharedPreferences>().getString(any()))
            .thenReturn(null);
        when(() => GetIt.I<SharedPreferences>().setString(any(), any()))
            .thenAnswer((_) async => true);
      });

      testWidgets(
        'Token is saved if remember me is checked, navigation succeeds, uses token [5]',
        (tester) async => mockNetworkImages(
          () async {
            await tester.pumpWidget(const MyApp());
            await tester.pumpAndSettle();
            await tester.enterText(
              find.byType(TextField).first,
              _correctEmail,
            );
            await tester.enterText(
              find.byType(TextField).last,
              _correctPassword,
            );
            await tester.tap(find.bySubtype<Checkbox>());
            await tester.tap(find.bySubtype<ButtonStyleButton>());
            await tester.pumpAndSettle();

            var route = verify(
              () => getMockNavigatorObserver().didReplace(
                newRoute: captureAny(named: 'newRoute'),
                oldRoute: any(named: 'oldRoute'),
              ),
            ).captured.first as Route;
            expect(route.settings.name, '/list');
            var tokenKey = verify(() =>
                    GetIt.I<SharedPreferences>().containsKey(captureAny()))
                .captured
                .first as String;
            verify(() =>
                GetIt.I<SharedPreferences>().setString(tokenKey, _testToken));
          },
        ),
      );
      group('Has saved token', () {
        setUp(() async {
          when(() => GetIt.I<SharedPreferences>().containsKey(any()))
              .thenReturn(true);
          when(() => GetIt.I<SharedPreferences>().getString(any()))
              .thenReturn(_testToken);
        });

        testWidgets(
          'MyApp loads, switches to ListPage [5]',
          (tester) async => mockNetworkImages(
            () async {
              await tester.pumpWidget(const MyApp());
              await tester.pumpAndSettle();
              var route = verify(
                () => getMockNavigatorObserver().didReplace(
                  newRoute: captureAny(named: 'newRoute'),
                  oldRoute: any(named: 'oldRoute'),
                ),
              ).captured.first as Route;
              expect(route.settings.name, '/list');
            },
          ),
        );

        testWidgets(
          'Sign out works on ListPage [2]',
          (tester) async => mockNetworkImages(
            () async {
              when(() => GetIt.I<SharedPreferences>().clear())
                  .thenAnswer((_) async => true);
              await tester.pumpWidget(const MyApp());
              await tester.pumpAndSettle();
              await tester.tap(find.bySubtype<IconButton>());
              await tester.pumpAndSettle();

              var route = verify(
                () => getMockNavigatorObserver().didReplace(
                  newRoute: captureAny(named: 'newRoute'),
                  oldRoute: any(named: 'oldRoute'),
                ),
              ).captured.skip(1).first as Route;
              expect(route.settings.name, '/');
              verify(() => GetIt.I<SharedPreferences>().clear());
            },
          ),
        );
      });
    });
  });
}
