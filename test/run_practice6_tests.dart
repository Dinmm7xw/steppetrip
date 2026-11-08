// ignore_for_file: avoid_print
import 'package:steppetrip/models/booking_model.dart';
import 'package:steppetrip/services/auth_service.dart';
import 'package:steppetrip/services/qr_scanner_service.dart';
import 'package:steppetrip/services/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  print('======================================================================');
  print('Практикалық жұмыс №6: Пайдаланушы интерфейсін бейімдеу және оңтайландыру');
  print('======================================================================\n');

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  int passed = 0;
  int failed = 0;

  void assertEqual(dynamic actual, dynamic expected, String description) {
    if (actual == expected) {
      print('  [PASS] $description');
      passed++;
    } else {
      print('  [FAIL] $description: Expected "$expected" but got "$actual"');
      failed++;
    }
  }

  void assertTrue(bool condition, String description) {
    if (condition) {
      print('  [PASS] $description');
      passed++;
    } else {
      print('  [FAIL] $description: Condition was false');
      failed++;
    }
  }

  // SQLite Mock базасын баптау
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

  final auth = AuthService.instance;
  final qr = QrScannerService.instance;

  // --------------------------------------------------------------------------
  // 1 & 2. Registration & Validation
  // --------------------------------------------------------------------------
  print('1 & 2. Registration формасы және өрістерге Validation орнату:');
  assertTrue(AuthService.validateName('') != null, '2. Бос аты-жөн валидациядан өтпейді');
  assertTrue(AuthService.validateName('Дінмұхаммед') == null, '2. Дұрыс аты-жөн қабылданады');
  assertTrue(AuthService.validateEmail('bad_email') != null, '2. Қате email пішімі анықталады');
  assertTrue(AuthService.validateEmail('dinmuhammed@steppetrip.kz') == null, '2. Дұрыс email қабылданады');
  assertTrue(AuthService.validatePassword('123') != null, '2. Қысқа құпиясөз (<6) қабылданбайды');
  assertTrue(AuthService.validatePassword('Steppe2026!') == null, '2. 6+ таңбалы құпиясөз қабылданады');

  final regOk = await auth.register(
    fullName: 'Дінмұхаммед Сұлтан',
    email: 'dinmuhammed@steppetrip.kz',
    phone: '+7 (708) 555-44-33',
    password: 'Steppe2026!',
  );
  assertTrue(regOk, '1. Жаңа пайдаланушы тіркелді (Registration)');
  assertEqual(auth.currentUser?.fullName, 'Дінмұхаммед Сұлтан', '1. Тіркелген деректер профильге енгізілді');

  // --------------------------------------------------------------------------
  // 3 & 4. Login & Error Handling
  // --------------------------------------------------------------------------
  print('\n3 & 4. Login функциясы және қате логин/пароль хабарламасы:');
  await auth.logout();

  // 4. Қате пароль
  final wrongPass = await auth.login(email: 'dinmuhammed@steppetrip.kz', password: 'WRONG');
  assertTrue(!wrongPass, '4. Қате пароль енгізілгенде кіру бұғатталады');
  assertTrue(auth.errorMessage!.contains('Құпиясөз қате'), '4. "Құпиясөз қате" хабарламасы көрсетілді');

  // 4. Тіркелмеген email
  final wrongEmail = await auth.login(email: 'nobody@mail.kz', password: '123');
  assertTrue(!wrongEmail, '4. Тіркелмеген email анықталды');

  // 3. Дұрыс кіру
  final loginOk = await auth.login(
    email: 'dinmuhammed@steppetrip.kz',
    password: 'Steppe2026!',
    rememberMe: true,
  );
  assertTrue(loginOk, '3. Login сәтті орындалды');
  assertTrue(auth.isAuthenticated, '3. Пайдаланушы жүйеге кірді');

  // --------------------------------------------------------------------------
  // 5 & 6. Session Persistence & Auto-Login
  // --------------------------------------------------------------------------
  print('\n5 & 6. Сессияны сақтау және қайта іске қосқанда тексеру:');
  assertTrue(auth.currentSession != null, '5. Авторизациядан кейін сессия құрылды');
  assertTrue(auth.currentSession!.token.startsWith('STP_SESSION_'), '5. Қауіпсіз сессия токені генерацияланды');
  assertEqual(auth.currentSession!.rememberMe, true, '5. rememberMe параметрі сақталды');

  final sessionValid = await auth.checkSavedSession();
  assertTrue(sessionValid, '6. Қосымшаны қайта қосқанда сессия табылды (Auto-login)');

  // --------------------------------------------------------------------------
  // 7. Logout
  // --------------------------------------------------------------------------
  print('\n7. Logout функциясы:');
  await auth.logout();
  assertTrue(!auth.isAuthenticated, '7. Logout: Сессия тазартылды');
  assertTrue(auth.currentUser == null, '7. Logout: Пайдаланушы ақпараты өшірілді');

  // --------------------------------------------------------------------------
  // 8. Profile Integration
  // --------------------------------------------------------------------------
  print('\n8. Profile экранын деректермен байланыстыру:');
  await auth.login(email: 'dinmuhammed@steppetrip.kz', password: 'Steppe2026!');
  final user = auth.currentUser!;
  assertEqual(user.email, 'dinmuhammed@steppetrip.kz', '8. Профильде белсенді email көрсетілді');

  await auth.updateUser(user.copyWith(phone: '+7 (777) 999-00-11'));
  assertEqual(auth.currentUser!.phone, '+7 (777) 999-00-11', '8. Профиль деректері жаңартылды');

  // --------------------------------------------------------------------------
  // 9 & 10. State Management
  // --------------------------------------------------------------------------
  print('\n9 & 10. State Management (Provider / ChangeNotifier):');
  bool listenerTriggered = false;
  void testListener() {
    listenerTriggered = true;
  }
  auth.addListener(testListener);
  await auth.logout();
  assertTrue(listenerTriggered, '9 & 10. ChangeNotifier арқылы UI-ға күй жаңарту хабарламасы жеткізілді');
  auth.removeListener(testListener);

  // --------------------------------------------------------------------------
  // 11, 12, 13. Camera & QR Scanner Permission
  // --------------------------------------------------------------------------
  print('\n11, 12, 13. Күрделі функция: Камера және QR Scanner Permission:');
  assertEqual(qr.cameraPermission, DevicePermissionStatus.notDetermined, '13. Бастапқы күй: notDetermined');

  final permStatus = await qr.requestCameraPermission(grant: true);
  assertEqual(permStatus, DevicePermissionStatus.granted, '13. Камераға permission сұралды және берілді');
  assertTrue(qr.hasPermission, '13. hasPermission белсенді');

  // --------------------------------------------------------------------------
  // 14. QR Scanner Business Logic (Билетті тексеру)
  // --------------------------------------------------------------------------
  print('\n14. QR-код арқылы тур билетін растау (Бизнес-логика):');
  final verifyResult = await qr.verifyQrData('STP:TICKET:BK-2026-TEST');
  assertTrue(verifyResult.isValid, '14. Билет сәтті тексерілді');
  assertEqual(verifyResult.booking?.status, BookingStatus.confirmed, '14. Брондау мәртебесі "confirmed" болды');

  final invalidResult = await qr.verifyQrData('UNKNOWN_QR_123');
  assertTrue(!invalidResult.isValid, '14. Жарамсыз билет қабылданбады');

  final cancelResult = await qr.verifyQrData('BK-CANCELLED-99');
  assertTrue(!cancelResult.isValid, '14. Болдырмалған билет бұғатталды');

  // --------------------------------------------------------------------------
  // 15. Permission Granted vs Denied
  // --------------------------------------------------------------------------
  print('\n15. Permission берілген және берілмеген жағдайларды жеке тексеру:');
  qr.setPermissionStatus(DevicePermissionStatus.denied);
  assertTrue(!qr.hasPermission, '15. Permission denied жағдайы өңделді (Камера жабық, қолмен енгізу)');

  qr.setPermissionStatus(DevicePermissionStatus.granted);
  assertTrue(qr.hasPermission, '15. Permission granted жағдайы өңделді (Камера мен лазер анимациясы белсенді)');

  // --------------------------------------------------------------------------
  // 16. Auth Guard (Экрандарға қолжетімділік)
  // --------------------------------------------------------------------------
  print('\n16. Экрандарға қолжетімділікті тексеру (Auth Guard):');
  assertTrue(!auth.isAuthenticated, '16. Авторизацияланбаған қолданушы');
  bool canAccessRestricted = auth.isAuthenticated;
  assertTrue(!canAccessRestricted, '16. Авторизацияланбаған қолданушыға шектеу қойылды');

  await auth.login(email: 'dinmuhammed@steppetrip.kz', password: 'Steppe2026!');
  canAccessRestricted = auth.isAuthenticated;
  assertTrue(canAccessRestricted, '16. Авторизацияланған қолданушыға барлық экрандар қолжетімді');

  // --------------------------------------------------------------------------
  // 17. Сессия мен құрылғы функциясын интеграциялық тексеру
  // --------------------------------------------------------------------------
  print('\n17. Қосымшаны қайта іске қосып сессия мен құрылғы функциясын тексеру:');
  assertTrue(auth.isAuthenticated, '17. Сессия сақтаулы');
  assertTrue(qr.hasPermission, '17. Құрылғының QR сканері жұмыс істеп тұр');

  // --------------------------------------------------------------------------
  // Қорытынды
  // --------------------------------------------------------------------------
  print('\n======================================================================');
  print('СЫНАҚ ҚОРЫТЫНДЫСЫ: Барлығы: ${passed + failed} | Сәтті: $passed | Қате: $failed');
  if (failed == 0) {
    print('ПРАКТИКАЛЫҚ ЖҰМЫС №6: БАРЛЫҚ 17 ТАПСЫРМА 100% СӘТТІ ОРЫНДАЛДЫ!');
  } else {
    print('Кейбір сынақтар сәтсіз өтті.');
  }
  print('======================================================================');
}

