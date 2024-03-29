import 'package:flutter/foundation.dart';

class LogUtils {
  static const String tag = 'ChitChat';

  static void debug(String tag, String message) {
    _log('D', "$tag:$message");
  }

  static void info(String tag, String message) {
    _log('I',  "$tag:$message");
  }

  static void warn(String tag, String message) {
    _log('W',  "$tag:$message");
  }

  static void error(String tag, String message) {
    _log('E',  "$tag:$message");
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
