import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../assets/constants.dart' as Constants;
import 'package:http/http.dart' as http;


class AboutPage extends StatefulWidget {
  @override
  _AboutPageState createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String creator = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access');

    if (accessToken != null) {
      final refreshTokenUrl = Uri.parse("${Constants.BACKEND_URL}/api/token/refresh/");
      final refreshResponse = await http.post(
        refreshTokenUrl,
        body: {'refresh': prefs.getString('refresh')}
      );


      if (refreshResponse.statusCode == 200) {
        final data = json.decode(refreshResponse.body);
        prefs.setString('access', data['access']);
        prefs.setString('refresh', data['refresh']);
      }

      accessToken = prefs.getString('access');

      final url = Uri.parse("${Constants.BACKEND_URL}/api/about/");
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(data);
        setState(() {
          creator = data['creator'];
        });
      } else {
        // Обработка ошибки
      }
    } else {
      // Обработка случая, когда токен доступа отсутствует
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Creator:',
              style: TextStyle(fontSize: 20),
            ),
            Text(
              creator,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}