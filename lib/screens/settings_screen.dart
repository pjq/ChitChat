// ignore_for_file: library_private_types_in_public_api

import 'package:about/about.dart';
import 'package:chitchat/models/constants.dart';
import 'package:chitchat/models/global_data.dart';
import 'package:chitchat/models/pubspec.dart';
import 'package:chitchat/utils/log_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:velocity_x/velocity_x.dart';

import '../models/colors.dart';

class SettingsScreen extends StatefulWidget {
  final SharedPreferences prefs;
  final Function onSettingsChanged;

  const SettingsScreen(
      {Key? key, required this.prefs, required this.onSettingsChanged})
      : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _apiKeyController;
  late TextEditingController _promptStringController;
  late TextEditingController _temperatureValueController;
  late TextEditingController
      _proxyUrlController; // new controller for proxy URL
  late TextEditingController _baseUrlController; //
  late TextEditingController _btpKeyJson; //
  late bool _continueConversationEnable;
  late bool _localCacheEnable;
  late bool _ttsEnable;
  late bool _streamModeEnable;
  late bool _enableEnterKeyToSend;
  late bool _useOpenAI;
  late bool _useBTP;

  late String? _ttsSelectedLanguage;
  late LocaleName? _sttSelectedLanguage;
  late AppLocalizations loc;

  late List<String> models;
  late String _selectedModel;

