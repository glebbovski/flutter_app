import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../assets/constants.dart' as Constants;
import 'package:http/http.dart' as http;
import 'courses_page.dart';

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctAnswerIndex;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
  });
}

class CourseQuestion {
  final int id;
  final String question;
  int? selectedOption;
  bool submitted;
  final int courseId;
  int correctAnswerIndex;
  final List<QuestionAnswer> options;

  CourseQuestion({
    required this.id,
    required this.question,
    required this.selectedOption,
    required this.submitted,
    required this.courseId,
    required this.correctAnswerIndex,
    required this.options,
  });

  @override
  String toString() {
    return 'CourseQuestion{id: $id, question: $question, selectedOption: $selectedOption, submitted: $submitted, correctAnswerIndex: $correctAnswerIndex, courseId: $courseId, options: $options}';
  }
}

class QuestionAnswer {
  final int id;
  final String answer;
  final bool isCorrect;

  QuestionAnswer({
    required this.id,
    required this.answer,
    required this.isCorrect,
  });

  @override
  String toString() {
    return 'QuestionAnswer{id: $id, answer: $answer, isCorrect: $isCorrect}';
  }
}

class CourseDetailsPage extends StatefulWidget {
  final Course course;

  const CourseDetailsPage({super.key, required this.course});

  @override
  _CourseDetailsPageState createState() => _CourseDetailsPageState();
}

class _CourseDetailsPageState extends State<CourseDetailsPage> {

