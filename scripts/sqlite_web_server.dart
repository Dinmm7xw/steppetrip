// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:steppetrip/models/booking_model.dart';
import 'package:steppetrip/models/review_model.dart';
import 'package:steppetrip/services/mock_data_service.dart';

late final String dbPath;
late final String webBuildDir;

Future<Database> openSteppeDb() async {
  final db = await databaseFactoryFfi.openDatabase(
    dbPath,
    options: OpenDatabaseOptions(
      version: 2,
      onOpen: (db) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS tours (
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
        await db.execute('''
          CREATE TABLE IF NOT EXISTS bookings (
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
          CREATE TABLE IF NOT EXISTS reviews (
            id TEXT PRIMARY KEY,
            tourId TEXT NOT NULL,
            userName TEXT NOT NULL,
            rating INTEGER NOT NULL,
            comment TEXT NOT NULL,
            date TEXT NOT NULL,
            tags TEXT NOT NULL,
            userAvatar TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS categories (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL UNIQUE,
            iconName TEXT NOT NULL,
            placesCount INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS users (
            id TEXT PRIMARY KEY,
            fullName TEXT NOT NULL,
            email TEXT NOT NULL,
            phone TEXT NOT NULL,
            avatarUrl TEXT NOT NULL,
            preferredLanguage TEXT NOT NULL,
            completedTours INTEGER NOT NULL DEFAULT 0,
            role TEXT NOT NULL DEFAULT 'tourist',
            isApproved INTEGER NOT NULL DEFAULT 1
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS user_passwords (
            email TEXT PRIMARY KEY,
            password TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS favorites (
            id TEXT PRIMARY KEY,
            userId TEXT NOT NULL,
            tourId TEXT NOT NULL,
            addedAt TEXT NOT NULL
          )
        ''');
        try {
          await db.execute("ALTER TABLE users ADD COLUMN role TEXT NOT NULL DEFAULT 'tourist'");
        } catch (_) {}
        try {
          await db.execute("ALTER TABLE users ADD COLUMN isApproved INTEGER NOT NULL DEFAULT 1");
        } catch (_) {}
      },
    ),
  );
  return db;
}

