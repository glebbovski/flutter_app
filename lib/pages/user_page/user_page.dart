import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../assets/constants.dart' as Constants;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

final List<String> genderItems = [
  'Male',
  'Female',
];

class UserPage extends StatefulWidget {
  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  String? _sexFullValue;
  String email = '';
  var sex = '';

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
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

    String refreshToken = prefs.getString('refresh') ?? '';
    final url = Uri.parse(
        "${Constants.BACKEND_URL}/api/get_info_by_token/$refreshToken");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        email = data['email'];
        firstNameController.text = data['first_name'];
        lastNameController.text = data['last_name'];
        _sexFullValue = data['sex'] == 'M' ? 'Male' : 'Female';
        dateController.text = data['date_of_birth'];
        prefs.setInt('user_id', data['user_id']);
      });
    } else {}
  }

  Future<void> saveChanges() async {
    var newAttrs = {
      'first_name': firstNameController.text,
      'last_name': lastNameController.text,
      'sex': _sexFullValue?[0],
      'date_of_birth': dateController.text
    };

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access') ?? '';
    int? userId = prefs.getInt('user_id') ?? 0;
    final url = Uri.parse('${Constants.BACKEND_URL}/api/users/$userId/');
    final response = await http.patch(url,
        headers: {'Authorization': 'Bearer $accessToken'}, body: newAttrs);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        email = data['email'];
        firstNameController.text = data['first_name'];
        lastNameController.text = data['last_name'];
        _sexFullValue = data['sex'] == 'M' ? 'Male' : 'Female';
        dateController.text = data['date_of_birth'];
        prefs.setInt('user_id', (data['id'] ?? 0));
      });
    } else {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: firstNameController,
              decoration: const InputDecoration(labelText: 'First Name'),
            ),
            TextFormField(
              controller: lastNameController,
              decoration: const InputDecoration(labelText: 'Last Name'),
            ),
            TextFormField(
              controller: TextEditingController(text: email),
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            // TextFormField(
            //   controller: sexController,
            //   decoration: InputDecoration(labelText: 'Sex'),
            // ),
            const SizedBox(height: 16.0),
            DropdownButton(
              hint: _sexFullValue == null
                  ? const Text('Dropdown')
                  : Text(
                      _sexFullValue!,
                      style: const TextStyle(color: Colors.black),
                    ),
              isExpanded: true,
              underline: const SizedBox(),
              iconSize: 30.0,
              style: const TextStyle(color: Colors.black),
              items: ['Male', 'Female'].map(
                (val) {
                  return DropdownMenuItem<String>(
                    value: val,
                    child: Text(val),
                  );
                },
              ).toList(),
              onChanged: (val) {
                setState(
                  () {
                    _sexFullValue = val;
                  },
                );
              },
            ),
            Divider(height: 1.0, color: Colors.black38.withOpacity(0.5)),
            TextField(
              controller: dateController,
              decoration: const InputDecoration(labelText: "Date Of Birth"),
              readOnly: true,
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101));

                if (pickedDate != null) {
                  String formattedDate =
                      DateFormat('yyyy-MM-dd').format(pickedDate);
                  setState(() {
                    dateController.text = formattedDate;
                  });
                } else {
                  print("Date is not selected");
                }
              },
            ),
            const SizedBox(height: 16.0),
            Center(
              child: ElevatedButton(
                onPressed: saveChanges,
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
