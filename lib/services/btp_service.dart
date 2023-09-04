import 'dart:convert';
import 'package:chitchat/models/constants.dart';
import 'package:chitchat/utils/log_utils.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BTPService {
  final String keyPath = 'assets/key.json'; // specify the path to your key.json

  Future<Map<String, dynamic>> loadKey() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? btpJsonKey = prefs.getString(Constants.btpKeyJson);
    try {
      String jsonString = await rootBundle.loadString(keyPath);
      return jsonDecode(jsonString);
    } catch (e) {
      if (btpJsonKey != null) {
        return jsonDecode(btpJsonKey);
      } else {
        throw Exception('Key file not found and no key in preferences');
      }
    }
  }

  Future<http.Response> getToken(Map<String, dynamic> svcKey) async {
    LogUtils.info("getToken");
    String uaaUrl = svcKey['uaa']['url'];
    String clientId = svcKey['uaa']['clientid'];
    String clientSecret = svcKey['uaa']['clientsecret'];

    var response = await http.post(
      Uri.parse('$uaaUrl/oauth/token'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization':
            'Basic ' + base64Encode(utf8.encode('$clientId:$clientSecret')),
      },
      body: {
        'grant_type': 'client_credentials',
      },
      encoding: Encoding.getByName('utf-8'),
    );

    if (response.statusCode == 200) {
      return response;
    } else {
      throw Exception('Failed to load token');
    }
  }

  Future<http.Response> makeRequest(Map<String, dynamic> data) async {
    LogUtils.info("makeRequest");
    Map<String, dynamic> mySvcKey = await loadKey();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? btp_token = prefs.getString('btp_token');
    int? tokenSavedTime = prefs.getInt('token_saved_time');
    int currentTime = DateTime.now().millisecondsSinceEpoch;
    if (btp_token == null ||
        tokenSavedTime == null ||
        currentTime - tokenSavedTime >=
            jsonDecode(btp_token)['expires_in'] * 1000) {
      Response response = await getToken(mySvcKey);
      //  'expires_in': 43199,
      // 'access_token': 'xxxxxxx'
      if (response.statusCode == 200) {
        prefs.setString('btp_token', response.body);
        prefs.setInt('token_saved_time', currentTime);
        btp_token = response.body;
      }
    }
    String myToken = jsonDecode(btp_token!)['access_token'];

    LogUtils.info("myToken: $myToken");

    var headers = {
      'Authorization': 'Bearer $myToken',
      'Content-Type': 'application/json',
    };

    var response = await http.post(
      Uri.parse('${mySvcKey["url"]}/api/v1/completions'),
      headers: headers,
      body: jsonEncode(data),
    );

    LogUtils.info("${response.statusCode}");
    LogUtils.info("${response.body}");

    return response;
  }

  Future<String> getCompletionRawByBTP(Map<String, dynamic> data) async {
    LogUtils.info("getCompletionRawByBTP");
    var response = await makeRequest(data);
    if (response.statusCode == 200) {
      String responseString = response.body;
      // LogUtils.info("getCompletionRawByBTP: $responseString");
      final completion =
          jsonDecode(responseString)['choices'][0]['message']['content'];
      LogUtils.info("getCompletionRawByBTP: $completion");
      return completion;
    } else {
      throw Exception('Failed to load token');
    }
  }
}
