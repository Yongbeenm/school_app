import 'package:flutter/material.dart';
import '../../widgets/common.dart';
import 'admin_teachers.dart';
import 'admin_classes.dart';
import 'admin_students.dart';
import 'admin_ranking.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("👑 ផ្នែក អ្នកគ្រប់គ្រង"), actions: appActions(context)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _tile(context, "👩‍🏫 គ្រប់គ្រងគ្រូ", const AdminTeachers()),
            _tile(context, "🏫 គ្រប់គ្រងថ្នាក់", const AdminClasses()),
            _tile(context, "👩‍🎓 គ្រប់គ្រងសិស្ស", const AdminStudents()),
            _tile(context, "🏆 ចំណាត់ថ្នាក់", const AdminRanking()),
            const SizedBox(height: 16),
            const Text("📌 Admin គ្រប់គ្រង: គ្រូ • សិស្ស • ថ្នាក់ • ចំណាត់ថ្នាក់", textAlign: TextAlign.center),
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
