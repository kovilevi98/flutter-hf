import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_homework/main.dart';
import 'package:flutter_homework/ui/provider/login/login_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDio extends Mock implements Dio {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

class FixLoadingLoginModel extends LoginModel {
  @override
  // ignore: overridden_fields
  var isLoading = true;
}

void main() {
  setUp(() async {
    var dioMock = MockDio();
    when(() => dioMock.options).thenReturn(BaseOptions());
    GetIt.I.registerSingleton<Dio>(dioMock);
    GetIt.I.registerSingleton<SharedPreferences>(MockSharedPreferences());
    configureCustomDependencies();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  test('tryAutoLogin reads token from SharedPreferences, returns true [1]', () {
    var model = LoginModel();
    when(() => GetIt.I<SharedPreferences>().containsKey(any()))
        .thenReturn(true);
    when(() => GetIt.I<SharedPreferences>().getString(any()))
        .thenReturn('token');

    expect(model.tryAutoLogin(), completion(true));
    verify(() => GetIt.I<SharedPreferences>().getString(any()));
  });

  test('tryAutoLogin tries reading token from SharedPreferences, returns false [1]',
      () {
    var model = LoginModel();
    when(() => GetIt.I<SharedPreferences>().containsKey(any()))
        .thenReturn(false);

    expect(model.tryAutoLogin(), completion(false));
  });

  test('login does nothing when isLoading is true [1]', () async {
    var model = FixLoadingLoginModel();
    await model.login('', '', false);
    verifyZeroInteractions(GetIt.I<SharedPreferences>());
    verifyZeroInteractions(GetIt.I<Dio>());
  });

  group(
      'login calls correct network call with parameters for different values, token is not saved [3]',
      () {
    var emails = ['test@test.com', 'a@a.com'];
    var passwords = ['12345678', 'abcdefgh'];
    for (var email in emails) {
      for (var password in passwords) {
        test(
            'login calls correct network call with parameters for different values, token is not saved',
            () async {
          var model = LoginModel();
          var completer = Completer<Response>();
          when(
            () => GetIt.I<Dio>().post(
              '/login',
              data: {
                'email': email,
                'password': password,
              },
            ),
          ).thenAnswer(
            (_) => completer.future,
          );
          var loginRequest = model.login(email, password, false);
          expect(model.isLoading, true);
          completer.complete(
            Response(
              data: {'token': 'TOKEN'},
              requestOptions: RequestOptions(path: '/login'),
            ),
          );
          await loginRequest;
          expect(model.isLoading, false);
          verifyZeroInteractions(GetIt.I<SharedPreferences>());
          verify(() => GetIt.I<Dio>().post(any(), data: any(named: 'data')));
        });
      }
    }
  });

  group('login saves token when rememberMe is true [1]', () {
    var testTokens = ['TEST_TOKEN_1', 'TEST_TOKEN_2'];
    for (var token in testTokens) {
      test('login saves token when rememberMe is true', () async {
        var model = LoginModel();
        when(
          () => GetIt.I<Dio>().post(
            '/login',
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: {'token': token},
            requestOptions: RequestOptions(path: '/login'),
          ),
        );
        when(() => GetIt.I<SharedPreferences>().setString(any(), token))
            .thenAnswer(
          (value) async => true,
        );
        await model.login('', '', true);
        verify(() => GetIt.I<SharedPreferences>().setString(any(), any()));
        verifyNoMoreInteractions(GetIt.I<SharedPreferences>());
        verify(() => GetIt.I<Dio>().post(any(), data: any(named: 'data')));
      });
    }
  });

  group('Errors are sent with LoginException [1]', () {
    var errors = ['TEST_ERROR_1', 'TEST_ERROR_2'];
    for (var error in errors) {
      test('Errors are sent with LoginException', () async {
        var model = LoginModel();
        var completer = Completer<Response>();
        when(
          () => GetIt.I<Dio>().post(
            '/login',
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) => completer.future,
        );
        var options = RequestOptions(path: '/login');
        completer.completeError(
          DioError(
            requestOptions: options,
            response: Response(
              data: {'message': error},
              requestOptions: options,
            ),
            type: DioErrorType.response,
          ),
        );
        var loginRequest = model.login('', '', false);
        expect(model.isLoading, true);
        await expectLater(
          loginRequest,
          throwsA(
            LoginException(error),
          ),
        );
        expect(model.isLoading, false);
        verifyZeroInteractions(GetIt.I<SharedPreferences>());
        verify(() => GetIt.I<Dio>().post(any(), data: any(named: 'data')));
      });
    }
  });
}
