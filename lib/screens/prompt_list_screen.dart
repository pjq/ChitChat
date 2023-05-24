
// ignore_for_file: library_private_types_in_public_api

import 'package:chitchat/models/colors.dart';
import 'package:chitchat/utils/Utils.dart';
import 'package:flutter/material.dart';
import 'package:chitchat/models/prompt.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:chitchat/models/constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/chat_message.dart';

class PromptListScreen extends StatefulWidget {
  final Function(Prompt) onSelectedPrompt;
  final PromptStorage promptStorage;
  final ChatHistory history;

  const PromptListScreen(
      {required this.onSelectedPrompt, required this.promptStorage, required this.history, super.key});

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

  void _addDefaultPrompt() {
    List<Prompt> allPrompts = widget.promptStorage.loadPrompts();
    if (allPrompts.isEmpty) {
      //add the default prompts
      Prompt newPrompt = Prompt(
        id: "-1",
        title: loc.default_prompt_category,
        content: loc.you_are_my_assistant,
        category: loc.default_prompt_category,
        selected: true,
      );

      widget.promptStorage.savePrompts(_prompts);

      setState(() {
        _prompts.add(newPrompt);
      });
    }
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
    showDialog<Prompt>(
      context: context,
      builder: (context) => _editPromptDialog(newPrompt),
    );
    // _editPromptDialog(newPrompt);
  }

  void _editPrompt(int index, Prompt updatedPrompt) {
    setState(() {
      _prompts[index] = updatedPrompt;
      widget.promptStorage.savePrompts(_prompts);
    });
  }

  @override
  Widget build(BuildContext context) {
    loc = AppLocalizations.of(context)!;
    _addDefaultPrompt();

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.assistants),
      ),
      body: ListView.builder(
        itemCount: _prompts.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_prompts[index].title),
            tileColor: _prompts[index].selected ? MyColors.accent200 : null,
            onTap: () {
              widget.promptStorage.selectPrompt(_prompts, _prompts[index].id);
              setState(() {
                _prompts[index].selected = true;
              });
              widget.onSelectedPrompt(_prompts[index]);
              if(!Utils.isBigScreen()){
                //if it's phone then need to pop
                Navigator.pop(context);
              }
            },
              onLongPress: () async {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => Wrap(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.edit),
                        title: Text(loc.edit_prompt),
                        onTap: () {
                          Navigator.pop(context);
                          final result = showDialog<Prompt>(
                            context: context,
                            builder: (context) => _editPromptDialog(_prompts[index]),
                          );
                          result.then((prompt) {
                            if (prompt != null) {
                              _editPrompt(index, prompt);
                            }
                          });
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.delete),
                        title: Text(loc.delete),
                        onTap: () {
                          Navigator.pop(context);
                          _deletePrompt(index);
                        },
                      ),
                    ],
                  ),
                );
              },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPrompt,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _editPromptDialog(Prompt currentPrompt) {
    final TextEditingController titleController =
        TextEditingController(text: currentPrompt.title);
    final TextEditingController contentController =
        TextEditingController(text: currentPrompt.content);
    final TextEditingController categoryController =
        TextEditingController(text: currentPrompt.category);

    return AlertDialog(
      title: Text(loc.edit_prompt),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: loc.title),
            ),
            TextField(
              controller: contentController,
              decoration: InputDecoration(labelText: loc.content),
            ),
            // TextField(
            //   controller: _categoryController,
            //   decoration: InputDecoration(labelText: loc.category),
            // ),
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
              title: titleController.text,
              content: contentController.text,
              category: categoryController.text,
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
  void _deletePrompt(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.delete),
        content: Text(loc.delete_prompt_confirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () {
              setState(() {
               if( _prompts[index].selected ) {
                 // if remove the selected prompt, then reset to the first prompt
                 widget.promptStorage.selectPrompt(_prompts, _prompts[0].id);
                 widget.onSelectedPrompt(_prompts[0]);
               }

                widget.history.deleteMessageForPromptChannel(_prompts[index].id);
                _prompts.removeAt(index);
              });
              widget.promptStorage.savePrompts(_prompts);
              Navigator.pop(context);
            },
            child: Text(loc.delete),
          ),
        ],
      ),
    );
  }
}
