import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_homework/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Journey through the completed app [2]', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await loadAppFonts();
    await tester.binding.setSurfaceSize(const Size(400, 640));

    //Load application [1]
    app.main();
    await tester.pumpAndSettle();
    await expectLater(find.byType(app.MyApp), matchesGoldenFile('0-login-initial.png'));

    //Display error message in fields [1]
    await tester.enterText(find.byType(TextField).first, 'wrong email format');
    await tester.enterText(find.byType(TextField).last, 'pass');
    await tester.tap(find.bySubtype<ButtonStyleButton>());
    await tester.pumpAndSettle();
    await expectLater(find.byType(app.MyApp), matchesGoldenFile('1-login-error.png'));

    //Show loading state [1]
    await tester.enterText(find.byType(TextField).first, 'wrong.email@gmail.com');
    await tester.enterText(find.byType(TextField).last, 'password');
    await tester.tap(find.bySubtype<ButtonStyleButton>());
    await tester.pump(const Duration(milliseconds: 500));
    await expectLater(find.byType(app.MyApp), matchesGoldenFile('2-login-loading.png'));

    //Show error Snackbar when user is wrong [1]
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpAndSettle();
    await expectLater(find.byType(app.MyApp), matchesGoldenFile('3-login-wrong-user.png'));
    //Hide snackbar for later screenshots [1]
    await tester.pump(const Duration(milliseconds: 5000));
    await tester.pumpAndSettle();

    //Show list page after successful login [1]
    await tester.enterText(find.byType(TextField).first, 'login@gmail.com');
    await tester.enterText(find.byType(TextField).last, 'password');
    await tester.tap(find.byType(Checkbox)); //Check autologin later
    await tester.tap(find.bySubtype<ButtonStyleButton>());
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await expectLater(find.byType(app.MyApp), matchesGoldenFile('4-list-initial.png'));
    //Drag list page [1]
    await tester.drag(find.bySubtype<app.MyApp>(), const Offset(0, -400));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await expectLater(find.byType(app.MyApp), matchesGoldenFile('5-list-dragged.png'));

    //Restart app, try autologin [1]
    await GetIt.I.reset();
    runApp(Container(key: UniqueKey()));
    await tester.pump();
    app.main();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await expectLater(find.byType(app.MyApp), matchesGoldenFile('6-list-autologin.png'));
    //Logout throw back to login page [1]
    await tester.tap(find.bySubtype<IconButton>());
    await tester.pumpAndSettle();
    await expectLater(find.byType(app.MyApp), matchesGoldenFile('7-login-logout.png'));
  });
}
