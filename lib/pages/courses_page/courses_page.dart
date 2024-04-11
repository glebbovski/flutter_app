import 'dart:convert';

import 'package:flutter/material.dart';
import '../../assets/constants.dart' as Constants;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Course {
  final int id;
  final String title;
  final String description;
  final String imageUrl;
  final String shortHref;
  final String longDescription;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.shortHref,
    required this.longDescription
  });
}

class CoursesPage extends StatefulWidget {
  @override
  _CoursesPageState createState() => _CoursesPageState();
}


class _CoursesPageState extends State<CoursesPage> {

    final List<Course> courses = [
      // Course(
      //   title: 'Course 1',
      //   description: 'Description for course 1',
      //   imageUrl: 'https://via.placeholder.com/150',
      // ),
      // Course(
      //   title: 'Course 2',
      //   description: 'Description for course 2',
      //   imageUrl: 'https://via.placeholder.com/150',
      // ),
    // Add more courses here
   ];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final refreshTokenUrl = Uri.parse(
        "${Constants.BACKEND_URL}/api/token/refresh/");
    final refreshResponse = await http.post(
        refreshTokenUrl,
        body: {'refresh': prefs.getString('refresh')}
    );


    if (refreshResponse.statusCode == 200) {
      final data = json.decode(refreshResponse.body);
      prefs.setString('access', data['access']);
      prefs.setString('refresh', data['refresh']);
    }

    String accessToken = prefs.getString('access') ?? '';

    final coursesRequest = await http.get(
        Uri.parse("${Constants.BACKEND_URL}/api/courses/"),
        headers: {'Authorization': 'Bearer $accessToken'});

    final List<Course> coursesToPush = [
    ];

    if (coursesRequest.statusCode == 200) {
      var coursesData = json.decode(coursesRequest.body);
      for (int i = 0; i < coursesData.length; i++) {
        coursesToPush.add(Course(id: coursesData[i]['id'],
            title: coursesData[i]['title'],
            description: coursesData[i]['description'],
            imageUrl: coursesData[i]['url_for_image'],
            shortHref: coursesData[i]['short_href'],
            longDescription: coursesData[i]['long_description']
        ));
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
        title: Text('Courses'),
      ),
      body: ListView.builder(
        itemCount: courses.length,
        itemBuilder: (context, index) {
          final course = courses[index];
          return Card(
            margin: EdgeInsets.all(8.0),
            child: ListTile(
              onTap: () {
                // Navigate to course details page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CourseDetailsPage(course: course),
                  ),
                );
              },
              // leading: Image.network(course.imageUrl),
              title: Text(course.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(course.description),
              trailing: Icon(Icons.arrow_forward),
            ),
          );
        },
      ),
    );
  }
}




// class CoursesPage extends StatelessWidget {
//   final List<Course> courses = [
//     Course(
//       title: 'Course 1',
//       description: 'Description for course 1',
//       imageUrl: 'https://via.placeholder.com/150',
//     ),
//     Course(
//       title: 'Course 2',
//       description: 'Description for course 2',
//       imageUrl: 'https://via.placeholder.com/150',
//     ),
//     // Add more courses here
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Courses'),
//       ),
//       body: ListView.builder(
//         itemCount: courses.length,
//         itemBuilder: (context, index) {
//           final course = courses[index];
//           return Card(
//             margin: EdgeInsets.all(8.0),
//             child: ListTile(
//               onTap: () {
//                 // Navigate to course details page
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => CourseDetailsPage(course: course),
//                   ),
//                 );
//               },
//               // leading: Image.network(course.imageUrl),
//               title: Text(course.title),
//               subtitle: Text(course.description),
//               trailing: Icon(Icons.arrow_forward),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
//
class CourseDetailsPage extends StatelessWidget {
  final Course course;

  CourseDetailsPage({required this.course});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(course.title),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              course.title,
              style: const TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.0),
            Text(course.longDescription),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                // Action to take when "Enroll" button is pressed
              },
              child: Text('Enroll'),
            ),
          ],
        ),
      ),
    );
  }
}
