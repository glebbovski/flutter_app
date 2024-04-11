
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../assets/constants.dart' as Constants;

class WebsocketChatPage extends StatefulWidget {
  @override
  _WebsocketChatPageState createState() => _WebsocketChatPageState();
}

class _WebsocketChatPageState extends State<WebsocketChatPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _controller = TextEditingController();
  WebSocketChannel? _channel;
  String? username;
  int? userId;
  String room = 'chatroom';

  List<String> messages = [
    // Добавьте свои сообщения здесь
  ];

  @override
  void initState() {
    super.initState();
    _connectToWebSocket();
  }


  Future<void> _connectToWebSocket() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String backendUrl = '192.168.1.107:8000';

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

    String refreshToken = prefs.getString('refresh') ?? '';
    final url = Uri.parse(
        "${Constants.BACKEND_URL}/api/get_info_by_token/$refreshToken");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      username = data['username'];
      userId = data['user_id'];
    } else {
      // Обработка ошибки
    }

    String accessToken = prefs.getString('access') ?? '';
    String websocketUrl = 'ws://$backendUrl/ws/$room/?token=$accessToken';
    _channel = IOWebSocketChannel.connect(websocketUrl);

    List<String> newMessages = [
      // Добавьте свои сообщения здесь
    ];

    final chatMessagesGetRequest = await http.get(Uri.parse("${Constants.BACKEND_URL}"
        "/api/chatmessages/?room=$room"),
        headers: {'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json' }
    );

    if (chatMessagesGetRequest.statusCode == 200) {
      var dataChatMessages = json.decode(chatMessagesGetRequest.body);
      final usersGetRequest = await http.get(Uri.parse("${Constants.BACKEND_URL}/api/users/"),
          headers: {'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json' }
      );
      if (usersGetRequest.statusCode == 200) {
        final Map<int, String> mapForUsers = {
        };
        // final Map<, int> mapForChatMessages = {
        // };
        var dataUsers = json.decode(usersGetRequest.body);
        for (int i = 0; i < dataUsers.length; i++) {
          mapForUsers[dataUsers[i]['id']] = dataUsers[i]['username'];
          // print(dataUsers[i]['username']);
        }

        for (int i = 0; i < dataChatMessages.length; i++) {
          // mapForChatMessages[dataChatMessages[i]['user']] = dataChatMessages[i]['content'];
          newMessages.add("${mapForUsers[dataChatMessages[i]['user']]}: ${dataChatMessages[i]['content']}");
        }

        setState(() {
          messages.clear();
          messages.addAll(newMessages);
        });

        _listenToWebSocket();

      }
    }
  }

  void _listenToWebSocket() {
    _channel?.stream.listen(
          (message) {
        // Обработка полученного сообщения
        // showMessage('Received: $message');
            var receivedData = jsonDecode(message);
            setState(() {
              messages.add(receivedData['username'] + ": " + receivedData['message']);
            });
      },
      onError: (error) {
        // Обработка ошибок при получении сообщений
        showMessage('Error: $error');
      },
      onDone: () {
        // Обработка завершения WebSocket соединения
        showMessage('WebSocket connection closed');
      },
    );
  }

  void showMessage(String message) {
    print(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Список сообщений
                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(messages[index]),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(labelText: 'Send a message'),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {

                      Map<String, dynamic> json = {
                        'message': _controller.text,
                        'username': username,
                        'user_id': userId,
                        'room': room
                      };

                      _channel?.sink.add(jsonEncode(json));
                      // setState(() {
                      //   messages.add('$username: ${_controller.text}');
                      // });
                      _controller.clear();
                    }
                  },
                  child: Text('Send'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }
}