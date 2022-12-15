import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_homework/main.dart';
import 'package:flutter_homework/network/user_item.dart';
import 'package:flutter_homework/ui/provider/list/list_model.dart';
import 'package:flutter_homework/ui/provider/login/login_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDio extends Mock implements Dio {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

class FixLoadingListModel extends ListModel {
  @override
  // ignore: overridden_fields
  var isLoading = true;
}

final _testUsers = [
  for (int i = 0; i < 10; i++) UserItem('Test User $i', 'Test Image $i'),
];

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

  test('loadUsers does nothing in while loading [1]', () {
    var model = FixLoadingListModel();
    model.loadUsers();
    verifyZeroInteractions(GetIt.I<SharedPreferences>());
    verifyZeroInteractions(GetIt.I<Dio>());
  });

  test('User list is successfully loaded on ListLoadEvent [2]', () async {
    var model = ListModel();
    var completer = Completer<Response>();
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
    var loadRequest = model.loadUsers();
    expect(model.isLoading, true);
    completer.complete(
      Response(
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
    await loadRequest;
    expect(model.isLoading, false);
    expect(model.users, _testUsers);
  });

  group('Errors are sent through ListError state [1]', () {
    var errors = ['TEST_ERROR_1', 'TEST_ERROR_2'];
    for (var error in errors) {
      test('User list is successfully loaded on ListLoadEvent', () async {
        var model = ListModel();
        var completer = Completer<Response>();
        when(
          () => GetIt.I<Dio>().get(
            '/users',
          ),
        ).thenAnswer(
          (_) => completer.future,
        );
        var options = RequestOptions(path: '/users');
        var loadRequest = model.loadUsers();
        expect(model.isLoading, true);
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
        await expectLater(loadRequest, throwsA(ListException(error)));
        expect(model.isLoading, false);
        verifyZeroInteractions(GetIt.I<SharedPreferences>());
        verify(() => GetIt.I<Dio>().get(any()));
      });
    }
  });
}
