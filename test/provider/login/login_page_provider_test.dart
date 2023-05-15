
import 'package:flutter/material.dart';
import 'package:flutter_homework/ui/provider/login/login_model.dart';
import 'package:flutter_homework/ui/provider/login/login_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class MockLoginModel extends Mock implements LoginModel {}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

void main() {
  testWidgets('tryAutoLogin is called on page load [1]', (tester) async {
    var model = MockLoginModel();
    when(() => model.tryAutoLogin()).thenAnswer((_) => Future.value(false));
    when(() => model.isLoading).thenReturn(false);
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<LoginModel>.value(
          value: model,
          child: const LoginPageProvider(),
        ),
      ),
    );
    verify(() => model.tryAutoLogin());
  });

  group('LoginPage valid input calls correct function [2]', () {
    var emails = ['alpaca@gmail.com', 'llama@gmail.com', 'myemail@freemail.hu'];
    var passwords = ['password1', 'password2'];
    var rememberMeValues = [false, true];
    for (var email in emails) {
      for (var password in passwords) {
        for (var rememberMe in rememberMeValues) {
          testWidgets('LoginPage correct field test (email: $email, password: $password, rememberMe:$rememberMe)', (tester) async {
            var model = MockLoginModel();
            when(() => model.login(any(), any(), any())).thenAnswer((_) async => null);
            when(() => model.isLoading).thenReturn(false);
            when(() => model.tryAutoLogin()).thenAnswer((_) => Future.value(false));
            await tester.pumpWidget(
              MaterialApp(
                home: ChangeNotifierProvider<LoginModel>.value(
                  value: model,
                  child: const LoginPageProvider(),
                ),
                routes: {'/list' : (_) => Container()}
              ),
            );
            await tester.enterText(find.byType(TextField).first, email);
            await tester.enterText(find.byType(TextField).last, password);
            if (tester.firstWidget<Checkbox>(find.byType(Checkbox)).value != rememberMe){
              await tester.tap(find.byType(Checkbox));
            }
            await tester.tap(find.bySubtype<ButtonStyleButton>());
            await tester.pumpAndSettle();
            verify(() => model.login(email, password, rememberMe));
          });
        }
      }
    }
  },);

  testWidgets('Fields are disabled in loading state [1]', (tester) async {
    var model = MockLoginModel();
    when(() => model.tryAutoLogin()).thenAnswer((_) => Future.value(false));
    when(() => model.isLoading).thenReturn(true);
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<LoginModel>.value(
          value: model,
          child: const LoginPageProvider(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.widgetList<TextFormField>(find.byType(TextFormField)).every((element) => !element.enabled), true);
    expect(tester.widgetList<Checkbox>(find.byType(Checkbox)).every((element) => element.onChanged == null), true);
    expect(tester.widgetList<ButtonStyleButton>(find.byType(ButtonStyleButton)).every((element) => element.onPressed == null), true);
  });

  testWidgets('On success, page is replaced [1]', (tester) async {
    var model = MockLoginModel();
    var navigatorObserver = MockNavigatorObserver();
    var placeholderPage = const Scaffold();
    var email = 'a@a.com';
    var password = 'password';

    when(() => model.tryAutoLogin()).thenAnswer((_) => Future.value(false));
    when(() => model.isLoading).thenReturn(false);
    when(() => model.login(any(), any(), any())).thenAnswer((_) async => null);
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<LoginModel>.value(
          value: model,
          child: const LoginPageProvider(),
        ),
        routes: {
          '/list' : (_) => placeholderPage,
        },
        navigatorObservers: [navigatorObserver],
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, email);
    await tester.enterText(find.byType(TextField).last, password);
    await tester.tap(find.bySubtype<ButtonStyleButton>());
    await tester.pumpAndSettle();
    verify(() => navigatorObserver.didReplace(oldRoute: any(named: 'oldRoute'), newRoute: any(named: 'newRoute')));
    expect(find.byWidget(placeholderPage), findsOneWidget);
  });

  group('On error state, Snackbar is shown with error message [2]', () {
    const errorMessages = [
      'TEST ERROR!',
      'General error!',
      'Network error!',
    ];
    for (var errorMessage in errorMessages){
      testWidgets('On error, Snackbar is shown with error message', (tester) async {
        var model = MockLoginModel();
        var email = 'a@a.com';
        var password = 'password';
        when(() => model.tryAutoLogin()).thenAnswer((_) => Future.value(false));
        when(() => model.isLoading).thenReturn(false);
        when(() => model.login(any(), any(), any())).thenAnswer((_) async => throw LoginException(errorMessage));
        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<LoginModel>.value(
              value: model,
              child: const LoginPageProvider(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).first, email);
        await tester.enterText(find.byType(TextField).last, password);
        await tester.tap(find.bySubtype<ButtonStyleButton>());
        await tester.pumpAndSettle();
        expect(find.byType(SnackBar), findsOneWidget);
        expect(tester.widget<Text>(find.descendant(of: find.byType(SnackBar), matching: find.byType(Text))).data, errorMessage);
      });
    }
  });
}