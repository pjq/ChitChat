import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class Utils {
  static bool isBigScreen(BuildContext context) {
    if(Platform.isIOS) {
      var size = MediaQuery.of(context).size;
      return size.width > 718 || size.height > 1024;
    }
    return Platform.isMacOS ||
        Platform.isWindows ||
        Platform.isLinux ||
        Platform.isFuchsia ||
        kIsWeb;
  }

}
