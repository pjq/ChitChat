import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:chitchat/models/prompt.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chitchat/models/prompt.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:chitchat/constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PromptListScreen extends StatefulWidget {
  final Function(Prompt) onSelectedPrompt;
  final PromptStorage promptStorage;

  PromptListScreen(
      {required this.onSelectedPrompt, required this.promptStorage});

  @override
  _PromptListScreenState createState() => _PromptListScreenState();
}

class _PromptListScreenState extends State<PromptListScreen> {
  List<Prompt> _prompts = [];
  late AppLocalizations loc;

  @override
  void initState() {
    super.initState();

    _prompts = _prompts.addAllT(widget.promptStorage.loadPrompts());
  }

  void _addPrompt() {
    String newId = DateTime.now().toIso8601String();
    Prompt newPrompt = Prompt(
      id: newId,
      title: loc.prompt_number((_prompts.length + 1).toString()),
      // Replace with localized string
      content: Constants.defaultPrompt,
      category: loc.default_prompt_category,
    );
    // _prompts.add(newPrompt);
    // widget.promptStorage.savePrompts(_prompts);
    final result = showDialog<Prompt>(
      context: context,
      builder: (context) => _editPromptDialog(newPrompt),
    );
    // _editPromptDialog(newPrompt);
  }

  // Future<void> _handleAddPrompt() async {
  //   Prompt p = Prompt();
  //   _prompts.add(Prompt(
  //     id: newId,
  //     title: 'Prompt ${_prompts.length + 1}',
  //     content: '',
  //     category: 'Default',
  //   ));
  //
  //   _editPromptDialog();
  //
  //   if (result == true) {
  //     setState(() {
  //       widget.promptStorage.addPrompt(
  //         Prompt(
  //           id: newPromptId,
  //           title: newPromptTitle,
  //           content: newPromptContent,
  //           category: newPromptCategory,
  //           selected: false,
  //         ),
  //       );
  //     });
  //   }
  // }

  void _editPrompt(int index, Prompt updatedPrompt) {
    setState(() {
      _prompts[index] = updatedPrompt;
      widget.promptStorage.savePrompts(_prompts);
    });
  }

  @override
  Widget build(BuildContext context) {
    loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc!.assistants),
      ),
      body: ListView.builder(
        itemCount: _prompts.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_prompts[index].title),
            tileColor: _prompts[index].selected ? Colors.green[100] : null,
            onTap: () {
              widget.promptStorage.selectPrompt(_prompts, _prompts[index].id);
              widget.onSelectedPrompt(_prompts[index]);
              Navigator.pop(context);
            },
            onLongPress: () async {
              final result = await showDialog<Prompt>(
                context: context,
                builder: (context) => _editPromptDialog(_prompts[index]),
              );
              if (result != null) {
                _editPrompt(index, result);
              }
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPrompt,
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _editPromptDialog(Prompt currentPrompt) {
    final TextEditingController _titleController =
        TextEditingController(text: currentPrompt.title);
    final TextEditingController _contentController =
        TextEditingController(text: currentPrompt.content);
    final TextEditingController _categoryController =
        TextEditingController(text: currentPrompt.category);

    return AlertDialog(
      title: Text(loc.edit_prompt),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: loc.title),
            ),
            TextField(
              controller: _contentController,
              decoration: InputDecoration(labelText: loc.content),
            ),
            TextField(
              controller: _categoryController,
              decoration: InputDecoration(labelText: loc.category),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.cancel),
        ),
        TextButton(
          onPressed: () {
            // currentPrompt.selected = true;
            Prompt updatedPrompt = Prompt(
              id: currentPrompt.id,
              title: _titleController.text,
              content: _contentController.text,
              category: _categoryController.text,
              selected: currentPrompt.selected,
            );
            _updatePrompt(updatedPrompt);
            Navigator.pop(context);
          },
          child: Text(loc.save),
        ),
      ],
    );
  }

  void _updatePrompt(Prompt updatedPrompt) {
    int index = _prompts.indexWhere((prompt) => prompt.id == updatedPrompt.id);
    if (index != -1) {
      setState(() {
        _prompts[index] = updatedPrompt;
      });

      widget.promptStorage.savePrompts(_prompts);
    } else {
      // if doesn't exist,save it.
      widget.promptStorage.savePrompts(_prompts);
      setState(() {
        _prompts.add(updatedPrompt);
      });
    }
  }
}
