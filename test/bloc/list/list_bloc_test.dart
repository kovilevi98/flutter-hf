import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_homework/main.dart';
import 'package:flutter_homework/network/user_item.dart';
import 'package:flutter_homework/ui/bloc/list/list_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDio extends Mock implements Dio {}

class MockSharedPreferences extends Mock implements SharedPreferences {}


final _testUsers = [
  for (int i = 0; i < 10; i++)
    UserItem('Test User $i', 'Test Image $i'),
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

  blocTest<ListBloc, ListState>(
    'Bloc starts in ListInitial state [0]',
    build: () => ListBloc(),
    expect: () => [],
    verify: (bloc) {
      expect(bloc.state, ListInitial());
    },
  );

  blocTest<ListBloc, ListState>(
      'ListLoadEvent does nothing in Loading state [1]',
      build: () => ListBloc(),
      act: (bloc) => bloc.add(ListLoadEvent()),
      seed: () => ListLoading(),
      expect: () => [],
      verify: (bloc) {
        verifyZeroInteractions(GetIt.I<SharedPreferences>());
        verifyZeroInteractions(GetIt.I<Dio>());
      });

  blocTest<ListBloc, ListState>(
    'User list is successfully loaded on ListLoadEvent [2]',
    build: () => ListBloc(),
    act: (bloc) => bloc.add(ListLoadEvent()),
    setUp: () {
      when(() => GetIt.I<Dio>().get('/users')).thenAnswer(
            (_) async =>
            Response(
              data: [
                for (var user in _testUsers)
                  {
                    'name' : user.name,
                    'avatarUrl' : user.avatarUrl,
                  }
              ],
              requestOptions: RequestOptions(path: '/users'),
            ),
      );
    },
    expect: () => [ListLoading(), ListLoaded(_testUsers)],
  );
  group('Errors are sent through ListError state [1]', () {
    var errors = ['TEST_ERROR_1', 'TEST_ERROR_2'];
    for (var error in errors) {
      blocTest<ListBloc, ListState>(
        'Error is sent through ListError state',
        build: () => ListBloc(),
        act: (bloc) => bloc.add(ListLoadEvent()),
        expect: () => [ListLoading(), ListError(error)],
        setUp: () {
          when(
                () =>
                GetIt.I<Dio>().get(
                  '/users',
                ),
          ).thenAnswer(
                (_) async {
              var options = RequestOptions(path: '/users');
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
          verify(() => GetIt.I<Dio>().get(any()));
        },
      );
    }
  });
}
