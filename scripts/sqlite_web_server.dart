// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:steppetrip/models/booking_model.dart';
import 'package:steppetrip/models/review_model.dart';
import 'package:steppetrip/services/mock_data_service.dart';

late final String dbPath;
late final String jsonMirrorPath;
late final String webBuildDir;

// Live in-memory + JSON + SQLite synchronized state
final Map<String, Map<String, dynamic>> liveUsers = {};
final Map<String, String> livePasswords = {
  'dinmuhammed@steppetrip.kz': '123456',
  'dinmuhammed@admin.kz': '123456',
};
final Map<String, Map<String, dynamic>> liveTours = {};
final Map<String, Map<String, dynamic>> liveBookings = {};
final List<Map<String, dynamic>> liveReviews = [];

bool sqliteNeedsSync = false;

void initDefaultMemoryState() {
  final admin = MockDataService.currentUser.toMap();
  liveUsers[admin['email'].toString().toLowerCase()] = admin;

  for (var t in MockDataService.tourPlaces) {
    liveTours[t.id] = t.toMap();
  }
  for (var b in MockDataService.mockBookings) {
    liveBookings[b.id] = b.toMap();
  }
  liveBookings['BK-2026-TEST'] = {
    'id': 'BK-2026-TEST',
    'tourId': 'tp_01',
    'tourName': 'Көлсай және Қайыңды көлдері',
    'date': '15.11.2026',
    'peopleCount': 2,
    'totalPrice': 45000,
    'status': BookingStatus.confirmed.name,
    'clientName': 'Дінмұхаммед Бақытұлы',
    'clientPhone': '+7 (708) 555-44-33',
    'notes': 'Тур билеті сәтті расталған',
  };
  liveReviews.add(const ReviewModel(
    id: 'rev_01',
    tourId: 'tp_01',
    userName: 'Айгүл Серікқызы',
    rating: 5,
    comment: 'Көлсай мен Қайыңды көлдері керемет әсер қалдырды!',
    date: '15 Қазан 2026',
    tags: ['Таза ауа', 'Керемет гид', 'Әдемі көрініс'],
    userAvatar: '',
  ).toMap());
}

void loadJsonMirror() {
  try {
    final file = File(jsonMirrorPath);
    if (!file.existsSync()) return;
    final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    if (data['users'] is List) {
      for (var u in (data['users'] as List)) {
        final m = Map<String, dynamic>.from(u as Map);
        liveUsers[m['email'].toString().toLowerCase()] = m;
      }
    }
    if (data['passwords'] is Map) {
      (data['passwords'] as Map).forEach((k, v) {
        livePasswords[k.toString().toLowerCase()] = v.toString();
      });
    }
    if (data['tours'] is List) {
      liveTours.clear();
      for (var t in (data['tours'] as List)) {
        final m = Map<String, dynamic>.from(t as Map);
        liveTours[m['id'].toString()] = m;
      }
    }
    if (data['bookings'] is List) {
      liveBookings.clear();
      for (var b in (data['bookings'] as List)) {
        final m = Map<String, dynamic>.from(b as Map);
        liveBookings[m['id'].toString()] = m;
      }
    }
  } catch (_) {}
}

void saveJsonMirror() {
  try {
    final file = File(jsonMirrorPath);
    file.writeAsStringSync(jsonEncode({
      'users': liveUsers.values.toList(),
      'passwords': livePasswords,
      'tours': liveTours.values.toList(),
      'bookings': liveBookings.values.toList(),
      'reviews': liveReviews,
    }));
  } catch (_) {}
}

