// Creates and populates the physical steppetrip.db file in the project folder
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:steppetrip/models/booking_model.dart';
import 'package:steppetrip/models/review_model.dart';
import 'package:steppetrip/services/mock_data_service.dart';

void main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final projectDir = Directory.current.path;
  final dbPath = p.join(projectDir, 'steppetrip.db');

  print('Жаңа SQLite файл жасалуда: $dbPath');

  // Егер ескі файл болса және бос болса өшіреміз, ал ашық тұрса үстінен жаңартамыз
  final file = File(dbPath);
  if (await file.exists()) {
    try {
      await file.delete();
    } catch (_) {
      print('Ескерту: steppetrip.db басқа бағдарламада ашық тұр, кестелер тікелей жаңартылады...');
    }
  }

  final db = await openDatabase(
    dbPath,
    version: 2,
    onUpgrade: (db, oldV, newV) async {
      try {
        await db.execute("ALTER TABLE users ADD COLUMN role TEXT NOT NULL DEFAULT 'tourist'");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE users ADD COLUMN isApproved INTEGER NOT NULL DEFAULT 1");
      } catch (_) {}
    },
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

      // Seed initial data with ConflictAlgorithm.replace
      print('Деректер базаға толтырылуда...');
      await db.delete('users');
      await db.insert('users', MockDataService.currentUser.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

      final categoriesData = [
        {'id': 'cat_01', 'name': 'Көлдер мен таулар', 'iconName': 'landscape', 'placesCount': 1},
        {'id': 'cat_02', 'name': 'Тарихи орындар', 'iconName': 'account_balance', 'placesCount': 1},
        {'id': 'cat_03', 'name': 'Каньондар', 'iconName': 'terrain', 'placesCount': 2},
        {'id': 'cat_04', 'name': 'Ұлттық парктер', 'iconName': 'forest', 'placesCount': 1},
        {'id': 'cat_05', 'name': 'Эко-турлар', 'iconName': 'eco', 'placesCount': 1},
      ];
      for (var cat in categoriesData) {
        await db.insert('categories', cat, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      for (var place in MockDataService.tourPlaces) {
        await db.insert('tours', place.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
        if (place.isFavorite) {
          await db.insert(
            'favorites',
            {
              'id': 'fav_${place.id}',
              'userId': MockDataService.currentUser.id,
              'tourId': place.id,
              'addedAt': DateTime.now().toIso8601String(),
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      for (var booking in MockDataService.mockBookings) {
        await db.insert('bookings', booking.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
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

      final initialReviews = [
        const ReviewModel(
          id: 'rev_01',
          tourId: 'tp_01',
          userName: 'Айгүл Серікқызы',
          rating: 5,
          comment: 'Көлсай мен Қайыңды көлдері керемет әсер қалдырды! Табиғаты таңғажайып, ауасы таза.',
          date: '15 Қазан 2026',
          tags: ['Таза ауа', 'Керемет гид', 'Әдемі көрініс'],
          userAvatar: '',
        ),
        const ReviewModel(
          id: 'rev_02',
          tourId: 'tp_01',
          userName: 'Данияр Бақытұлы',
          rating: 5,
          comment: 'Атпен серуендеу және көл жағасында демалу ерекше ұнады.',
          date: '20 Қазан 2026',
          tags: ['Қауіпсіз жол', 'Әдемі көрініс'],
          userAvatar: '',
        ),
      ];
      for (var rev in initialReviews) {
        await db.insert('reviews', rev.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    },
    onCreate: (db, version) async {},
  );

  await db.close();
  print('====================================================');
  print('ДАЙЫН! steppetrip.db файлы сәтті құрылды:');
  print(dbPath);
  print('====================================================');
}

