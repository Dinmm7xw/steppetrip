import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/tour_place.dart';
import '../models/booking_model.dart';
import '../models/review_model.dart';
import 'mock_data_service.dart';

// ============================================================================
// 17. HTTP Exception кластарының иерархиясы
// ============================================================================

abstract class AppException implements Exception {
  final String message;
  final int? statusCode;

  AppException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

/// 15. Интернет байланысы жоқ болғанда
class NetworkException extends AppException {
  NetworkException([super.message = 'Интернет байланысы жоқ немесе желі қолжетімсіз']);
}

/// 16. Сервер ұзақ жауап бергенде (Timeout)
class ApiTimeoutException extends AppException {
  ApiTimeoutException([String message = 'Сервердің жауап беру уақыты асып кетті (Timeout: 10 сек)'])
      : super(message, 408);
}

/// 14. Сервер қатесі (500 Internal Server Error т.б.)
class ServerException extends AppException {
  ServerException([super.message = 'Сервер қатесі орын алды', super.statusCode = 500]);
}

/// 14. Дерек табылмады (404 Not Found)
class NotFoundException extends AppException {
  NotFoundException([String message = 'Сұралған ресурс серверден табылмады (404)'])
      : super(message, 404);
}

/// 14. Дұрыс емес сұраныс (400 Bad Request)
class BadRequestException extends AppException {
  BadRequestException([String message = 'Қате сұраныс параметрлері (400 Bad Request)'])
      : super(message, 400);
}

// ============================================================================
// 1-3. REST API Service (Endpoints, HTTP Methods, CRUD)
// ============================================================================

class ApiService {
  static final ApiService instance = ApiService._internal();

  /// 1. REST API Base URL
  String baseUrl = 'https://api.steppetrip.kz/api/v1';

  /// HTTP клиенті (тестілеу үшін inject етуге болады)
  http.Client client;

  /// Сұраныстың максималды күту уақыты (16. Timeout)
  Duration timeoutDuration;

  /// Мок/Симуляцияланған сервер режимі (Офлайн кезінде немесе сервер жоқ болғанда)
  bool simulateBackend;

  /// Қателерді сынақтан өткізу үшін күйлер (тест / демо кезінде)
  bool forceSimulateNetworkError = false;
  bool forceSimulateTimeout = false;
  bool forceSimulateServerError = false;

  // Симуляциялық сервердің жадындағы деректер
  final List<Map<String, dynamic>> _mockToursDb = [];
  final List<Map<String, dynamic>> _mockBookingsDb = [];
  final List<Map<String, dynamic>> _mockReviewsDb = [];

  ApiService._internal({
    http.Client? httpClient,
    this.timeoutDuration = const Duration(seconds: 10),
    this.simulateBackend = true,
  }) : client = httpClient ?? http.Client() {
    _initMockServerDb();
  }

  factory ApiService({http.Client? client, Duration? timeout, bool simulateBackend = true}) {
    if (client != null || timeout != null) {
      return ApiService._internal(
        httpClient: client,
        timeoutDuration: timeout ?? const Duration(seconds: 10),
        simulateBackend: simulateBackend,
      );
    }
    return instance;
  }

  void _initMockServerDb() {
    if (_mockToursDb.isEmpty) {
      for (var t in MockDataService.tourPlaces) {
        _mockToursDb.add(t.toJson());
      }
    }
    if (_mockBookingsDb.isEmpty) {
      for (var b in MockDataService.mockBookings) {
        _mockBookingsDb.add(b.toJson());
      }
    }
    if (_mockReviewsDb.isEmpty) {
      _mockReviewsDb.addAll([
        {
          'id': 'rev_01',
          'tourId': 'tp_01',
          'userName': 'Айгүл Серікқызы',
          'rating': 5,
          'comment': 'Көлсай мен Қайыңды көлдері керемет әсер қалдырды! Ұйымдастыру жоғары деңгейде.',
          'date': '15 Қазан 2026',
          'tags': ['Таза ауа', 'Керемет гид', 'Әдемі көрініс'],
          'userAvatar': null,
        },
        {
          'id': 'rev_02',
          'tourId': 'tp_01',
          'userName': 'Данияр Бақытұлы',
          'rating': 5,
          'comment': 'Атпен серуендеу және көл жағасында демалу ерекше ұнады.',
          'date': '20 Қазан 2026',
          'tags': ['Қауіпсіз жол', 'Әдемі көрініс'],
          'userAvatar': null,
        },
      ]);
    }
  }

