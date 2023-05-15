import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_homework/network/user_item.dart';
import 'package:flutter_homework/ui/bloc/list/list_bloc.dart';
import 'package:flutter_homework/ui/bloc/list/list_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mocktail_image_network/mocktail_image_network.dart';

class MockListBloc extends Mock implements ListBloc {}

void main() {
  testWidgets('ListLoadEvent is added to ListBloc [1]', (tester) async {
    var bloc = MockListBloc();
    whenListen(bloc, const Stream<ListState>.empty(),
        initialState: ListInitial());
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<ListBloc>.value(
          value: bloc,
          child: const ListPageBloc(),
        ),
      ),
    );
    verify(() => bloc.add(ListLoadEvent()));
  });

  testWidgets('ProgressIndicator shown in loading state [1]', (tester) async {
    var bloc = MockListBloc();
    whenListen(bloc, const Stream<ListState>.empty(),
        initialState: ListLoading());
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<ListBloc>.value(
          value: bloc,
          child: const ListPageBloc(),
        ),
      ),
    );
    expect(find.bySubtype<ProgressIndicator>(), findsOneWidget);
  });

  group('On error state, Snackbar is shown with error message [2]', () {
    const errorMessages = [
      'TEST ERROR!',
      'General error!',
      'Network error!',
    ];
    for (var errorMessage in errorMessages) {
      testWidgets('On error state, Snackbar is shown with error message',
          (tester) async {
        var bloc = MockListBloc();

        whenListen(bloc, Stream<ListState>.value(ListError(errorMessage)),
            initialState: ListInitial());
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<ListBloc>.value(
              value: bloc,
              child: const ListPageBloc(),
            ),
          ),
        );
        await tester.pump();
        expect(find.byType(SnackBar), findsOneWidget);
        expect(
            tester
                .widget<Text>(find.descendant(
                    of: find.byType(SnackBar), matching: find.byType(Text)))
                .data,
            errorMessage);
      });
    }
  });

  testWidgets(
    'List items are shown in ListLoaded state [2]',
    (tester) async => mockNetworkImages(
      () async {
        var bloc = MockListBloc();
        var users = [
          for (int i = 0; i < 4; i++)
            UserItem('Test User $i', 'Test Image $i'),
        ];
        whenListen(bloc, const Stream<ListState>.empty(),
            initialState: ListLoaded(users));
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<ListBloc>.value(
              value: bloc,
              child: const ListPageBloc(),
            ),
          ),
        );
        expect(find.bySubtype<Scrollable>(), findsOneWidget);
        var images = find
            .descendant(
              of: find.bySubtype<Scrollable>(),
              matching: find.byType(Image),
            )
            .evaluate()
            .map((e) => ((e.widget as Image).image as NetworkImage).url);
        expect(images, users.map((e) => e.avatarUrl));
        var names = find
            .descendant(
              of: find.bySubtype<Scrollable>(),
              matching: find.byType(Text),
            )
            .evaluate()
            .map((e) => (e.widget as Text).data);
        expect(names, users.map((e) => e.name));
      },
    ),
  );
}
