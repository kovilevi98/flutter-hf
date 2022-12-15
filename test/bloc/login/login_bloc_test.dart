import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_homework/main.dart';
import 'package:flutter_homework/ui/bloc/login/login_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDio extends Mock implements Dio {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

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

  blocTest<LoginBloc, LoginState>(
    'Bloc starts in LoginForm state [0]',
    build: () => LoginBloc(),
    expect: () => [],
    verify: (bloc) {
      expect(bloc.state, LoginForm());
    },
  );

  blocTest<LoginBloc, LoginState>(
    'AutoLoginEvent reads token from SharedPreferences, sends success state [1]',
    build: () => LoginBloc(),
    act: (bloc) => bloc.add(LoginAutoLoginEvent()),
    expect: () => [LoginSuccess()],
    setUp: () {
      when(() => GetIt.I<SharedPreferences>().containsKey(any()))
          .thenReturn(true);
      when(() => GetIt.I<SharedPreferences>().getString(any()))
          .thenReturn('token');
    },
    verify: (bloc) {
      verify(() => GetIt.I<SharedPreferences>().getString(any()));
    },
  );

  blocTest<LoginBloc, LoginState>(
    'AutoLoginEvent tries reading token from SharedPreferences, nothing happens [1]',
    build: () => LoginBloc(),
    act: (bloc) => bloc.add(LoginAutoLoginEvent()),
    expect: () => [],
    setUp: () {
      when(() => GetIt.I<SharedPreferences>().containsKey(any()))
          .thenReturn(false);
    },
  );

  blocTest<LoginBloc, LoginState>(
      'LoginSubmitEvent does nothing in Loading state [1]',
      build: () => LoginBloc(),
      act: (bloc) => bloc.add(LoginSubmitEvent('email', 'password', false)),
      seed: () => LoginLoading(),
      expect: () => [],
      verify: (bloc) {
        verifyZeroInteractions(GetIt.I<SharedPreferences>());
        verifyZeroInteractions(GetIt.I<Dio>());
      });

  group(
      'LoginSubmitEvent calls correct network call with parameters for different values, token is not saved [3]',
          () {
        var emails = ['test@test.com', 'a@a.com'];
        var passwords = ['12345678', 'abcdefgh'];
        for (var email in emails) {
          for (var password in passwords) {
            blocTest<LoginBloc, LoginState>(
              'LoginSubmitEvent calls correct network call with parameters',
              build: () => LoginBloc(),
              act: (bloc) => bloc.add(LoginSubmitEvent(email, password, false)),
              expect: () => [LoginLoading(), LoginSuccess(), LoginForm()],
              setUp: () {
                when(
                      () =>
                      GetIt.I<Dio>().post(
                        '/login',
                        data: {
                          'email': email,
                          'password': password,
                        },
                      ),
                ).thenAnswer(
                      (_) async =>
                      Response(
                        data: {'token': 'TOKEN'},
                        requestOptions: RequestOptions(path: '/login'),
                      ),
                );
              },
              verify: (bloc) {
                verifyZeroInteractions(GetIt.I<SharedPreferences>());
                verify(() =>
                    GetIt.I<Dio>().post(any(), data: any(named: 'data')));
              },
            );
          }
        }
      });

  group('LoginSubmitEvent saves token when rememberMe is true [1]', () {
    var testTokens = ['TEST_TOKEN_1', 'TEST_TOKEN_2'];
    for (var token in testTokens) {
      blocTest<LoginBloc, LoginState>(
        'LoginSubmitEvent saves token when rememberMe is true',
        build: () => LoginBloc(),
        act: (bloc) => bloc.add(LoginSubmitEvent('', '', true)),
        expect: () => [LoginLoading(), LoginSuccess(), LoginForm()],
        setUp: () {
          when(
                () =>
                GetIt.I<Dio>().post(
                  '/login',
                  data: any(named: 'data'),
                ),
          ).thenAnswer(
                (_) async =>
                Response(
                  data: {'token': token},
                  requestOptions: RequestOptions(path: '/login'),
                ),
          );
          when(() => GetIt.I<SharedPreferences>().setString(any(), token))
              .thenAnswer(
                (value) async => true,
          );
        },
        verify: (bloc) {
          verify(() => GetIt.I<SharedPreferences>().setString(any(), any()));
          verifyNoMoreInteractions(GetIt.I<SharedPreferences>());
          verify(() => GetIt.I<Dio>().post(any(), data: any(named: 'data')));
        },
      );
    }
  });

  group('Errors are sent through LoginError state [1]', () {
    var errors = ['TEST_ERROR_1', 'TEST_ERROR_2'];
    for (var error in errors) {
      blocTest<LoginBloc, LoginState>(
        'Errors are sent through LoginError state',
        build: () => LoginBloc(),
        act: (bloc) => bloc.add(LoginSubmitEvent('', '', true)),
        expect: () => [LoginLoading(), LoginError(error), LoginForm()],
        setUp: () {
          when(
                () =>
                GetIt.I<Dio>().post(
                  '/login',
                  data: any(named: 'data'),
                ),
          ).thenAnswer(
                (_) async {
              var options = RequestOptions(path: '/login');
              throw DioError(
                requestOptions: options,
                response: Response(
                  data: {'message': error},
                  requestOptions: options,
                ),
                type: DioErrorType.response,
              );
            },
          );
        },
        verify: (bloc) {
          verifyZeroInteractions(GetIt.I<SharedPreferences>());
          verify(() => GetIt.I<Dio>().post(any(), data: any(named: 'data')));
        },
      );
    }
  });
}
