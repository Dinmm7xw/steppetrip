import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:steppetrip/main.dart';
import 'package:steppetrip/screens/onboarding_screen.dart';
import 'package:steppetrip/services/database_helper.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    DatabaseHelper.setMockDatabase(db);
  });

  testWidgets('Сценарий 1: Қосымшаны іске қосу және Splash экранды тексеру', (WidgetTester tester) async {
    await tester.pumpWidget(const SteppeTripApp());

    // SteppeTrip атауының экранда барын тексеру
    expect(find.text('SteppeTrip'), findsOneWidget);
    expect(find.text('Ұлы даланың інжу-маржандарын бірге ашайық'), findsOneWidget);

    // Splash таймерін өңдеу
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('Сценарий 2: Onboarding экранындағы негізгі батырманы басу', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

    // Батырманы табу
    final guestButton = find.text('Қонақ ретінде саяхаттау');
    expect(guestButton, findsOneWidget);

    // Батырманы басу
    await tester.tap(guestButton);
    await tester.pumpAndSettle();
  });
}
