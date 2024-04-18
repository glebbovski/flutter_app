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
  TextEditingController _creatorController = TextEditingController();
  TextEditingController _bornCityController = TextEditingController();
  TextEditingController _aboutProjectController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access');

    if (accessToken != null) {
      final refreshTokenUrl =
          Uri.parse("${Constants.BACKEND_URL}/api/token/refresh/");
      final refreshResponse = await http
          .post(refreshTokenUrl, body: {'refresh': prefs.getString('refresh')});

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
        setState(() {
          _creatorController.text = data['creator'];
          _aboutProjectController.text = data['about_project'];
          _bornCityController.text = data['born_city'];
        });
      } else {

      }
    } else {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About Page'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _creatorController,
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Creator'),
            ),
            TextFormField(
              controller: _bornCityController,
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Born City'),
            ),
            TextFormField(
              controller: _aboutProjectController,
              readOnly: true,
              decoration: InputDecoration(labelText: 'About Project'),
            ),
          ],
        ),
      ),
    );
  }
}
