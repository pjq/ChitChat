import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chitchat/models/constants.dart';
class Prompt {
  final String id;
  final String title;
  final String content;
  final String category;
  bool selected;

  Prompt({
    required this.title,
    required this.content,
    required this.category,
    this.selected = false,
    String? id,
  }) : id = id ?? _generateId();

  // Other methods and properties...

  static String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  factory Prompt.fromJson(Map<String, dynamic> json) {
    return Prompt(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      category: json['category'],
      selected: json['selected'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'category': category,
    'selected': selected,
  };

  @override
  String toString() {
    return 'Prompt{id: $id, title: $title, content: $content, category: $category, selected: $selected}';
  }

  // Future<void> _loadPrompts() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   String? json = prefs.getString('promptList');
  //   if (json != null) {
  //     List<dynamic> data = jsonDecode(json);
  //     setState(() {
  //       _prompts = data
  //           .map((item) => Prompt.fromJson(item as Map<String, dynamic>))
  //           .toList();
  //     });
  //   }
  // }
}


class PromptStorage {
  final SharedPreferences _prefs;

  PromptStorage({required SharedPreferences prefs}) : _prefs = prefs;

  List<Prompt> loadPrompts() {
    final String? json = _prefs.getString(Constants.cachePromptKey);
    if (json == null) {
      return [];
    }

    final List<dynamic> data = jsonDecode(json);
    final List<Prompt> prompts =
    data.map((item) => Prompt.fromJson(item)).toList(growable: false);
    prompts.sort((a, b) => b.id.compareTo(a.id));

    return prompts;
  }

  void selectPrompt(List<Prompt> prompts, String id) {
    for (var prompt in prompts) {
      if (prompt.id == id) {
        prompt.selected = true;
      } else {
        prompt.selected = false;
      }
    }

    savePrompts(prompts);
  }

  void savePrompts(List<Prompt> prompts) {
    final List<Map<String, dynamic>> data =
    prompts.map((prompt) => prompt.toJson()).toList(growable: false);
    final String json = jsonEncode(data);
    _prefs.setString(Constants.cachePromptKey, json);
  }

  Prompt getSelectedPrompt() {
    final prompts = loadPrompts();
    return prompts.firstWhere((prompt) => prompt.selected, orElse: () => Prompt(id: "-1", title: "Default Prompt", content: Constants.defaultPrompt, category: "default"));
  }
}