  // ==========================================================================
  // HTTP ҚАТЕЛЕРДІ ЖӘНЕ ЖАУАПТАРДЫ ТАЛДАУ (Error & Status handling)
  // ==========================================================================

  dynamic _handleResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
        if (response.body.isEmpty) return null;
        return jsonDecode(response.body);
      case 204:
        return null;
      case 400:
        throw BadRequestException('Қате параметрлер: ${response.body}');
      case 404:
        throw NotFoundException('Сұралған ресурс табылмады (404)');
      case 500:
      case 502:
      case 503:
        throw ServerException('Сервер қатесі (${response.statusCode}): ${response.body}', response.statusCode);
      default:
        throw ServerException('Күтпеген қате: ${response.statusCode}', response.statusCode);
    }
  }

  Future<T> _executeWithHandling<T>(Future<T> Function() action) async {
    // 15, 16, 17. Exception өңдеу
    if (forceSimulateNetworkError) {
      throw NetworkException();
    }
    if (forceSimulateTimeout) {
      throw ApiTimeoutException();
    }
    if (forceSimulateServerError) {
      throw ServerException('Сынақтық 500 Internal Server Error қатесі', 500);
    }

    try {
      return await action();
    } on TimeoutException {
      throw ApiTimeoutException();
    } on http.ClientException catch (e) {
      throw NetworkException('Желіге қосылу қатесі: ${e.message}');
    } catch (e) {
      if (e.toString().contains('SocketException')) throw NetworkException();
      if (e is AppException) rethrow;
      throw ServerException('Жүйелік қате: $e');
    }
  }

  // ==========================================================================
  // 5. GET СҰРАУЛАРЫ (Fetch data)
  // ==========================================================================

  /// GET /tours - Барлық турлар тізімін алу
  Future<List<TourPlace>> getTours() async {
    return await _executeWithHandling(() async {
      if (simulateBackend) {
        await Future.delayed(const Duration(milliseconds: 300));
        // JSON арқылы түрлендіру сынағы
        final jsonString = jsonEncode(_mockToursDb);
        final List decoded = jsonDecode(jsonString);
        return decoded.map((item) => TourPlace.fromJson(item as Map<String, dynamic>)).toList();
      }

      final url = Uri.parse('$baseUrl/tours');
      final response = await client
          .get(url, headers: {'Accept': 'application/json'})
          .timeout(timeoutDuration);

      final data = _handleResponse(response) as List;
      return data.map((item) => TourPlace.fromJson(item as Map<String, dynamic>)).toList();
    });
  }

  /// GET /tours/{id} - Жеке тур мәліметін алу
  Future<TourPlace> getTourById(String id) async {
    return await _executeWithHandling(() async {
      if (simulateBackend) {
        await Future.delayed(const Duration(milliseconds: 200));
        final tour = _mockToursDb.firstWhere(
          (t) => t['id'] == id,
          orElse: () => throw NotFoundException('Тур табылмады: $id'),
        );
        return TourPlace.fromJson(tour);
      }

      final url = Uri.parse('$baseUrl/tours/$id');
      final response = await client
          .get(url, headers: {'Accept': 'application/json'})
          .timeout(timeoutDuration);

      final data = _handleResponse(response) as Map<String, dynamic>;
      return TourPlace.fromJson(data);
    });
  }

  /// GET /bookings - Қолданушының барлық брондауларын алу
  Future<List<BookingModel>> getBookings() async {
    return await _executeWithHandling(() async {
      if (simulateBackend) {
        await Future.delayed(const Duration(milliseconds: 300));
        final jsonString = jsonEncode(_mockBookingsDb);
        final List decoded = jsonDecode(jsonString);
        return decoded.map((b) => BookingModel.fromJson(b as Map<String, dynamic>)).toList();
      }

      final url = Uri.parse('$baseUrl/bookings');
      final response = await client
          .get(url, headers: {'Accept': 'application/json'})
          .timeout(timeoutDuration);

      final data = _handleResponse(response) as List;
      return data.map((item) => BookingModel.fromJson(item as Map<String, dynamic>)).toList();
    });
  }

  /// GET /reviews?tourId={id} - Белгілі бір турдың пікірлерін алу
  Future<List<ReviewModel>> getReviews(String tourId) async {
    return await _executeWithHandling(() async {
      if (simulateBackend) {
        await Future.delayed(const Duration(milliseconds: 200));
        final filtered = _mockReviewsDb.where((r) => r['tourId'] == tourId).toList();
        final jsonString = jsonEncode(filtered);
        final List decoded = jsonDecode(jsonString);
        return decoded.map((r) => ReviewModel.fromJson(r as Map<String, dynamic>)).toList();
      }

      final url = Uri.parse('$baseUrl/reviews?tourId=$tourId');
      final response = await client
          .get(url, headers: {'Accept': 'application/json'})
          .timeout(timeoutDuration);

      final data = _handleResponse(response) as List;
      return data.map((item) => ReviewModel.fromJson(item as Map<String, dynamic>)).toList();
    });
  }

  // ==========================================================================
  // 8. POST СҰРАУЛАРЫ (Create new data)
  // ==========================================================================

  /// POST /tours - Жаңа тур құру
  Future<TourPlace> createTour(TourPlace tour) async {
    return await _executeWithHandling(() async {
      final jsonBody = jsonEncode(tour.toJson());

      if (simulateBackend) {
        await Future.delayed(const Duration(milliseconds: 350));
        final map = jsonDecode(jsonBody) as Map<String, dynamic>;
        _mockToursDb.insert(0, map);
        return TourPlace.fromJson(map);
      }

      final url = Uri.parse('$baseUrl/tours');
      final response = await client
          .post(
            url,
            headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: jsonBody,
          )
          .timeout(timeoutDuration);

      final data = _handleResponse(response) as Map<String, dynamic>;
      return TourPlace.fromJson(data);
    });
  }

  /// POST /bookings - Жаңа брондау жасау
  Future<BookingModel> createBooking(BookingModel booking) async {
    return await _executeWithHandling(() async {
      final jsonBody = jsonEncode(booking.toJson());

      if (simulateBackend) {
        await Future.delayed(const Duration(milliseconds: 350));
        final map = jsonDecode(jsonBody) as Map<String, dynamic>;
        _mockBookingsDb.insert(0, map);
        return BookingModel.fromJson(map);
      }

      final url = Uri.parse('$baseUrl/bookings');
      final response = await client
          .post(
            url,
            headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: jsonBody,
          )
          .timeout(timeoutDuration);

      final data = _handleResponse(response) as Map<String, dynamic>;
      return BookingModel.fromJson(data);
    });
  }

  /// POST /reviews - Жаңа пікір қосу
  Future<ReviewModel> createReview(ReviewModel review) async {
    return await _executeWithHandling(() async {
      final jsonBody = jsonEncode(review.toJson());

      if (simulateBackend) {
        await Future.delayed(const Duration(milliseconds: 300));
        final map = jsonDecode(jsonBody) as Map<String, dynamic>;
        _mockReviewsDb.insert(0, map);
        return ReviewModel.fromJson(map);
      }

      final url = Uri.parse('$baseUrl/reviews');
      final response = await client
          .post(
            url,
            headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: jsonBody,
          )
          .timeout(timeoutDuration);

      final data = _handleResponse(response) as Map<String, dynamic>;
      return ReviewModel.fromJson(data);
    });
  }

  // ==========================================================================
  // 9. PUT ЖӘНЕ PATCH СҰРАУЛАРЫ (Update data)
  // ==========================================================================

  /// PUT /tours/{id} - Тур деректерін толық жаңарту
  Future<TourPlace> updateTour(String id, TourPlace tour) async {
    return await _executeWithHandling(() async {
      final jsonBody = jsonEncode(tour.toJson());

      if (simulateBackend) {
        await Future.delayed(const Duration(milliseconds: 300));
        final index = _mockToursDb.indexWhere((t) => t['id'] == id);
        if (index == -1) throw NotFoundException('Жаңартылатын тур табылмады (404)');
        final map = jsonDecode(jsonBody) as Map<String, dynamic>;
        _mockToursDb[index] = map;
        return TourPlace.fromJson(map);
      }

      final url = Uri.parse('$baseUrl/tours/$id');
      final response = await client
          .put(
            url,
            headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: jsonBody,
          )
          .timeout(timeoutDuration);

      final data = _handleResponse(response) as Map<String, dynamic>;
      return TourPlace.fromJson(data);
    });
  }

  /// PATCH /bookings/{id} - Брондау мәртебесін өзгерту
  Future<BookingModel> patchBookingStatus(String id, BookingStatus newStatus) async {
    return await _executeWithHandling(() async {
      final patchData = {'status': newStatus.name};
      final jsonBody = jsonEncode(patchData);

      if (simulateBackend) {
        await Future.delayed(const Duration(milliseconds: 250));
        final index = _mockBookingsDb.indexWhere((b) => b['id'] == id);
        if (index == -1) throw NotFoundException('Брондау табылмады (404)');
        _mockBookingsDb[index]['status'] = newStatus.name;
        return BookingModel.fromJson(_mockBookingsDb[index]);
      }

      final url = Uri.parse('$baseUrl/bookings/$id');
      final response = await client
          .patch(
            url,
            headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: jsonBody,
          )
          .timeout(timeoutDuration);

      final data = _handleResponse(response) as Map<String, dynamic>;
      return BookingModel.fromJson(data);
    });
  }

  // ==========================================================================
  // 10. DELETE СҰРАУЛАРЫ (Delete data)
  // ==========================================================================

  /// DELETE /tours/{id} - Турды серверден өшіру
  Future<bool> deleteTour(String id) async {
    return await _executeWithHandling(() async {
      if (simulateBackend) {
        await Future.delayed(const Duration(milliseconds: 250));
        final index = _mockToursDb.indexWhere((t) => t['id'] == id);
        if (index == -1) throw NotFoundException('Өшірілетін тур табылмады: $id');
        _mockToursDb.removeAt(index);
        return true;
      }

      final url = Uri.parse('$baseUrl/tours/$id');
      final response = await client
          .delete(url, headers: {'Accept': 'application/json'})
          .timeout(timeoutDuration);

      _handleResponse(response);
      return true;
    });
  }

  /// DELETE /bookings/{id} - Брондауды жою
  Future<bool> deleteBooking(String id) async {
    return await _executeWithHandling(() async {
      if (simulateBackend) {
        await Future.delayed(const Duration(milliseconds: 250));
        final index = _mockBookingsDb.indexWhere((b) => b['id'] == id);
        if (index == -1) throw NotFoundException('Өшірілетін брондау табылмады: $id');
        _mockBookingsDb.removeAt(index);
        return true;
      }

      final url = Uri.parse('$baseUrl/bookings/$id');
      final response = await client
          .delete(url, headers: {'Accept': 'application/json'})
          .timeout(timeoutDuration);

      _handleResponse(response);
      return true;
    });
  }

  /// DELETE /reviews/{id} - Пікірді жою
  Future<bool> deleteReview(String id) async {
    return await _executeWithHandling(() async {
      if (simulateBackend) {
        await Future.delayed(const Duration(milliseconds: 200));
        _mockReviewsDb.removeWhere((r) => r['id'] == id);
        return true;
      }

      final url = Uri.parse('$baseUrl/reviews/$id');
      final response = await client
          .delete(url, headers: {'Accept': 'application/json'})
          .timeout(timeoutDuration);

      _handleResponse(response);
      return true;
    });
  }
}
