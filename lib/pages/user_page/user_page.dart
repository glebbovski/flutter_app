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
  final TextEditingController colorController = TextEditingController();
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
      setState(() {
        email = data['email'];
        firstNameController.text = data['first_name'];
        lastNameController.text = data['last_name'];
        _sexFullValue = data['sex'] == 'M' ? 'Male' : 'Female';
        dateController.text = data['date_of_birth'];
        prefs.setInt('user_id', data['user_id']);
      });
    } else {
      // Обработка ошибки
    }
  }

  Future<void> saveChanges() async {
    // Здесь делаем запрос к серверу для сохранения изменений
    // В качестве примера просто выводим данные в консоль
    print('First Name: ${firstNameController.text}');
    print('Last Name: ${lastNameController.text}');
    print('Sex: $_sexFullValue');
    print('Date of Birth: ${dateController.text}');

    var newAttrs = {
      'first_name': firstNameController.text,
      'last_name': lastNameController.text,
      'sex': _sexFullValue?[0],
      'date_of_birth': dateController.text
    };

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access') ?? '';
    int? userId = prefs.getInt('user_id') ?? 0;
    final url = Uri.parse(
        '${Constants.BACKEND_URL}/api/users/$userId/');
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
        title: Text('User Profile'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: firstNameController,
              decoration: InputDecoration(labelText: 'First Name'),
            ),
            TextFormField(
              controller: lastNameController,
              decoration: InputDecoration(labelText: 'Last Name'),
            ),
            TextFormField(
              controller: TextEditingController(text: email),
              readOnly: true,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            // TextFormField(
            //   controller: sexController,
            //   decoration: InputDecoration(labelText: 'Sex'),
            // ),
            const SizedBox(height: 16.0),
            DropdownButton(
              hint: _sexFullValue == null
                  ? Text('Dropdown')
                  : Text(
                _sexFullValue!,
                style: TextStyle(color: Colors.black),
              ),
              isExpanded: true,
              iconSize: 30.0,
              style: TextStyle(color: Colors.black),
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
            // TextFormField(
            //   controller: dateController,
            //   decoration: InputDecoration(labelText: 'Date of Birth'),
            // ),
            TextField(
              controller: dateController, //editing controller of this TextField
              decoration: const InputDecoration(

                  // icon: Icon(Icons.calendar_today), //icon of text field
                  labelText: "Date Of Birth" //label text of field
              ),
              readOnly: true,  // when true user cannot edit text
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(), //get today's date
                    firstDate: DateTime(2000), //DateTime.now() - not to allow to choose before today.
                    lastDate: DateTime(2101)
                );

                if(pickedDate != null ){
                  print(pickedDate);  //get the picked date in the format => 2022-07-04 00:00:00.000
                  String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate); // format date in required form here we use yyyy-MM-dd that means time is removed
                  print(formattedDate); //formatted date output using intl package =>  2022-07-04
                  //You can format date as per your need

                  setState(() {
                    dateController.text = formattedDate; //set foratted date to TextField value.
                  });
                } else {
                  print("Date is not selected");
                }
              },
            ),
            SizedBox(height: 16.0),
            Center(
              child: ElevatedButton(
                onPressed: saveChanges,
                child: Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
