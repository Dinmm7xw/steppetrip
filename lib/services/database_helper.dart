// Database helper for SteppeTrip app with Web and Mobile support
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/tour_place.dart';
import '../models/booking_model.dart';
import '../models/review_model.dart';
import '../models/category_model.dart';
import '../models/user_model.dart';
import 'mock_data_service.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static String? _dbPath;

  // In-memory web fallback data storage
  static final List<TourPlace> _webTours = List.from(MockDataService.tourPlaces);
  static final List<BookingModel> _webBookings = List.from(MockDataService.mockBookings);
  static final List<ReviewModel> _webReviews = [
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
  ];
  static UserModel _webUser = MockDataService.currentUser;
  static final List<CategoryModel> _webCategories = [
    const CategoryModel(id: 'cat_01', name: 'Көлдер мен таулар', iconName: 'landscape', placesCount: 1),
    const CategoryModel(id: 'cat_02', name: 'Тарихи орындар', iconName: 'account_balance', placesCount: 1),
    const CategoryModel(id: 'cat_03', name: 'Каньондар', iconName: 'terrain', placesCount: 2),
    const CategoryModel(id: 'cat_04', name: 'Ұлттық парктер', iconName: 'forest', placesCount: 1),
    const CategoryModel(id: 'cat_05', name: 'Эко-турлар', iconName: 'eco', placesCount: 1),
  ];

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    if (kIsWeb) {
      throw UnsupportedError('Running in-memory for Web');
    }
    _database = await _initDB('steppetrip.db');
    return _database!;
  }

  // Expose the computed database file path for debugging
  Future<String?> getDatabasePath() async {
    if (kIsWeb) return 'IndexedDB / Memory (Web)';
    if (_dbPath == null) {
      await _initDB('steppetrip.db');
    }
    return _dbPath;
  }

  // Allow setting in-memory or custom db for unit testing
  @visibleForTesting
  static void setMockDatabase(Database? db) {
    _database = db;
  }

  Future<Database> _initDB(String filePath) async {
    if (!kIsWeb) {
      try {
        if (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux) {
          sqfliteFfiInit();
          databaseFactory = databaseFactoryFfi;
        }
      } catch (_) {}
    }

    String path;
    try {
      if (!kIsWeb) {
        final appDocDir = await getApplicationDocumentsDirectory();
        path = join(appDocDir.path, filePath);
      } else {
        path = filePath;
      }
    } catch (_) {
      try {
        final dbPath = await getDatabasesPath();
        path = join(dbPath, filePath);
      } catch (_) {
        path = filePath;
      }
    }

    _dbPath = path;

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createDB(Database db, int version) async {
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
        notes TEXT,
        FOREIGN KEY (tourId) REFERENCES tours (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE reviews (
        id TEXT PRIMARY KEY,
        tourId TEXT NOT NULL,
        userName TEXT NOT NULL,
        rating INTEGER NOT NULL,
        comment TEXT NOT NULL,
        date TEXT NOT NULL,
        tags TEXT NOT NULL,
        userAvatar TEXT,
        FOREIGN KEY (tourId) REFERENCES tours (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        iconName TEXT NOT NULL,
        placesCount INTEGER NOT NULL DEFAULT 0
      )
    ''');

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
      CREATE TABLE favorites (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        tourId TEXT NOT NULL,
        addedAt TEXT NOT NULL,
        FOREIGN KEY (tourId) REFERENCES tours (id) ON DELETE CASCADE,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await _seedInitialData(db);
  }

  Future<void> _seedInitialData(Database db) async {
    await db.insert('users', MockDataService.currentUser.toMap());
    final categoriesData = [
      {'id': 'cat_01', 'name': 'Көлдер мен таулар', 'iconName': 'landscape', 'placesCount': 1},
      {'id': 'cat_02', 'name': 'Тарихи орындар', 'iconName': 'account_balance', 'placesCount': 1},
      {'id': 'cat_03', 'name': 'Каньондар', 'iconName': 'terrain', 'placesCount': 2},
      {'id': 'cat_04', 'name': 'Ұлттық парктер', 'iconName': 'forest', 'placesCount': 1},
      {'id': 'cat_05', 'name': 'Эко-турлар', 'iconName': 'eco', 'placesCount': 1},
    ];
    for (var cat in categoriesData) {
      await db.insert('categories', cat);
    }
    for (var place in MockDataService.tourPlaces) {
      await db.insert('tours', place.toMap());
      if (place.isFavorite) {
        await db.insert('favorites', {
          'id': 'fav_${place.id}',
          'userId': MockDataService.currentUser.id,
          'tourId': place.id,
          'addedAt': DateTime.now().toIso8601String(),
        });
      }
    }
    for (var booking in MockDataService.mockBookings) {
      await db.insert('bookings', booking.toMap());
    }
    final initialReviews = [
      const ReviewModel(
        id: 'rev_01',
        tourId: 'tp_01',
        userName: 'Айгүл Серікқызы',
        rating: 5,
        comment: 'Көлсай мен Қайыңды көлдері керемет әсер қалдырды! Табиғаты таңғажайып, ауасы таза. Ұйымдастыру жоғары деңгейде болды.',
        date: '15 Қазан 2026',
        tags: ['Таза ауа', 'Керемет гид', 'Әдемі көрініс'],
        userAvatar: '',
      ),
    ];
    for (var rev in initialReviews) {
      await db.insert('reviews', rev.toMap());
    }
  }

  // ==================== TOURS CRUD ====================
  Future<int> insertTour(TourPlace tour) async {
    if (kIsWeb) {
      _webTours.removeWhere((t) => t.id == tour.id);
      _webTours.insert(0, tour);
      return 1;
    }
    try {
      final db = await database;
      return await db.insert('tours', tour.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (_) {
      _webTours.removeWhere((t) => t.id == tour.id);
      _webTours.insert(0, tour);
      return 1;
    }
  }

  Future<List<TourPlace>> getAllTours() async {
    if (kIsWeb) return List.from(_webTours);
    try {
      final db = await database;
      final maps = await db.query('tours', orderBy: 'rating DESC');
      return maps.map((m) => TourPlace.fromMap(m)).toList();
    } catch (_) {
      return List.from(_webTours);
    }
  }

  Future<TourPlace?> getTourById(String id) async {
    if (kIsWeb) {
      try {
        return _webTours.firstWhere((t) => t.id == id);
      } catch (_) {
        return null;
      }
    }
    try {
      final db = await database;
      final maps = await db.query('tours', where: 'id = ?', whereArgs: [id], limit: 1);
      if (maps.isNotEmpty) {
        return TourPlace.fromMap(maps.first);
      }
      return null;
    } catch (_) {
      try {
        return _webTours.firstWhere((t) => t.id == id);
      } catch (_) {
        return null;
      }
    }
  }

  Future<int> updateTour(TourPlace tour) async {
    if (kIsWeb) {
      final idx = _webTours.indexWhere((t) => t.id == tour.id);
      if (idx != -1) _webTours[idx] = tour;
      return 1;
    }
    try {
      final db = await database;
      return await db.update('tours', tour.toMap(), where: 'id = ?', whereArgs: [tour.id]);
    } catch (_) {
      final idx = _webTours.indexWhere((t) => t.id == tour.id);
      if (idx != -1) _webTours[idx] = tour;
      return 1;
    }
  }

  Future<int> deleteTour(String id) async {
    if (kIsWeb) {
      _webTours.removeWhere((t) => t.id == id);
      return 1;
    }
    try {
      final db = await database;
      return await db.delete('tours', where: 'id = ?', whereArgs: [id]);
    } catch (_) {
      _webTours.removeWhere((t) => t.id == id);
      return 1;
    }
  }

  // ==================== FAVORITES ====================
  Future<bool> toggleFavorite(String tourId) async {
    final tour = await getTourById(tourId);
    if (tour == null) return false;
    final newStatus = !tour.isFavorite;
    await updateTour(tour.copyWith(isFavorite: newStatus));
    return newStatus;
  }

  Future<List<TourPlace>> getFavoriteTours() async {
    final all = await getAllTours();
    return all.where((t) => t.isFavorite).toList();
  }

  // ==================== SEARCH, FILTER, SORT ====================
  Future<List<TourPlace>> searchAndFilterTours({
    String query = '',
    String category = 'Барлығы',
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String sortBy = 'rating_desc',
  }) async {
    final all = await getAllTours();
    return all.where((t) {
      final q = query.trim().toLowerCase();
      final matchQ = q.isEmpty ||
          t.name.toLowerCase().contains(q) ||
          t.region.toLowerCase().contains(q) ||
          t.description.toLowerCase().contains(q);
      final matchC = category == 'Барлығы' || t.category == category;
      final matchMinP = minPrice == null || t.pricePerPerson >= minPrice;
      final matchMaxP = maxPrice == null || t.pricePerPerson <= maxPrice;
      final matchR = minRating == null || t.rating >= minRating;
      return matchQ && matchC && matchMinP && matchMaxP && matchR;
    }).toList();
  }

  // ==================== BOOKINGS CRUD ====================
  Future<int> insertBooking(BookingModel booking) async {
    if (kIsWeb) {
      _webBookings.removeWhere((b) => b.id == booking.id);
      _webBookings.insert(0, booking);
      return 1;
    }
    try {
      final db = await database;
      return await db.insert('bookings', booking.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (_) {
      _webBookings.removeWhere((b) => b.id == booking.id);
      _webBookings.insert(0, booking);
      return 1;
    }
  }

  Future<List<BookingModel>> getAllBookings() async {
    if (kIsWeb) return List.from(_webBookings);
    try {
      final db = await database;
      final maps = await db.query('bookings', orderBy: 'id DESC');
      return maps.map((m) => BookingModel.fromMap(m)).toList();
    } catch (_) {
      return List.from(_webBookings);
    }
  }

  Future<int> updateBooking(BookingModel booking) async {
    if (kIsWeb) {
      final idx = _webBookings.indexWhere((b) => b.id == booking.id);
      if (idx != -1) _webBookings[idx] = booking;
      return 1;
    }
    try {
      final db = await database;
      return await db.update('bookings', booking.toMap(), where: 'id = ?', whereArgs: [booking.id]);
    } catch (_) {
      final idx = _webBookings.indexWhere((b) => b.id == booking.id);
      if (idx != -1) _webBookings[idx] = booking;
      return 1;
    }
  }

  Future<int> deleteBooking(String id) async {
    if (kIsWeb) {
      _webBookings.removeWhere((b) => b.id == id);
      return 1;
    }
    try {
      final db = await database;
      return await db.delete('bookings', where: 'id = ?', whereArgs: [id]);
    } catch (_) {
      _webBookings.removeWhere((b) => b.id == id);
      return 1;
    }
  }

  // ==================== USER PROFILE ====================
  Future<UserModel> getUserProfile() async {
    if (kIsWeb) return _webUser;
    try {
      final db = await database;
      final maps = await db.query('users', limit: 1);
      if (maps.isNotEmpty) {
        return UserModel.fromMap(maps.first);
      }
      return _webUser;
    } catch (_) {
      return _webUser;
    }
  }

  Future<int> updateUserProfile(UserModel user) async {
    _webUser = user;
    if (kIsWeb) return 1;
    try {
      final db = await database;
      return await db.update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
    } catch (_) {
      return 1;
    }
  }

  // ==================== REVIEWS CRUD ====================
  Future<int> insertReview(ReviewModel review) async {
    _webReviews.insert(0, review);
    if (kIsWeb) return 1;
    try {
      final db = await database;
      return await db.insert('reviews', review.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (_) {
      return 1;
    }
  }

  Future<List<ReviewModel>> getReviewsForTour(String tourId) async {
    if (kIsWeb) {
      return _webReviews.where((r) => r.tourId == tourId).toList();
    }
    try {
      final db = await database;
      final maps = await db.query('reviews', where: 'tourId = ?', whereArgs: [tourId], orderBy: 'id DESC');
      return maps.map((m) => ReviewModel.fromMap(m)).toList();
    } catch (_) {
      return _webReviews.where((r) => r.tourId == tourId).toList();
    }
  }

  Future<int> deleteReview(String id, String tourId) async {
    _webReviews.removeWhere((r) => r.id == id);
    if (kIsWeb) return 1;
    try {
      final db = await database;
      return await db.delete('reviews', where: 'id = ?', whereArgs: [id]);
    } catch (_) {
      return 1;
    }
  }

  // ==================== CATEGORIES ====================
  Future<List<CategoryModel>> getAllCategories() async {
    return List.from(_webCategories);
  }

  // Reset database helper for testing or re-initialization
  Future<void> clearAllData() async {
    _webTours.clear();
    _webTours.addAll(MockDataService.tourPlaces);
    _webBookings.clear();
    _webBookings.addAll(MockDataService.mockBookings);
    _webUser = MockDataService.currentUser;
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
