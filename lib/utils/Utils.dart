import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class Utils {
  static bool isBigScreen() {
    return Platform.isMacOS ||
        Platform.isWindows ||
        Platform.isLinux ||
        Platform.isFuchsia ||
        kIsWeb;
  }
}
