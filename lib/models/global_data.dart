import 'package:speech_to_text/speech_to_text.dart';

// Create a class to store data in memory
class GlobalData {
  // Declare variables to store data
  List<LocaleName> sttLocaleNames = [];
  List<dynamic> ttsLanguages = [];

  // Singleton pattern to ensure only one instance of the class
  static final GlobalData _instance = GlobalData._internal();

  // Private constructor
  GlobalData._internal();

  // Factory method to return the singleton instance
  factory GlobalData() {
    return _instance;
  }
}