import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'database_helper.dart';
import 'mock_data_service.dart';
import 'tour_repository.dart';
import 'notification_service.dart';

/// Модель сессии пользователя
class UserSession {
  final String token;
  final String userId;
  final String email;
  final DateTime loggedInAt;
  final bool rememberMe;

  const UserSession({
    required this.token,
    required this.userId,
    required this.email,
    required this.loggedInAt,
    this.rememberMe = true,
  });

  Map<String, dynamic> toMap() => {
        'token': token,
        'userId': userId,
        'email': email,
        'loggedInAt': loggedInAt.toIso8601String(),
        'rememberMe': rememberMe ? 1 : 0,
      };

  factory UserSession.fromMap(Map<String, dynamic> map) => UserSession(
        token: map['token'] as String,
        userId: map['userId'] as String,
        email: map['email'] as String,
        loggedInAt: DateTime.parse(map['loggedInAt'] as String),
        rememberMe: (map['rememberMe'] as int? ?? 1) == 1,
      );

  String toJson() => jsonEncode(toMap());
  factory UserSession.fromJson(String json) =>
      UserSession.fromMap(jsonDecode(json) as Map<String, dynamic>);
}

/// Күйі (Auth Status)
enum AuthStatus {
  unauthenticated,
  authenticating,
  authenticated,
  error,
}

