// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:steppetrip/models/booking_model.dart';
import 'package:steppetrip/services/auth_service.dart';
import 'package:steppetrip/services/qr_scanner_service.dart';
import 'package:steppetrip/services/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Практикалық жұмыс №6: Толық тестілеу (17 Тапсырма)', () {
    late AuthService authService;
    late QrScannerService qrService;

    setUp(() async {
      final db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE users (
              id TEXT PRIMARY KEY,
              fullName TEXT NOT NULL,
              email TEXT NOT NULL,
              phone TEXT NOT NULL,
              avatarUrl TEXT NOT NULL,
              preferredLanguage TEXT NOT NULL,
              completedTours INTEGER NOT NULL DEFAULT 0
            )
          ''');
          await db.execute('''
            CREATE TABLE bookings (
              id TEXT PRIMARY KEY,
              tourId TEXT NOT NULL,
              tourName TEXT NOT NULL,
              date TEXT NOT NULL,
              peopleCount INTEGER NOT NULL,
              totalPrice INTEGER NOT NULL,
              status TEXT NOT NULL,
              clientName TEXT NOT NULL,
              clientPhone TEXT NOT NULL,
              notes TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE tours (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              region TEXT NOT NULL,
              category TEXT NOT NULL,
              rating REAL NOT NULL,
              reviewsCount INTEGER NOT NULL,
              pricePerPerson INTEGER NOT NULL,
              description TEXT NOT NULL,
              imageUrl TEXT NOT NULL,
              highlights TEXT NOT NULL,
              bestSeason TEXT NOT NULL,
              isFavorite INTEGER NOT NULL DEFAULT 0
            )
          ''');

          // Бастапқы демо брондау
          await db.insert('bookings', {
            'id': 'BK-2026-TEST',
            'tourId': 'tp_01',
            'tourName': 'Көлсай және Қайыңды көлдері',
            'date': '15.11.2026',
            'peopleCount': 2,
            'totalPrice': 45000,
            'status': BookingStatus.pending.name,
            'clientName': 'Әлішер Ербол',
            'clientPhone': '+7 (777) 123-45-67',
          });

          // Болдырмалған брондау
          await db.insert('bookings', {
            'id': 'BK-CANCELLED-99',
            'tourId': 'tp_02',
            'tourName': 'Шарын шатқалы',
            'date': '01.10.2026',
            'peopleCount': 1,
            'totalPrice': 15000,
            'status': BookingStatus.cancelled.name,
            'clientName': 'Тест Тұтынушы',
            'clientPhone': '+7 (701) 999-88-77',
          });
        },
      );

      DatabaseHelper.setMockDatabase(db);
      authService = AuthService.instance;
      qrService = QrScannerService.instance;
    });

    // ------------------------------------------------------------------------
    // 1 & 2. Registration & Validation
    // ------------------------------------------------------------------------
    test('1 & 2. Тіркелу формасындағы өрістерге валидация орнату', () {
      // Name validation
      expect(AuthService.validateName(null), isNotNull);
      expect(AuthService.validateName(''), isNotNull);
      expect(AuthService.validateName('А'), isNotNull);
      expect(AuthService.validateName('Дінмұхаммед'), isNull);

      // Email validation
      expect(AuthService.validateEmail(null), isNotNull);
      expect(AuthService.validateEmail('invalid_email'), isNotNull);
      expect(AuthService.validateEmail('user@domain'), isNotNull);
      expect(AuthService.validateEmail('dinmuhammed@steppetrip.kz'), isNull);

      // Phone validation
      expect(AuthService.validatePhone(null), isNotNull);
      expect(AuthService.validatePhone('123'), isNotNull);
      expect(AuthService.validatePhone('+7 (777) 123-45-67'), isNull);

      // Password validation (мин 6 таңба)
      expect(AuthService.validatePassword(null), isNotNull);
      expect(AuthService.validatePassword('12345'), isNotNull);
      expect(AuthService.validatePassword('123456'), isNull);
      expect(AuthService.validatePassword('SecurePass2026!'), isNull);
    });

    test('1 & 5. Жаңа пайдаланушыны тіркеу және сессия сақтау', () async {
      final success = await authService.register(
        fullName: 'Дінмұхаммед Сұлтан',
        email: 'dinmuhammed@steppetrip.kz',
        phone: '+7 (708) 555-44-33',
        password: 'Steppe2026!',
      );

      expect(success, isTrue);
      expect(authService.isAuthenticated, isTrue);
      expect(authService.currentUser?.fullName, 'Дінмұхаммед Сұлтан');
      expect(authService.currentSession?.token, startsWith('STP_SESSION_'));
      expect(authService.currentSession?.rememberMe, isTrue);
    });

    // ------------------------------------------------------------------------
    // 3 & 4. Login & Error Handling
    // ------------------------------------------------------------------------
    test('3. Дұрыс логин және құпиясөзбен кіру', () async {
      final success = await authService.login(
        email: 'dinmuhammed@steppetrip.kz',
        password: '123456',
        rememberMe: true,
      );

      expect(success, isTrue);
      expect(authService.status, AuthStatus.authenticated);
      expect(authService.currentUser, isNotNull);
      expect(authService.currentSession?.email, 'dinmuhammed@steppetrip.kz');
    });

    test('4. Қате логин немесе пароль енгізілгенде хабарлама көрсету', () async {
      // 1. Тіркелмеген email
      final wrongEmail = await authService.login(
        email: 'unknown_person@gmail.com',
        password: '123456',
      );
      expect(wrongEmail, isFalse);
      expect(authService.status, AuthStatus.error);
      expect(authService.errorMessage, contains('тіркелмеген'));

      // 2. Қате пароль
      final wrongPass = await authService.login(
        email: 'dinmuhammed@steppetrip.kz',
        password: 'WRONG_PASSWORD_999',
      );
      expect(wrongPass, isFalse);
      expect(authService.status, AuthStatus.error);
      expect(authService.errorMessage, contains('Құпиясөз қате'));
    });

    // ------------------------------------------------------------------------
    // 5 & 6. Session Persistence & Auto-Login
    // ------------------------------------------------------------------------
    test('5 & 6. Авторизациядан кейін пайдаланушы сессиясын сақтау және тексеру', () async {
      await authService.login(
        email: 'alisher.erbol@gmail.com',
        password: '123456',
        rememberMe: true,
      );

      expect(authService.currentSession, isNotNull);
      expect(authService.currentSession!.rememberMe, isTrue);

      // Қосымша қайта іске қосылғанда сессияны тексеру
      final hasSavedSession = await authService.checkSavedSession();
      expect(hasSavedSession, isTrue);
      expect(authService.isAuthenticated, isTrue);
    });

    // ------------------------------------------------------------------------
    // 7. Logout
    // ------------------------------------------------------------------------
    test('7. Logout функциясын іске асыру', () async {
      await authService.login(
        email: 'alisher.erbol@gmail.com',
        password: '123456',
      );
      expect(authService.isAuthenticated, isTrue);

      await authService.logout();

      expect(authService.isAuthenticated, isFalse);
      expect(authService.currentSession, isNull);
      expect(authService.currentUser, isNull);
      expect(authService.status, AuthStatus.unauthenticated);
    });

    // ------------------------------------------------------------------------
    // 8. Profile Integration
    // ------------------------------------------------------------------------
    test('8. Пайдаланушының Profile экранын деректермен байланыстыру', () async {
      await authService.login(
        email: 'alisher.erbol@gmail.com',
        password: '123456',
      );

      final user = authService.currentUser!;
      expect(user.email, 'alisher.erbol@gmail.com');

      // Профильді өзгерту
      final updatedUser = user.copyWith(
        fullName: 'Әлішер Ерболұлы (Жаңартылған)',
        phone: '+7 (701) 777-88-99',
      );
      await authService.updateUser(updatedUser);

      expect(authService.currentUser?.fullName, 'Әлішер Ерболұлы (Жаңартылған)');
      expect(authService.currentUser?.phone, '+7 (701) 777-88-99');
    });

    // ------------------------------------------------------------------------
    // 9 & 10. State Management (Provider / ChangeNotifier)
    // ------------------------------------------------------------------------
    test('9 & 10. State Management (ChangeNotifier) реактивті күйін тексеру', () async {
      int notifyCount = 0;
      authService.addListener(() {
        notifyCount++;
      });

      await authService.login(email: 'alisher.erbol@gmail.com', password: '123456');
      expect(notifyCount, greaterThan(0));

      await authService.logout();
      expect(notifyCount, greaterThan(1));
    });

    // ------------------------------------------------------------------------
    // 11, 12, 13. Complex Feature: Camera Permission Request
    // ------------------------------------------------------------------------
    test('11, 12, 13. Камера және QR-код сканері: Permission сұрау', () async {
      expect(qrService.cameraPermission, DevicePermissionStatus.notDetermined);

      final status = await qrService.requestCameraPermission(grant: true);

      expect(status, DevicePermissionStatus.granted);
      expect(qrService.hasPermission, isTrue);
    });

    // ------------------------------------------------------------------------
    // 14. QR Scanner Business Logic (Ticket Verification)
    // ------------------------------------------------------------------------
    test('14. QR-код арқылы тур билетін растау және мәртебесін өзгерту', () async {
      // 1. Бар билетті сканерлеу
      final result = await qrService.verifyQrData('STP:TICKET:BK-2026-TEST');

      expect(result.isValid, isTrue);
      expect(result.booking?.id, 'BK-2026-TEST');
      expect(result.booking?.status, BookingStatus.confirmed);
      expect(result.message, contains('Билет сәтті тексерілді'));

      // 2. Жарамсыз кодты сканерлеу
      final invalidResult = await qrService.verifyQrData('UNKNOWN_TICKET_123');
      expect(invalidResult.isValid, isFalse);
      expect(invalidResult.message, contains('табылмады'));

      // 3. Болдырмалған билетті сканерлеу
      final cancelledResult = await qrService.verifyQrData('BK-CANCELLED-99');
      expect(cancelledResult.isValid, isFalse);
      expect(cancelledResult.message, contains('БОЛДЫРМАЛҒАН'));
    });

    // ------------------------------------------------------------------------
    // 15. Permission Granted vs Denied
    // ------------------------------------------------------------------------
    test('15. Permission берілген және берілмеген жағдайларды жеке тексеру', () {
      // Рұқсат жоқ кезде
      qrService.setPermissionStatus(DevicePermissionStatus.denied);
      expect(qrService.hasPermission, isFalse);

      // Рұқсат берілгенде
      qrService.setPermissionStatus(DevicePermissionStatus.granted);
      expect(qrService.hasPermission, isTrue);
    });

    // ------------------------------------------------------------------------
    // 16. Auth Guard (Экрандарға қолжетімділік)
    // ------------------------------------------------------------------------
    test('16. Авторизацияланған және авторизацияланбаған қолданушылар үшін тексеру', () async {
      await authService.logout();
      expect(authService.isAuthenticated, isFalse);

      // Авторизацияланбаған кезде брондау тексеру шектеледі
      bool canBook = authService.isAuthenticated;
      expect(canBook, isFalse);

      await authService.login(email: 'alisher.erbol@gmail.com', password: '123456');
      canBook = authService.isAuthenticated;
      expect(canBook, isTrue);
    });

    // ------------------------------------------------------------------------
    // 17. Қосымшаны қайта іске қосу және интеграцияны тексеру
    // ------------------------------------------------------------------------
    test('17. Сессия мен құрылғы функциясын интеграциялық тексеру', () async {
      expect(authService.isAuthenticated, isTrue);
      expect(qrService.hasPermission, isTrue);

      final scanRes = await qrService.verifyQrData('BK-2026-TEST');
      expect(scanRes.isValid, isTrue);
    });
  });
}

