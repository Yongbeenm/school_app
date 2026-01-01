import 'package:flutter/material.dart';
import '../../widgets/common.dart';
import 'student_overview.dart';

class StudentHome extends StatelessWidget {
  const StudentHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🎓 ផ្នែក សិស្ស"), actions: appActions(context)),
      body: const StudentOverview(),
    );
  }
}