Future<void> syncToSqliteFile() async {
  Database? db;
  try {
    db = await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    await db.execute('PRAGMA busy_timeout = 1500');

    // Read existing users from SQLite first so we don't lose anything added in DB Browser
    try {
      final existingUsers = await db.query('users');
      for (var row in existingUsers) {
        final email = (row['email'] ?? '').toString().toLowerCase();
        if (email.isNotEmpty && !liveUsers.containsKey(email)) {
          // Skip deleted demo users if they were old
          if (!email.contains('alisher') && !email.contains('aruzhan') && !email.contains('bauyrzhan')) {
            liveUsers[email] = {
              'id': row['id'] ?? 'usr_db',
              'fullName': row['fullName'] ?? 'Пайдаланушы',
              'email': email,
              'phone': row['phone'] ?? '',
              'avatarUrl': row['avatarUrl'] ?? '',
              'preferredLanguage': row['preferredLanguage'] ?? 'Қазақша',
              'completedTours': row['completedTours'] ?? 0,
              'role': row['role'] ?? 'tourist',
              'isApproved': row['isApproved'] ?? 1,
            };
          }
        }
      }
    } catch (_) {}

    // Try writing current state into SQLite tables
    try {
      await db.execute("ALTER TABLE users ADD COLUMN role TEXT NOT NULL DEFAULT 'tourist'");
    } catch (_) {}
    try {
      await db.execute("ALTER TABLE users ADD COLUMN isApproved INTEGER NOT NULL DEFAULT 1");
    } catch (_) {}

    for (var u in liveUsers.values) {
      await db.insert('users', u, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    for (var t in liveTours.values) {
      await db.insert('tours', t, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    for (var b in liveBookings.values) {
      await db.insert('bookings', b, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    if (sqliteNeedsSync) {
      print('[SQLite] steppetrip.db файлына барлық өзгерістер сәтті жазылды!');
      sqliteNeedsSync = false;
    }
  } catch (e) {
    sqliteNeedsSync = true;
    print('[SQLite Ескерту] steppetrip.db қазір DB Browser бағдарламасында құлыптаулы (locked). DB Browser-де "Write Changes / Записать изменения" бассаңыз, бірден жазылады.');
  } finally {
    try {
      await db?.close();
    } catch (_) {}
  }
}

void addCorsHeaders(HttpResponse res) {
  res.headers.set('Access-Control-Allow-Origin', '*');
  res.headers.set('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
  res.headers.set('Access-Control-Allow-Headers', 'Origin, Content-Type, Accept, Authorization');
  res.headers.set('Cache-Control', 'no-store, no-cache, must-revalidate');
}

Future<void> handleApiRequest(HttpRequest req) async {
  final res = req.response;
  addCorsHeaders(res);

  if (req.method == 'OPTIONS') {
    res.statusCode = HttpStatus.ok;
    await res.close();
    return;
  }

  final path = req.uri.path;

  try {
    if (path == '/api/state' && req.method == 'GET') {
      res.headers.contentType = ContentType.json;
      res.write(jsonEncode({
        'users': liveUsers.values.toList(),
        'passwords': livePasswords,
        'tours': liveTours.values.toList(),
        'bookings': liveBookings.values.toList(),
        'reviews': liveReviews,
      }));
      await res.close();
      return;
    }

    final bodyStr = await utf8.decoder.bind(req).join();
    final Map<String, dynamic> body =
        bodyStr.isNotEmpty ? Map<String, dynamic>.from(jsonDecode(bodyStr) as Map) : {};

    if (path == '/api/users') {
      if (req.method == 'POST' || req.method == 'PUT') {
        final userMap = Map<String, dynamic>.from(body['user'] as Map? ?? body);
        final password = body['password'] as String?;
        final email = (userMap['email'] as String).toLowerCase();

        if (liveUsers.containsKey(email)) {
          userMap['id'] = liveUsers[email]!['id'];
        }
        liveUsers[email] = userMap;
        if (password != null && password.isNotEmpty) {
          livePasswords[email] = password;
        }
        saveJsonMirror();
        sqliteNeedsSync = true;
        unawaited(syncToSqliteFile());

        print('[База] Пайдаланушы сақталды: ${userMap['fullName']} ($email, role=${userMap['role']}, approved=${userMap['isApproved']})');
        res.headers.contentType = ContentType.json;
        res.write(jsonEncode({'ok': true, 'user': userMap}));
        await res.close();
        return;
      } else if (req.method == 'DELETE') {
        final email = (req.uri.queryParameters['email'] ?? body['email'] ?? '').toString().toLowerCase();
        liveUsers.remove(email);
        livePasswords.remove(email);
        saveJsonMirror();
        sqliteNeedsSync = true;
        unawaited(syncToSqliteFile());

        res.headers.contentType = ContentType.json;
        res.write(jsonEncode({'ok': true}));
        await res.close();
        return;
      }
    }

    if (path == '/api/tours') {
      if (req.method == 'POST' || req.method == 'PUT') {
        final id = body['id'].toString();
        liveTours[id] = body;
        saveJsonMirror();
        sqliteNeedsSync = true;
        unawaited(syncToSqliteFile());

        res.headers.contentType = ContentType.json;
        res.write(jsonEncode({'ok': true}));
        await res.close();
        return;
      } else if (req.method == 'DELETE') {
        final id = (req.uri.queryParameters['id'] ?? body['id'] ?? '').toString();
        liveTours.remove(id);
        saveJsonMirror();
        sqliteNeedsSync = true;
        unawaited(syncToSqliteFile());

        res.headers.contentType = ContentType.json;
        res.write(jsonEncode({'ok': true}));
        await res.close();
        return;
      }
    }

    if (path == '/api/bookings') {
      if (req.method == 'POST' || req.method == 'PUT') {
        final id = body['id'].toString();
        liveBookings[id] = body;
        saveJsonMirror();
        sqliteNeedsSync = true;
        unawaited(syncToSqliteFile());

        res.headers.contentType = ContentType.json;
        res.write(jsonEncode({'ok': true}));
        await res.close();
        return;
      } else if (req.method == 'DELETE') {
        final id = (req.uri.queryParameters['id'] ?? body['id'] ?? '').toString();
        liveBookings.remove(id);
        saveJsonMirror();
        sqliteNeedsSync = true;
        unawaited(syncToSqliteFile());

        res.headers.contentType = ContentType.json;
        res.write(jsonEncode({'ok': true}));
        await res.close();
        return;
      }
    }

    res.statusCode = HttpStatus.notFound;
    res.write(jsonEncode({'error': 'Not found'}));
    await res.close();
  } catch (e, st) {
    print('[Server Error] $e\n$st');
    res.statusCode = HttpStatus.internalServerError;
    res.write(jsonEncode({'error': e.toString()}));
    await res.close();
  }
}

ContentType getMimeType(String path) {
  if (path.endsWith('.html')) return ContentType.html;
  if (path.endsWith('.js')) return ContentType('application', 'javascript', charset: 'utf-8');
  if (path.endsWith('.css')) return ContentType('text', 'css', charset: 'utf-8');
  if (path.endsWith('.json')) return ContentType.json;
  if (path.endsWith('.png')) return ContentType('image', 'png');
  if (path.endsWith('.jpg') || path.endsWith('.jpeg')) return ContentType('image', 'jpeg');
  if (path.endsWith('.svg')) return ContentType('image', 'svg+xml');
  if (path.endsWith('.woff2')) return ContentType('font', 'woff2');
  if (path.endsWith('.ttf') || path.endsWith('.otf')) return ContentType('font', 'ttf');
  if (path.endsWith('.wasm')) return ContentType('application', 'wasm');
  return ContentType.binary;
}

Future<void> handleStaticRequest(HttpRequest req) async {
  final res = req.response;
  addCorsHeaders(res);

  String reqPath = req.uri.path;
  if (reqPath == '/' || reqPath.isEmpty) {
    reqPath = '/index.html';
  }

  final cleanRel = reqPath.startsWith('/') ? reqPath.substring(1) : reqPath;
  var file = File(p.join(webBuildDir, cleanRel));
  if (!await file.exists()) {
    file = File(p.join(webBuildDir, 'index.html'));
  }

  if (await file.exists()) {
    res.headers.contentType = getMimeType(file.path);
    await res.addStream(file.openRead());
    await res.close();
  } else {
    res.statusCode = HttpStatus.notFound;
    res.write('File not found');
    await res.close();
  }
}

void main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final projectDir = Directory.current.path;
  dbPath = p.join(projectDir, 'steppetrip.db');
  jsonMirrorPath = p.join(projectDir, 'steppetrip_live_db.json');
  webBuildDir = p.join(projectDir, 'build', 'web');

  initDefaultMemoryState();
  loadJsonMirror();
  saveJsonMirror();
  await syncToSqliteFile();

  // Retry syncing to SQLite every 4 seconds if DB Browser had locked it
  Timer.periodic(const Duration(seconds: 4), (_) {
    if (sqliteNeedsSync) {
      syncToSqliteFile();
    }
  });

  final ports = [3000];
  for (final port in ports) {
    try {
      final server = await HttpServer.bind(InternetAddress.anyIPv4, port, shared: true);
      print('====================================================');
      print('SteppeTrip SQLite + Web Сервер іске қосылды!');
      print('URL (Компьютер): http://localhost:$port');
      print('URL (Телефон):   http://172.20.10.2:$port');
      print('Деректер қоры:   $dbPath');
      print('====================================================');

      server.listen((HttpRequest req) {
        if (req.uri.path.startsWith('/api/')) {
          handleApiRequest(req);
        } else {
          handleStaticRequest(req);
        }
      });
    } catch (e) {
      print('Порт $port бос емес немесе рұқсат жоқ: $e');
    }
  }
}
