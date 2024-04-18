import 'dart:convert';
import 'package:flutter/material.dart';
import '../../assets/constants.dart' as Constants;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'course_details_page.dart';

class Course {
  final int id;
  final String title;
  final String description;
  final String imageUrl;
  final String shortHref;
  final String longDescription;

  Course(
      {required this.id,
      required this.title,
      required this.description,
      required this.imageUrl,
      required this.shortHref,
      required this.longDescription});
}

class CoursesPage extends StatefulWidget {
  @override
  _CoursesPageState createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  final List<Course> courses = [];

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

    String accessToken = prefs.getString('access') ?? '';

    final coursesRequest = await http.get(
        Uri.parse("${Constants.BACKEND_URL}/api/courses/"),
        headers: {'Authorization': 'Bearer $accessToken'});

    final List<Course> coursesToPush = [];

    if (coursesRequest.statusCode == 200) {
      var coursesData = json.decode(coursesRequest.body);
      for (int i = 0; i < coursesData.length; i++) {
        coursesToPush.add(Course(
            id: coursesData[i]['id'],
            title: coursesData[i]['title'],
            description: coursesData[i]['description'],
            imageUrl: coursesData[i]['url_for_image'],
            shortHref: coursesData[i]['short_href'],
            longDescription: coursesData[i]['long_description']));
      }

      setState(() {
        courses.addAll(coursesToPush);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Courses'),
      ),
      body: ListView.builder(
        itemCount: courses.length,
        itemBuilder: (context, index) {
          final course = courses[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CourseDetailsPage(course: course),
                  ),
                );
              },
              title: Text(
                course.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(course.description),
              trailing: const Icon(Icons.arrow_forward),
            ),
          );
        },
      ),
    );
  }
}