  List<int?> selectedAnswers = [];
  List<CourseQuestion> courseQuestions = [];
  bool isSubmitted = false;
  String? username;
  int? userId;
  String? firstName;
  String? lastName;
  String? email;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      refreshToken().then((_) {
        getCourseQuestions().then((_) {
          getQuestionAnswers().then((_) {
            getPreviousResult();
          });
        });
      });
    });
  }

  Future<void> refreshToken() async {
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
      username = data['username'];
      userId = data['user_id'];
      firstName = data['first_name'];
      lastName = data['last_name'];
      email = data['email'];
    } else {

    }
  }

  Future<void> getCourseQuestions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String accessToken = prefs.getString('access') ?? '';

    List<CourseQuestion> newCourseQuestions = [];

    final courseQuestionsUrl = Uri.parse(
        "${Constants.BACKEND_URL}/api/questions/?course=${widget.course.id}");
    final courseQuestionsResponse = await http.get(courseQuestionsUrl,
        headers: {'Authorization': 'Bearer $accessToken'});

    if (courseQuestionsResponse.statusCode == 200) {
      var data = json.decode(courseQuestionsResponse.body);
      for (int i = 0; i < data.length; i++) {
        newCourseQuestions.add(CourseQuestion(
            id: data[i]['id'],
            question: data[i]['question'],
            selectedOption: null,
            submitted: false,
            courseId: data[i]['course'],
            options: [],
            correctAnswerIndex: -1));
      }
    }

    setState(() {
      courseQuestions.clear();
      courseQuestions.addAll(newCourseQuestions);
      selectedAnswers = List.filled(courseQuestions.length, null);
    });
  }

  Future<void> getQuestionAnswers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String accessToken = prefs.getString('access') ?? '';

    List<CourseQuestion> updatedQuestions =
        List.from(courseQuestions);

    for (int i = 0; i < updatedQuestions.length; i++) {
      final questionAnswersUrl = Uri.parse(
          "${Constants.BACKEND_URL}/api/answers/?question=${courseQuestions[i].id}");
      final questionAnswersResponse = await http.get(questionAnswersUrl,
          headers: {'Authorization': 'Bearer $accessToken'});

      if (questionAnswersResponse.statusCode == 200) {
        var data = json.decode(questionAnswersResponse.body);
        for (int j = 0; j < data.length; j++) {
          updatedQuestions[i].options.add(QuestionAnswer(
              id: data[j]['id'],
              answer: data[j]['answer'],
              isCorrect: data[j]['isRight']));
          if (data[j]['isRight']) {
            updatedQuestions[i].correctAnswerIndex = j;
          }
        }
      }
    }

    setState(() {
      courseQuestions.clear();
      courseQuestions.addAll(updatedQuestions);
    });
  }

  Future<void> getPreviousResult() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String accessToken = prefs.getString('access') ?? '';

    final previousResultUrl = Uri.parse(
        "${Constants.BACKEND_URL}/api/previousresult/?course=${widget.course.id}&user=$userId");

    final previousResultResponse = await http.get(previousResultUrl,
        headers: {'Authorization': 'Bearer $accessToken'});

    if (previousResultResponse.statusCode == 200) {
      var data = json.decode(previousResultResponse.body);
      if (data.length > 0) {
        for (int i = 0; i < data.length; i++) {
          final question_index =
              courseQuestions.indexWhere((q) => q.id == data[i]['question']);

          if (question_index != -1) {
            final question = courseQuestions[question_index];
            for (int j = 0; j < question.options.length; j++) {
              if (question.options[j].id == data[i]['answer']) {
                setState(() {
                  question.selectedOption = j;
                  question.submitted = true;
                  selectedAnswers[question_index] = j;
                });
              }
            }
          }
        }

        setState(() {
          isSubmitted = true;
        });
      }
    }
  }

  Future<void> deleteResultsForRetry() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String accessToken = prefs.getString('access') ?? '';

    final previousResultUrl = Uri.parse(
        "${Constants.BACKEND_URL}/api/previousresult/?course=${widget.course.id}&user=$userId");

    final previousResultResponse = await http.get(previousResultUrl,
        headers: {'Authorization': 'Bearer $accessToken'});

    if (previousResultResponse.statusCode == 200) {
      var data = json.decode(previousResultResponse.body);
      if (data.length > 0) {
        for (int i = 0; i < data.length; i++) {
          final deleteUrl = Uri.parse(
              "${Constants.BACKEND_URL}/api/previousresult/${data[i]['id']}/");
          final deleteResult = await http.delete(deleteUrl,
              headers: {'Authorization': 'Bearer $accessToken'});
        }
      }
    }
  }

  Future<void> pushResults() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String accessToken = prefs.getString('access') ?? '';

    for (int i = 0; i < courseQuestions.length; i++) {
      final pushResultUrl =
          Uri.parse("${Constants.BACKEND_URL}/api/previousresult/");

      final pushResultResponse = await http.post(pushResultUrl, body: {
        "user": userId.toString(),
        "course": widget.course.id.toString(),
        "question": courseQuestions[i].id.toString(),
        "answer": courseQuestions[i].options[selectedAnswers[i]!].id.toString()
      }, headers: {
        'Authorization': 'Bearer $accessToken'
      });
    }
  }

  void handleRadioValueChanged(int? value, int index) {
    if (!isSubmitted) {
      setState(() {
        selectedAnswers[index] = value;
      });
    }
  }

  bool isSubmitButtonEnabled() {
    return !selectedAnswers.contains(null) && !isSubmitted;
  }

  void submitAnswers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    int correctAnswersCount = 0;

    for (int i = 0; i < courseQuestions.length; i++) {
      if (selectedAnswers[i] == courseQuestions[i].correctAnswerIndex) {
        correctAnswersCount++;
      }
    }

    if (correctAnswersCount == courseQuestions.length) {
      final generatePdfUrl =
          Uri.parse("${Constants.BACKEND_URL}/api/generatepdf/");
      String accessToken = prefs.getString('access') ?? '';
      final generatePdfResponse = http.post(generatePdfUrl, body: {
        "name": '${firstName!} ${lastName!}',
        "course": widget.course.title,
        "email": email
      }, headers: {
        'Authorization': 'Bearer $accessToken'
      });
    } else {
      final courseNotFinishedUrl =
          Uri.parse("${Constants.BACKEND_URL}/api/coursenotfinished/");
      String accessToken = prefs.getString('access') ?? '';
      final courseNotFinishedResponse = http.post(courseNotFinishedUrl, body: {
        "name": '${firstName!} ${lastName!}',
        "course": widget.course.title,
        "email": email
      }, headers: {
        'Authorization': 'Bearer $accessToken'
      });
    }

    double percentage = (correctAnswersCount / courseQuestions.length) * 100;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Quiz Results'),
          content: Text(
              'You got $correctAnswersCount out of ${courseQuestions.length} correct! \nPercentage: $percentage%'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );

    setState(() {
      pushResults();
      isSubmitted = true;
    });
  }

  void resetQuiz() {
    setState(() {
      deleteResultsForRetry();
      selectedAnswers = List.filled(courseQuestions.length, null);
      isSubmitted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.course.title} quiz'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.network(widget.course.imageUrl),
            const SizedBox(height: 16.0),
            RichText(
              text: TextSpan(
                children: <TextSpan>[
                  const TextSpan(
                    text: 'Full description: ',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontSize: 16.0),
                  ),
                  TextSpan(
                    text: widget.course.longDescription,
                    style: const TextStyle(color: Colors.black, fontSize: 16.0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: ListView.builder(
                itemCount: courseQuestions.length,
                itemBuilder: (context, index) {
                  final question = courseQuestions[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        question.question,
                        style: const TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: question.options.asMap().entries.map((entry) {
                          final optionIndex = entry.key;
                          final option = entry.value;
                          return RadioListTile<int>(
                            value: optionIndex,
                            groupValue: selectedAnswers[index],
                            onChanged: isSubmitted
                                ? null
                                : (value) =>
                                    handleRadioValueChanged(value, index),
                            title: Text(option.answer),
                          );
                        }).toList(),
                      ),
                    ],
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: isSubmitButtonEnabled() ? submitAnswers : null,
              child: const Text('Submit'),
            ),
            const SizedBox(height: 8.0),
            ElevatedButton(
              onPressed: isSubmitted ? resetQuiz : null,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