/// Практикалық жұмыс №6:
/// 1-7, 9, 10. Аутентификация, валидация, сессия сақтау және күйді басқару сервисі
class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._internal();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  AuthService._internal() {
    // Әдепкі сессия: Дінмұхаммед (Әкімші)
    _currentUser = MockDataService.currentUser;
    _status = AuthStatus.authenticated;
    _currentSession = UserSession(
      token: 'STP_SESSION_admin_01',
      userId: MockDataService.currentUser.id,
      email: MockDataService.currentUser.email,
      loggedInAt: DateTime.now(),
      rememberMe: true,
    );
  }

  AuthStatus _status = AuthStatus.authenticated;
  UserModel? _currentUser = MockDataService.currentUser;
  UserSession? _currentSession;
  String? _errorMessage;
  String? _successMessage;

  String? _savedEmail = 'dinmuhammed@steppetrip.kz';
  String? _savedPassword = '123456';

  // Жүйедегі пайдаланушылар тізімі (email -> UserModel)
  final Map<String, UserModel> _usersByEmail = {
    for (var u in MockDataService.demoUsers) u.email.toLowerCase(): u,
  };

  // Құпиясөздер базасы (email -> password)
  final Map<String, String> _userPasswords = {
    'dinmuhammed@steppetrip.kz': '123456',
    'dinmuhammed@admin.kz': '123456',
  };

  // Getters
  AuthStatus get status => _status;
  bool get isAuthenticated =>
      _status == AuthStatus.authenticated && _currentUser != null;
  bool get isAuthenticating => _status == AuthStatus.authenticating;
  UserModel? get currentUser => _currentUser;
  UserSession? get currentSession => _currentSession;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  String? get savedEmail => _savedEmail;
  String? get savedPassword => _savedPassword;
  List<UserModel> get availableDemoUsers => _usersByEmail.values.toList();

  void toggleRole() {
    if (_currentUser == null) return;
    final newRole = _currentUser!.isGuide ? 'tourist' : 'guide';
    final updated = _currentUser!.copyWith(role: newRole);
    _currentUser = updated;
    _usersByEmail[updated.email.toLowerCase()] = updated;
    TourRepository.instance.setCurrentUser(updated);
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  // ==========================================================================
  // 2. Валидация логикасы
  // ==========================================================================
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Электронды поштаны енгізіңіз';
    }
    final emailRegex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Электронды пошта пішімі қате (мысалы: user@domain.kz)';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Құпиясөзді енгізіңіз';
    }
    if (value.length < 6) {
      return 'Құпиясөз кем дегенде 6 таңбадан тұруы керек';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Толық аты-жөніңізді енгізіңіз';
    }
    if (value.trim().length < 2) {
      return 'Аты-жөн кем дегенде 2 әріптен тұруы қажет';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Телефон нөмірін енгізіңіз';
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) {
      return 'Телефон нөмірі толық емес (кемінде 10 сан)';
    }
    return null;
  }

  // ==========================================================================
  // 6. Қосымшаны қайта іске қосқанда сақталған сессияны тексеру (Auto-Login)
  // ==========================================================================
  Future<bool> checkSavedSession() async {
    _status = AuthStatus.authenticating;
    notifyListeners();

    try {
      if (_currentSession != null && _currentSession!.rememberMe) {
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Session check error: $e');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // ==========================================================================
  // 3. Login функциясы + 4. Қате енгізілген кезде хабарлама көрсету
  // ==========================================================================
  Future<bool> login({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    // Желі/сұрау уақытын модельдеу
    await Future.delayed(const Duration(milliseconds: 600));

    final cleanEmail = email.trim().toLowerCase();

    // 4. Қате логин немесе парольді тексеру
    if (!_userPasswords.containsKey(cleanEmail)) {
      _status = AuthStatus.error;
      _errorMessage = 'Мұндай электронды пошта тіркелмеген: $cleanEmail';
      notifyListeners();
      return false;
    }

    if (_userPasswords[cleanEmail] != password) {
      _status = AuthStatus.error;
      _errorMessage = 'Құпиясөз қате! Қайта тексеріп көріңіз.';
      notifyListeners();
      return false;
    }

    // 5. Авторизациядан кейін пайдаланушы сессиясын сақтау
    try {
      UserModel? user = _usersByEmail[cleanEmail];
      if (user == null && !kIsWeb) {
        try {
          final db = await _dbHelper.database;
          final users = await db.query('users',
              where: 'LOWER(email) = ?', whereArgs: [cleanEmail]);
          if (users.isNotEmpty) {
            user = UserModel.fromMap(users.first);
          }
        } catch (_) {}
      }

      if (user == null) {
        user = UserModel(
          id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
          fullName: cleanEmail.split('@').first,
          email: cleanEmail,
          phone: '+7 (777) 000-00-00',
          avatarUrl:
              'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde',
          completedTours: 1,
        );
      }

      _usersByEmail[cleanEmail] = user;

      final token =
          'STP_SESSION_${user.id}_${DateTime.now().millisecondsSinceEpoch}';
      _currentSession = UserSession(
        token: token,
        userId: user.id,
        email: user.email,
        loggedInAt: DateTime.now(),
        rememberMe: rememberMe,
      );

      if (rememberMe) {
        _savedEmail = cleanEmail;
        _savedPassword = password;
      }

      _currentUser = user;
      _status = AuthStatus.authenticated;
      _successMessage = 'Қош келдіңіз, ${user.fullName}!';

      // TourRepository-мен синхрондау
      TourRepository.instance.setCurrentUser(user);

      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Жүйеге кіру кезінде қате орын алды: $e';
      notifyListeners();
      return false;
    }
  }

  // ==========================================================================
  // 1. Тіркелу функциясы (Registration)
  // ==========================================================================
  Future<bool> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    String role = 'tourist',
  }) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 700));

    final cleanEmail = email.trim().toLowerCase();

    // Email бұрыннан бар ма тексеру
    if (_userPasswords.containsKey(cleanEmail)) {
      _status = AuthStatus.error;
      _errorMessage = 'Бұл электронды поштамен аккаунт бұрыннан тіркелген!';
      notifyListeners();
      return false;
    }

    try {
      final isGuide = role == 'guide';
      final isApproved = !isGuide; // Гид болса — әкімші мақұлдауын күтеді

      final newUser = UserModel(
        id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
        fullName: fullName.trim(),
        email: cleanEmail,
        phone: phone.trim(),
        avatarUrl:
            'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde',
        completedTours: 0,
        role: role,
        isApproved: isApproved,
      );

      // Пароль мен пайдаланушыны сақтау
      _userPasswords[cleanEmail] = password;
      _usersByEmail[cleanEmail] = newUser;
      _savedEmail = cleanEmail;
      _savedPassword = password;

      // SQLite-қа қолданушыны жазу (егер web емес болса)
      if (!kIsWeb) {
        try {
          final db = await _dbHelper.database;
          await db.insert('users', newUser.toMap());
        } catch (_) {}
      }

      // 5. Сессияны автоматты түрде ашу
      _currentSession = UserSession(
        token:
            'STP_SESSION_${newUser.id}_${DateTime.now().millisecondsSinceEpoch}',
        userId: newUser.id,
        email: newUser.email,
        loggedInAt: DateTime.now(),
        rememberMe: true,
      );

      _currentUser = newUser;
      _status = AuthStatus.authenticated;
      _successMessage = isGuide
          ? 'Гид ретінде өтініш қабылданды (Админ мақұлдауы күтілуде)!'
          : 'Тіркелу сәтті аяқталды! Қош келдіңіз.';

      // Гид ретінде тіркелсе — Админге хабарлама жолдау
      if (isGuide) {
        NotificationService.instance.addGuideApplication(newUser);
      }

      // TourRepository-мен синхрондау
      TourRepository.instance.setCurrentUser(newUser);

      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Тіркелу қатесі: $e';
      notifyListeners();
      return false;
    }
  }

  void approveGuide(String email) {
    final clean = email.toLowerCase();
    final user = _usersByEmail[clean];
    if (user != null) {
      final updated = user.copyWith(isApproved: true);
      _usersByEmail[clean] = updated;
      if (_currentUser?.email.toLowerCase() == clean) {
        _currentUser = updated;
        TourRepository.instance.setCurrentUser(updated);
      }
      NotificationService.instance.markGuideAsApproved(clean);
      notifyListeners();
    }
  }

  void rejectGuide(String email) {
    final clean = email.toLowerCase();
    final user = _usersByEmail[clean];
    if (user != null) {
      final updated = user.copyWith(role: 'tourist', isApproved: true);
      _usersByEmail[clean] = updated;
      if (_currentUser?.email.toLowerCase() == clean) {
        _currentUser = updated;
        TourRepository.instance.setCurrentUser(updated);
      }
      notifyListeners();
    }
  }

  void changeUserRole(String email, String newRole) {
    final clean = email.toLowerCase();
    final user = _usersByEmail[clean];
    if (user != null) {
      final updated = user.copyWith(role: newRole, isApproved: true);
      _usersByEmail[clean] = updated;
      if (_currentUser?.email.toLowerCase() == clean) {
        _currentUser = updated;
        TourRepository.instance.setCurrentUser(updated);
      }
      notifyListeners();
    }
  }

  void deleteUser(String email) {
    final clean = email.toLowerCase();
    _usersByEmail.remove(clean);
    _userPasswords.remove(clean);
    notifyListeners();
  }

  List<UserModel> get pendingGuides =>
      _usersByEmail.values.where((u) => u.isGuide && !u.isApproved).toList();

  // ==========================================================================
  // 7. Logout функциясын іске асыру
  // ==========================================================================
  Future<void> logout() async {
    _currentSession = null;
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    _successMessage = 'Жүйеден сәтті шықтыңыз.';
    _errorMessage = null;
    TourRepository.instance.setCurrentUser(null);
    notifyListeners();
  }

  // Профильді жаңарту
  Future<void> updateUser(UserModel updated) async {
    _currentUser = updated;
    final db = await _dbHelper.database;
    await db.update('users', updated.toMap(),
        where: 'id = ?', whereArgs: [updated.id]);
    notifyListeners();
  }

  // Тесттер үшін күйді қолмен орнату
  @visibleForTesting
  void setMockSession(UserSession? session, UserModel? user) {
    _currentSession = session;
    _currentUser = user;
    _status =
        session != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    notifyListeners();
  }
}
