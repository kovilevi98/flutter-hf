import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_homework/ui/bloc/login/login_bloc.dart';
import 'package:flutter_homework/ui/bloc/login/login_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockLoginBloc extends MockBloc<LoginEvent, LoginState>
    implements LoginBloc {}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

void main() {
  testWidgets('AutoLoginEvent is added to BLoC [1]', (tester) async {
    var bloc = MockLoginBloc();
    whenListen(bloc, const Stream<LoginState>.empty(),
        initialState: LoginForm());
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<LoginBloc>.value(
          value: bloc,
          child: const LoginPageBloc(),
        ),
      ),
    );
    verify(() => bloc.add(LoginAutoLoginEvent()));
  });

  group('LoginPage valid input sends correct event [2]', () {
    var emails = ['alpaca@gmail.com', 'llama@gmail.com', 'myemail@freemail.hu'];
    var passwords = ['password1', 'password2'];
    var rememberMeValues = [false, true];
    for (var email in emails) {
      for (var password in passwords) {
        for (var rememberMe in rememberMeValues) {
          testWidgets('LoginPage correct field test (email: $email, password: $password, rememberMe:$rememberMe)', (tester) async {
            var bloc = MockLoginBloc();
            whenListen(bloc, const Stream<LoginState>.empty(),
                initialState: LoginForm());
            await tester.pumpWidget(
              MaterialApp(
                home: BlocProvider<LoginBloc>.value(
                  value: bloc,
                  child: const LoginPageBloc(),
                ),
              ),
            );
            await tester.enterText(find.byType(TextField).first, email);
            await tester.enterText(find.byType(TextField).last, password);
            if (tester.firstWidget<Checkbox>(find.byType(Checkbox)).value != rememberMe){
              await tester.tap(find.byType(Checkbox));
            }
            await tester.tap(find.bySubtype<ButtonStyleButton>());
            await tester.pumpAndSettle();
            verify(() => bloc.add(LoginSubmitEvent(email, password, rememberMe),),);
          });
        }
      }
    }
  },);

  testWidgets('Fields are disabled in loading state [1]', (tester) async {
    var bloc = MockLoginBloc();
    whenListen(bloc, const Stream<LoginState>.empty(),
        initialState: LoginLoading());
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<LoginBloc>.value(
          value: bloc,
          child: const LoginPageBloc(),
        ),
      ),
    );
    expect(tester.widgetList<TextFormField>(find.byType(TextFormField)).every((element) => !element.enabled), true);
    expect(tester.widgetList<Checkbox>(find.byType(Checkbox)).every((element) => element.onChanged == null), true);
    expect(tester.widgetList<ButtonStyleButton>(find.byType(ButtonStyleButton)).every((element) => element.onPressed == null), true);
  });

  testWidgets('On success state, page is replaced [1]', (tester) async {
    var bloc = MockLoginBloc();
    var navigatorObserver = MockNavigatorObserver();
    var placeholderPage = const Scaffold();

    whenListen(bloc, Stream<LoginState>.value(LoginSuccess()),
        initialState: LoginLoading());
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<LoginBloc>.value(
          value: bloc,
          child: const LoginPageBloc(),
        ),
        routes: {
          '/list' : (_) => placeholderPage,
        },
        navigatorObservers: [navigatorObserver],
      ),
    );
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
      testWidgets('On error state, Snackbar is shown with error message', (tester) async {
        var bloc = MockLoginBloc();

        whenListen(bloc, Stream<LoginState>.value(LoginError(errorMessage)),
            initialState: LoginLoading());
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<LoginBloc>.value(
              value: bloc,
              child: const LoginPageBloc(),
            ),
          ),
        );
        await tester.pump();
        expect(find.byType(SnackBar), findsOneWidget);
        expect(tester.widget<Text>(find.descendant(of: find.byType(SnackBar), matching: find.byType(Text))).data, errorMessage);
      });
    }
  });
}
