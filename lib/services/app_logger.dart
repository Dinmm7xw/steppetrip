import 'dart:async';
import 'package:flutter/foundation.dart';

/// Лог деңгейлері
enum LogLevel { debug, info, warning, error, realtime }

/// Лог жазбасының моделі
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final String message;
  final dynamic error;
  final StackTrace? stackTrace;

  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
    this.error,
    this.stackTrace,
  });

  String get formattedTime =>
      '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}.${timestamp.millisecond.toString().padLeft(3, '0')}';

  @override
  String toString() => '[$formattedTime] [${level.name.toUpperCase()}] [$tag] $message';
}

/// Практикалық жұмыс №7:
/// 13. Қосымшадағы маңызды әрекеттер мен қателер үшін лог жүргізу жүйесі (Structured Logger)
class AppLogger extends ChangeNotifier {
  static final AppLogger instance = AppLogger._internal();

  AppLogger._internal();

  final List<LogEntry> _logs = [];

  List<LogEntry> get logs => List.unmodifiable(_logs);

  void log(
    LogLevel level,
    String tag,
    String message, {
    dynamic error,
    StackTrace? stackTrace,
  }) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      tag: tag,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );

    _logs.add(entry);
    if (_logs.length > 500) {
      _logs.removeAt(0);
    }

    if (kDebugMode) {
      debugPrint(entry.toString());
      if (error != null) debugPrint('  Error details: $error');
    }

    notifyListeners();
  }

  void info(String tag, String message) => log(LogLevel.info, tag, message);
  void debug(String tag, String message) => log(LogLevel.debug, tag, message);
  void warning(String tag, String message) => log(LogLevel.warning, tag, message);
  void error(String tag, String message, [dynamic err, StackTrace? stack]) =>
      log(LogLevel.error, tag, message, error: err, stackTrace: stack);
  void realtime(String tag, String message) => log(LogLevel.realtime, tag, message);

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }
}

