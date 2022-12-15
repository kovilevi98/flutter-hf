import 'dart:io';
import 'dart:typed_data';

import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_homework/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mocktail_image_network/mocktail_image_network.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockHttpClientAdapter extends Mock implements HttpClientAdapter {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockInterceptor extends Mock implements Interceptor {}

void main() {
  setUp(() async {
    var dio = Dio();
    var httpClientAdapter = MockHttpClientAdapter();
    dio.httpClientAdapter = httpClientAdapter;
    GetIt.I.registerSingleton(httpClientAdapter);
    GetIt.I.registerSingleton<Dio>(dio);
    GetIt.I.registerSingleton<SharedPreferences>(MockSharedPreferences());
    GetIt.I.registerSingleton(<NavigatorObserver>[]);
    configureCustomDependencies();
  });
  tearDown(() async {
    await GetIt.I.reset();
  });

  const _correctEmail = 'a@a.com';
  const _correctPassword = '12345678';
  group('Token is registered correctly for network requests [5]', () {
    var tokens = ['TEST_TOKEN_1', 'TEST_TOKEN_2'];
    for (var token in tokens) {
      mockNetworkImages(
        () => testWidgets(
          'Login registers token correctly',
          (tester) async {
            registerFallbackValue(RequestOptions(path: ''));

            when(() => GetIt.I<SharedPreferences>().containsKey(any()))
                .thenReturn(false);
            when(
              () => GetIt.I<MockHttpClientAdapter>().fetch(
                any(
                  that: predicate<RequestOptions>(
                      (options) => options.path == '/login'),
                ),
                any(),
                any(),
              ),
            ).thenAnswer(
              (_) => Future.value(
                ResponseBody(
                    Stream.value(
                      Uint8List.fromList('{"token" : "$token"}'.codeUnits),
                    ),
                    200,
                    headers: {
                      Headers.contentTypeHeader: [Headers.jsonContentType],
                    }),
              ),
            );
            when(
              () => GetIt.I<MockHttpClientAdapter>().fetch(
                any(
                  that: predicate<RequestOptions>(
                      (options) => options.path == '/users'),
                ),
                any(),
                any(),
              ),
            ).thenAnswer(
              (_) => Future.value(
                ResponseBody(
                  Stream.value(
                    Uint8List.fromList('[]'.codeUnits),
                  ),
                  200,
                  headers: {
                    Headers.contentTypeHeader: [Headers.jsonContentType],
                  },
                ),
              ),
            );
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
            await tester.tap(find.bySubtype<ButtonStyleButton>());
            await tester.pumpAndSettle();
            var captured = verify(() => GetIt.I<MockHttpClientAdapter>()
                .fetch(captureAny(), any(), any())).captured;
            expect(
              captured,
              predicate(
                (list) {
                  return (list as Iterable)
                      .map((e) => e.headers['Authorization'])
                      .whereType<String>()
                      .any((element) => element == 'Bearer $token');
                },
              ),
            );
          },
        ),
      );
      mockNetworkImages(
        () => testWidgets(
          'AutoLogin registers token correctly',
          (tester) async {
            registerFallbackValue(RequestOptions(path: ''));

            when(() => GetIt.I<SharedPreferences>().containsKey(any()))
                .thenReturn(true);
            when(() => GetIt.I<SharedPreferences>().getString(any()))
                .thenReturn(token);
            when(
              () => GetIt.I<MockHttpClientAdapter>().fetch(
                any(),
                any(),
                any(),
              ),
            ).thenAnswer(
              (_) => Future.value(
                ResponseBody(
                  Stream.value(
                    Uint8List.fromList('[]'.codeUnits),
                  ),
                  200,
                  headers: {
                    Headers.contentTypeHeader: [Headers.jsonContentType],
                  },
                ),
              ),
            );
            await tester.pumpWidget(const MyApp());
            await tester.pumpAndSettle();
            var captured = verify(() => GetIt.I<MockHttpClientAdapter>()
                .fetch(captureAny(), any(), any())).captured;
            expect(
              captured,
              predicate(
                (list) {
                  return (list as Iterable)
                      .map((e) => e.headers['Authorization'])
                      .whereType<String>()
                      .any((element) => element == 'Bearer $token');
                },
              ),
            );
          },
        ),
      );
    }
  });
}
