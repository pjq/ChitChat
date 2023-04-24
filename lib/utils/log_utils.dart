import 'package:flutter/foundation.dart';

class LogUtils {
  static const String tag = 'OpenAIChat';

  static void debug(String message) {
    _log('D', message);
  }

  static void info(String message) {
    _log('I', message);
  }

  static void warn(String message) {
    _log('W', message);
  }

  static void error(String message) {
    _log('E', message);
  }

  static void _log(String level, String message) {
    final now = DateTime.now();
    final timeString = '${now.hour}:${now.minute}:${now.second}.${now.millisecond}';
    final fullMessage = '[$timeString][$tag][$level] $message';
    if (kDebugMode) {
      print(fullMessage);
    }
  }
}