Future<void> ensureSeeded() async {
  final db = await openSteppeDb();
  try {
    final usersCount = await db.rawQuery('SELECT COUNT(*) as cnt FROM users');
    final toursCount = await db.rawQuery('SELECT COUNT(*) as cnt FROM tours');
    final uCnt = (usersCount.first['cnt'] as int?) ?? 0;
    final tCnt = (toursCount.first['cnt'] as int?) ?? 0;

    // Ensure admin user exists
    await db.insert('users', MockDataService.currentUser.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    await db.insert(
      'user_passwords',
      {'email': 'dinmuhammed@steppetrip.kz', 'password': '123456'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (tCnt == 0) {
      for (var place in MockDataService.tourPlaces) {
        await db.insert('tours', place.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }

    final bookingsCount = await db.rawQuery('SELECT COUNT(*) as cnt FROM bookings');
    final bCnt = (bookingsCount.first['cnt'] as int?) ?? 0;
    if (bCnt == 0) {
      for (var booking in MockDataService.mockBookings) {
        await db.insert('bookings', booking.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await db.insert(
        'bookings',
        {
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
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    final reviewsCount = await db.rawQuery('SELECT COUNT(*) as cnt FROM reviews');
    final rCnt = (reviewsCount.first['cnt'] as int?) ?? 0;
    if (rCnt == 0) {
      const rev = ReviewModel(
        id: 'rev_01',
        tourId: 'tp_01',
        userName: 'Айгүл Серікқызы',
        rating: 5,
        comment: 'Көлсай мен Қайыңды көлдері керемет әсер қалдырды!',
        date: '15 Қазан 2026',
        tags: ['Таза ауа', 'Керемет гид', 'Әдемі көрініс'],
        userAvatar: '',
      );
      await db.insert('reviews', rev.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    print('SQLite базасы тексерілді: users=$uCnt, tours=$tCnt');
  } finally {
    await db.close();
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
  final db = await openSteppeDb();

  try {
    if (path == '/api/state' && req.method == 'GET') {
      final users = await db.query('users');
      final passRows = await db.query('user_passwords');
      final tours = await db.query('tours', orderBy: 'rating DESC');
      final bookings = await db.query('bookings', orderBy: 'id DESC');
      final reviews = await db.query('reviews', orderBy: 'id DESC');

      final Map<String, String> passwords = {};
      for (var row in passRows) {
        passwords[row['email'].toString()] = row['password'].toString();
      }

      res.headers.contentType = ContentType.json;
      res.write(jsonEncode({
        'users': users,
        'passwords': passwords,
        'tours': tours,
        'bookings': bookings,
        'reviews': reviews,
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

        // Check existing user by email so we update same row if needed
        final existing = await db.query('users', where: 'LOWER(email) = ?', whereArgs: [email]);
        if (existing.isNotEmpty) {
          userMap['id'] = existing.first['id'];
        }

        await db.insert('users', userMap, conflictAlgorithm: ConflictAlgorithm.replace);
        if (password != null && password.isNotEmpty) {
          await db.insert(
            'user_passwords',
            {'email': email, 'password': password},
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        print('[SQLite] Пайдаланушы сақталды: ${userMap['fullName']} ($email, role=${userMap['role']}, approved=${userMap['isApproved']})');
        res.headers.contentType = ContentType.json;
        res.write(jsonEncode({'ok': true, 'user': userMap}));
        await res.close();
        return;
      } else if (req.method == 'DELETE') {
        final email = (req.uri.queryParameters['email'] ?? body['email'] ?? '').toString().toLowerCase();
        await db.delete('users', where: 'LOWER(email) = ?', whereArgs: [email]);
        await db.delete('user_passwords', where: 'LOWER(email) = ?', whereArgs: [email]);
        print('[SQLite] Пайдаланушы өшірілді: $email');
        res.headers.contentType = ContentType.json;
        res.write(jsonEncode({'ok': true}));
        await res.close();
        return;
      }
    }

    if (path == '/api/tours') {
      if (req.method == 'POST' || req.method == 'PUT') {
        await db.insert('tours', body, conflictAlgorithm: ConflictAlgorithm.replace);
        print('[SQLite] Тур сақталды: ${body['name']}');
        res.headers.contentType = ContentType.json;
        res.write(jsonEncode({'ok': true}));
        await res.close();
        return;
      } else if (req.method == 'DELETE') {
        final id = (req.uri.queryParameters['id'] ?? body['id'] ?? '').toString();
        await db.delete('tours', where: 'id = ?', whereArgs: [id]);
        print('[SQLite] Тур өшірілді: $id');
        res.headers.contentType = ContentType.json;
        res.write(jsonEncode({'ok': true}));
        await res.close();
        return;
      }
    }

    if (path == '/api/bookings') {
      if (req.method == 'POST' || req.method == 'PUT') {
        await db.insert('bookings', body, conflictAlgorithm: ConflictAlgorithm.replace);
        print('[SQLite] Брондау сақталды: ${body['id']} (${body['status']})');
        res.headers.contentType = ContentType.json;
        res.write(jsonEncode({'ok': true}));
        await res.close();
        return;
      } else if (req.method == 'DELETE') {
        final id = (req.uri.queryParameters['id'] ?? body['id'] ?? '').toString();
        await db.delete('bookings', where: 'id = ?', whereArgs: [id]);
        print('[SQLite] Брондау өшірілді: $id');
        res.headers.contentType = ContentType.json;
        res.write(jsonEncode({'ok': true}));
        await res.close();
        return;
      }
    }

    if (path == '/api/reviews') {
      if (req.method == 'POST') {
        await db.insert('reviews', body, conflictAlgorithm: ConflictAlgorithm.replace);
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
    print('[SQLite Server Error] $e\n$st');
    res.statusCode = HttpStatus.internalServerError;
    res.write(jsonEncode({'error': e.toString()}));
    await res.close();
  } finally {
    await db.close();
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
  webBuildDir = p.join(projectDir, 'build', 'web');

  await ensureSeeded();

  final ports = [8080, 80];
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

