import 'package:flutter/material.dart';
import 'package:learning_flutter/pages/login_page/login_page.dart';
import 'dart:convert';
import './assets/constants.dart' as Constants;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LoginPage(),
    );
  }
}
