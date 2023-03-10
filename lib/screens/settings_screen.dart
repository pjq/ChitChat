import 'package:flutter/material.dart';
import 'package:chitchat/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  final SharedPreferences prefs;

  const SettingsScreen({Key? key, required this.prefs}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _apiKeyController;
  late TextEditingController _promptStringController;
  late TextEditingController _temperatureValueController;
  late TextEditingController _proxyUrlController; // new controller for proxy URL
  late TextEditingController _baseUrlController; //
  late bool _continueConversationEnable;
  late bool _localCacheEnable;

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

    _proxyUrlController = TextEditingController(
        text: widget.prefs.getString(Constants.proxyUrlKey));

    _baseUrlController = TextEditingController(
        text: widget.prefs.getString(Constants.baseUrlKey));
  }

  void _saveSettings() {
    widget.prefs.setString(Constants.apiKeyKey, _apiKeyController.text);
    widget.prefs
        .setString(Constants.promptStringKey, _promptStringController.text);
    widget.prefs.setDouble(Constants.temperatureValueKey,
        double.parse(_temperatureValueController.text));
    widget.prefs.setBool(
        Constants.continueConversationEnableKey, _continueConversationEnable);
    widget.prefs.setBool(Constants.localCacheEnableKey, _localCacheEnable);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Settings saved'),
      ),
    );
    widget.prefs.setString(Constants.proxyUrlKey, _proxyUrlController.text);
    widget.prefs.setString(Constants.baseUrlKey, _baseUrlController.text);

    Navigator.pop(context);
  }
  void _clearChatHistory() {
    // Clear the chat history from the shared preferences
    widget.prefs.remove(Constants.cacheHistoryKey);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Conversation records erased, you may restart the App.'),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                controller: _apiKeyController,
                label: 'OpenAI API Key',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _promptStringController,
                label: 'Prompt String',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _temperatureValueController,
                label: 'Temperature Value(0-1.0)',
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: Text('Continue Conversation'),
                value: _continueConversationEnable,
                onChanged: (value) {
                  setState(() {
                    _continueConversationEnable = value!;
                  });
                },
              ),
              CheckboxListTile(
                title: Text('Local Cache'),
                value: _localCacheEnable,
                onChanged: (value) {
                  setState(() {
                    _localCacheEnable = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _clearChatHistory,
                child: Text('Clear Chat History'),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _proxyUrlController, // add text field for proxy URL
                label: 'Proxy(host:port)',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _baseUrlController, // add text field for proxy URL
                label: 'OpenAI Base URL',
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveSettings,
                child: Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
