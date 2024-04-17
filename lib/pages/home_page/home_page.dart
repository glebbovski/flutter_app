import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:learning_flutter/pages/courses_page/courses_page.dart';
import 'package:learning_flutter/pages/login_page/login_page.dart';
import 'package:learning_flutter/pages/user_page/user_page.dart';
import 'package:learning_flutter/pages/websocket_chat_page/websocket_chat_page.dart';
import 'package:learning_flutter/widgets/my_card_widget.dart';
import '../../assets/constants.dart' as Constants;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../about_page/about_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final refreshTokenUrl =
        Uri.parse("${Constants.BACKEND_URL}/api/token/refresh/");
    final refreshResponse = await http
        .post(refreshTokenUrl, body: {'refresh': prefs.getString('refresh')});

    if (refreshResponse.statusCode == 200) {
      final data = json.decode(refreshResponse.body);
      prefs.setString('access', data['access']);
      prefs.setString('refresh', data['refresh']);
    }

    String accessToken = prefs.getString('access') ?? '';

    final logoutUrl = Uri.parse("${Constants.BACKEND_URL}/api/logout/");
    final logoutResponse = await http.post(logoutUrl,
        body: {'refresh': prefs.getString('refresh')},
        headers: {'Authorization': 'Bearer $accessToken'});

    if (logoutResponse.statusCode == 200) {
      prefs.remove('refresh');
      prefs.remove('access');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      MyCardWidget(
                        text: 'About',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AboutPage(),
                          ),
                        ),
                      ),
                      MyCardWidget(
                        text: 'Profile',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserPage(),
                          ),
                        ),
                      ),
                      MyCardWidget(
                        text: 'Websocket\nChat Page',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WebsocketChatPage(),
                          ),
                        ),
                      ),
                      MyCardWidget(
                        text: 'Courses Page',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CoursesPage(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  _logout();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            LoginPage()), // Замените NextPage() на вашу страницу
                  );
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(80.0)),
                  padding: const EdgeInsets.all(0.0),
                ),
                child: Ink(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment(0.8, 1),
                      colors: <Color>[
                        Color(0xff1f005c),
                        Color(0xff5b0060),
                        Color(0xff870160),
                        Color(0xffac255e),
                        Color(0xffca485c),
                        Color(0xffe16b5c),
                        Color(0xfff39060),
                        Color(0xffffb56b),
                      ],
                      tileMode: TileMode.mirror,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(80.0)),
                  ),
                  child: Container(
                    constraints: const BoxConstraints(
                        minWidth: 88.0,
                        minHeight:
                            36.0), // минимальные размеры для Material кнопок
                    alignment: Alignment.center,
                    child: const Text(
                      'Log Out',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