  @override
  void initState() {
    super.initState();

    // If the temperature value has not been set, set it to 1.0
    if (widget.prefs.getDouble(Constants.temperatureValueKey) == 0.0) {
      widget.prefs.setDouble(Constants.temperatureValueKey, 1.0);
    }

    _apiKeyController = TextEditingController(
        text: widget.prefs.getString(Constants.apiKeyKey));
    _promptStringController = TextEditingController(
        text: widget.prefs.getString(Constants.promptStringKey));
    _temperatureValueController = TextEditingController(
      text: widget.prefs.getDouble(Constants.temperatureValueKey) == null
          ? "1.0"
          : widget.prefs.getDouble(Constants.temperatureValueKey).toString(),
    );
    _continueConversationEnable =
        widget.prefs.getBool(Constants.continueConversationEnableKey) ??
            Constants.defaultContinueConversationEnable;
    _localCacheEnable = widget.prefs.getBool(Constants.localCacheEnableKey) ??
        Constants.defaultLocalCacheEnable;
    _ttsEnable = widget.prefs.getBool(Constants.ttsEnableKey) ??
        Constants.defaultTtsEnable;
    _streamModeEnable = widget.prefs.getBool(Constants.streamModeEnableKey) ??
        Constants.defaultStreamModeEnable;
    _enableEnterKeyToSend =
        widget.prefs.getBool(Constants.enableEnterKeyToSendKey) ??
            Constants.defaultEnableEnterKeyToSend;

    _proxyUrlController = TextEditingController(
        text: widget.prefs.getString(Constants.proxyUrlKey));

    _baseUrlController = TextEditingController(
        text: widget.prefs.getString(Constants.baseUrlKey));

    _btpKeyJson = TextEditingController(
        text: widget.prefs.getString(Constants.btpKeyJson));

    String? selected = widget.prefs.getString(Constants.ttsSelectedLanguageKey);
    _ttsSelectedLanguage =
        (selected != null && selected.isNotEmpty) ? selected : null;
    LogUtils.debug("$_ttsSelectedLanguage");

    if (GlobalData().sttLocaleNames.isNotEmpty) {
      String? savedSttSelectedLanguage =
          widget.prefs.getString(Constants.sttSelectedLanguageKey);
      _sttSelectedLanguage = GlobalData().sttLocaleNames.firstWhere(
            (element) => savedSttSelectedLanguage == element.localeId,
            orElse: () => GlobalData().sttLocaleNames[0], // Set a default value
          );

      LogUtils.debug("selected: ${_sttSelectedLanguage?.localeId}");
    } else {
      _sttSelectedLanguage = null;
    }

    models = widget.prefs.getStringList('models') ?? Constants.models;
    _selectedModel = widget.prefs.getString(Constants.selectedModelKey) ??
        Constants.defaultAIModel;
    if (!Constants.models.contains(_selectedModel)) {
      _selectedModel = Constants.defaultAIModel;
    }

    _useOpenAI = widget.prefs.getBool(Constants.useOpenAI) ?? true;
    _useBTP = widget.prefs.getBool(Constants.useBTP) ?? false;
  }

  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _saveSettings(false);
    }
  }

  void _saveSettings(bool back) {
    widget.prefs.setString(Constants.apiKeyKey, _apiKeyController.text);
    widget.prefs
        .setString(Constants.promptStringKey, _promptStringController.text);
    widget.prefs.setDouble(Constants.temperatureValueKey,
        double.parse(_temperatureValueController.text));
    widget.prefs.setBool(
        Constants.continueConversationEnableKey, _continueConversationEnable);
    widget.prefs.setBool(Constants.localCacheEnableKey, _localCacheEnable);
    widget.prefs.setBool(Constants.ttsEnableKey, _ttsEnable);
    widget.prefs.setBool(Constants.streamModeEnableKey, _streamModeEnable);
    widget.prefs
        .setBool(Constants.enableEnterKeyToSendKey, _enableEnterKeyToSend);
    widget.prefs.setString(Constants.proxyUrlKey, _proxyUrlController.text);
    widget.prefs.setString(Constants.baseUrlKey, _baseUrlController.text);
    widget.prefs.setString(Constants.btpKeyJson, _btpKeyJson.text);

    widget.prefs.setString(
        Constants.ttsSelectedLanguageKey, _ttsSelectedLanguage ?? "");

    if (null != _sttSelectedLanguage) {
      widget.prefs.setString(
          Constants.sttSelectedLanguageKey, _sttSelectedLanguage!.localeId);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.settings_saved),
        duration: const Duration(milliseconds: 1000),
      ),
    );

    if (back) {
      Navigator.pop(context);
    }
    widget.onSettingsChanged();

    LogUtils.debug("useOpenAI: $_useOpenAI, useBTP: $_useBTP");
    widget.prefs.setBool(Constants.useOpenAI, _useOpenAI);
    widget.prefs.setBool(Constants.useBTP, _useBTP);
  }

  void _showAddModelDialog() {
    final TextEditingController _newModelController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Model'),
          content: TextField(
            controller: _newModelController,
            decoration: InputDecoration(hintText: "Enter model name"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Add'),
              onPressed: () {
                addModel(_newModelController.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void addModel(String newModel) {
    setState(() {
      models.add(newModel);
      widget.prefs.setStringList('models', models);
    });
  }

  // void _clearChatHistory() {
  //   // Clear the chat history from the shared preferences
  //   widget.prefs.remove(Constants.cacheHistoryKey);

  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text(loc.conversationRecordsErased),
  //     ),
  //   );
  // }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool enable = true,
    bool passwordField = false,
  }) {
    return TextFormField(
      obscureText: passwordField,
      enabled: enable,
      controller: controller,
      cursorColor: passwordField ? Theme.of(context).canvasColor : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    loc = AppLocalizations.of(context)!; // Add this line
    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.settings,
          style: TextStyle(
              fontSize: MyColors
                  .TEXT_SIZE_TITLE), // Change the value to adjust the size
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _saveSettings(true),
            tooltip: loc.save,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                controller: _apiKeyController,
                label: loc.openAIApiKey,
                passwordField: true,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _baseUrlController, // add text field for baseURL
                label: loc.openAIBaseUrl,
              ),
              // const SizedBox(height: 16),
              // _buildTextField(
              //   enable: false,
              //   controller: _promptStringController,
              //   label: loc.promptString,
              // ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _temperatureValueController,
                label: loc.temperatureValue,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loc.selectModel),
                      _buildModelDropdown(),
                    ],
                  ),
                  FloatingActionButton(
                    onPressed: _showAddModelDialog,
                    tooltip: 'Add Model',
                    child: Icon(Icons.add),
                  ),
                ],
              ),
              CheckboxListTile(
                title: Text(loc.enable_stream_mode),
                value: _streamModeEnable,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
                onChanged: (value) {
                  setState(() {
                    _streamModeEnable = value!;
                    _saveSettings(false);
                  });
                },
              ),
              // const SizedBox(height: 16),
              CheckboxListTile(
                title: Text(loc.continueConversation),
                value: _continueConversationEnable,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
                onChanged: (value) {
                  setState(() {
                    _continueConversationEnable = value!;
                    _saveSettings(false);
                  });
                },
              ),
              CheckboxListTile(
                title: Text(loc.localCache),
                value: _localCacheEnable,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
                onChanged: (value) {
                  setState(() {
                    _localCacheEnable = value!;
                    _saveSettings(false);
                  });
                },
              ),
              CheckboxListTile(
                title: Text(loc.enableTts),
                value: _ttsEnable,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
                onChanged: (value) {
                  setState(() {
                    _ttsEnable = value!;
                    _saveSettings(false);
                  });
                },
              ),
              CheckboxListTile(
                title: Text(loc.enable_enterkey_to_send),
                value: _enableEnterKeyToSend,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
                onChanged: (value) {
                  setState(() {
                    _enableEnterKeyToSend = value!;
                    _saveSettings(false);
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(loc.ttsLanguage),
                          _buildTtsLanguageDropdown(),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(loc.sttLanguage),
                          _buildSttLanguageDropdown(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // const SizedBox(height: 16),
              // ElevatedButton(
              //   onPressed: _clearChatHistory,
              //   child: Text(loc.clearChatHistory),
              // ),
              // const SizedBox(height: 16),
              // _buildTextField(
              //   controller: _proxyUrlController, // add text field for proxy URL
              //   label: loc.proxyUrl,
              // ),

              Container(
                child: Column(
                  children: [
                    Text(loc.switch_between_openai_btp),
                    CheckboxListTile(
                      title: Text('OpenAI'),
                      value: _useOpenAI,
                      onChanged: (value) {
                        setState(() {
                          _useOpenAI = value!;
                          _useBTP = !_useOpenAI;
                          _saveSettings(false);
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: Text('BTP'),
                      value: _useBTP,
                      onChanged: (value) {
                        setState(() {
                          _useBTP = value!;
                          _useOpenAI = !_useBTP;
                          _saveSettings(false);
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              TextField(
                controller: _btpKeyJson, // add text field for baseURL
                decoration: InputDecoration(
                  labelText: loc.paste_your_btp_key,
                ),
                maxLines: null,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _showAbout,
                child: Text(loc.about),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTtsLanguageDropdown() {
    if (GlobalData().ttsLanguages.isEmpty) {
      return Text(loc.noTtsLanguagesAvailable);
    }

    return DropdownButton<String>(
      value: _ttsSelectedLanguage ?? GlobalData().ttsLanguages[0],
      items: GlobalData().ttsLanguages.toSet().map((dynamic value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          if (newValue.isNotEmptyAndNotNull) {
            _ttsSelectedLanguage = newValue!;
            widget.prefs.setString(
                Constants.ttsSelectedLanguageKey, _ttsSelectedLanguage ?? "");
          }
        });
      },
    );
  }

  Widget _buildSttLanguageDropdown() {
    if (GlobalData().sttLocaleNames.isEmpty) {
      return Text(loc.noSttLanguagesAvailable);
    }

    return DropdownButton<LocaleName>(
      isExpanded: true,
      value: _sttSelectedLanguage ?? GlobalData().sttLocaleNames[0],
      items: GlobalData().sttLocaleNames.toSet().map((LocaleName value) {
        return DropdownMenuItem<LocaleName>(
          value: value,
          child: Text(value.name),
        );
      }).toList(),
      onChanged: (LocaleName? newValue) {
        setState(() {
          _sttSelectedLanguage = newValue!;

          if (null != _sttSelectedLanguage) {
            LogUtils.debug("selected stt: ${_sttSelectedLanguage!.localeId}");
            widget.prefs.setString(Constants.sttSelectedLanguageKey,
                _sttSelectedLanguage!.localeId);
          }
        });
      },
    );
  }

  Widget _buildModelDropdown() {
    return DropdownButton<String>(
      value: _selectedModel,
      items: models.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedModel = newValue!;
          widget.prefs.setString(Constants.selectedModelKey, _selectedModel);
        });
      },
    );
  }

  void _showAbout() {
    PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
      setState(() {
        String version = packageInfo.version;
        String buildNumber = packageInfo.buildNumber;
        // You can also get other details like app name and package name
        // from packageInfo, if needed.

        showAboutPage(
          context: context,
          values: {
            'version': "$version+$buildNumber",
            'year': DateTime.now().year.toString(),
          },
          applicationLegalese:
              'Copyright © ${Pubspec.authorsName.join(', ')}, {{ year }}',
          applicationDescription: Text(Pubspec.description),
          children: const <Widget>[
            MarkdownPageListTile(
              icon: Icon(Icons.list),
              title: Text('Changelog'),
              filename: 'assets/CHANGELOG.md',
            ),
            LicensesPageListTile(
              icon: Icon(Icons.favorite),
            ),
          ],
          applicationIcon: const SizedBox(
            width: 100,
            height: 100,
            child: Image(
              image: AssetImage(
                  'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png'),
            ),
          ),
        );
      });
    });
  }
}
