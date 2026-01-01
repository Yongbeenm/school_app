import 'package:flutter/material.dart';
import '../../widgets/common.dart';
import 'teacher_students.dart';
import 'teacher_marks.dart';
import 'teacher_attendance.dart';
import 'teacher_ranking.dart';

class TeacherHome extends StatelessWidget {
  const TeacherHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("👩‍🏫 ផ្នែក គ្រូ"), actions: appActions(context)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _tile(context, "👩‍🎓 បញ្ជីសិស្ស", const TeacherStudents()),
            _tile(context, "📝 បញ្ចូលពិន្ទុ", const TeacherMarks()),
            _tile(context, "📒 អវត្តមាន/ច្បាប់", const TeacherAttendance()),
            _tile(context, "🏆 ចំណាត់ថ្នាក់", const TeacherRanking()),
            const SizedBox(height: 14),
            const Text("📌 គ្រូអាច: បន្ថែមសិស្ស • បញ្ចូលពិន្ទុ • កត់អវត្តមាន/ច្បាប់ • មើលចំណាត់ថ្នាក់", textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, String title, Widget page) {
    return Card(
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      ),
    );
  }
}
