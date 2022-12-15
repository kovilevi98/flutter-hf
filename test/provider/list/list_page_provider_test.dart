import 'package:flutter/material.dart';
import 'package:flutter_homework/network/user_item.dart';
import 'package:flutter_homework/ui/provider/list/list_model.dart';
import 'package:flutter_homework/ui/provider/list/list_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mocktail_image_network/mocktail_image_network.dart';
import 'package:provider/provider.dart';

class MockListModel extends Mock implements ListModel {}

void main() {
  testWidgets('loadUsers is called on start [1]', (tester) async {
    var model = MockListModel();
    when(() => model.isLoading).thenReturn(false);
    when(() => model.users).thenReturn([]);
    when(() => model.loadUsers()).thenAnswer((_) async => null);
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<ListModel>.value(
          value: model,
          child: const ListPageProvider(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    verify(() => model.loadUsers());
  });

  testWidgets('ProgressIndicator shown in loading state [1]', (tester) async {
    var model = MockListModel();
    when(() => model.isLoading).thenReturn(true);
    when(() => model.users).thenReturn([]);
    when(() => model.loadUsers()).thenAnswer((_) async => null);
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<ListModel>.value(
          value: model,
          child: const ListPageProvider(),
        ),
      ),
    );
    await tester.pump(Duration(milliseconds: 100));
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
        var model = MockListModel();
        when(() => model.isLoading).thenReturn(true);
        when(() => model.users).thenReturn([]);
        when(() => model.loadUsers())
            .thenAnswer((_) async => throw ListException(errorMessage));
        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<ListModel>.value(
              value: model,
              child: const ListPageProvider(),
            ),
          ),
        );
        await tester.pump(Duration(milliseconds: 100));
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
    'List items are shown in loaded state [2]',
    (tester) async => mockNetworkImages(
      () async {
        var model = MockListModel();
        var users = [
          for (int i = 0; i < 10; i++)
            UserItem('Test User $i', 'Test Image $i'),
        ];
        when(() => model.isLoading).thenReturn(false);
        when(() => model.users).thenReturn(users);
        when(() => model.loadUsers()).thenAnswer((_) async => null);
        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<ListModel>.value(
              value: model,
              child: const ListPageProvider(),
            ),
          ),
        );
        await tester.pump(Duration(milliseconds: 100));
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
