import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../services/api_client.dart';
import '../../widgets/ui.dart';

class TeacherStudents extends StatefulWidget {
  const TeacherStudents({super.key});

  @override
  State<TeacherStudents> createState() => _TeacherStudentsState();
}

class _TeacherStudentsState extends State<TeacherStudents> {
  bool loading = true;
  String className = "";
  List<StudentItem> students = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final res = await ApiClient.I.get("/api/teacher/students");
      if (res.data["ok"] == true) {
        className = (res.data["classroom"]["name"] ?? "") as String;
        students = (res.data["students"] as List).map((e) => StudentItem.fromJson(e)).toList();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(snackErr("មិនអាចទាញសិស្សបាន"));
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(snackErr("មិនអាចទាញសិស្សបាន"));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _addStudent() async {
    final full = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("➕ បន្ថែមសិស្ស"),
        content: TextField(controller: full, decoration: const InputDecoration(labelText: "👩‍🎓 ឈ្មោះពេញ")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("បោះបង់")),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text("រក្សាទុក")),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final res = await ApiClient.I.post("/api/teacher/students", {"full_name": full.text.trim()});
      if (res.data["ok"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(snackOk("បានបន្ថែមសិស្ស"));
        await _load();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(snackErr("បរាជ័យ"));
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(snackErr("បរាជ័យ"));
    }
  }

  Future<void> _deleteStudent(StudentItem s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("🗑️ លុបសិស្ស"),
        content: Text("ចង់លុប '${s.fullName}' មែនទេ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("ទេ")),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text("លុប")),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final res = await ApiClient.I.delete("/api/teacher/students/${s.id}");
      if (res.data["ok"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(snackOk("បានលុប"));
        await _load();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(snackErr("បរាជ័យ"));
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(snackErr("បរាជ័យ"));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("👩‍🎓 សិស្ស ($className)"), actions: [
        IconButton(onPressed: loading ? null : _load, icon: const Icon(Icons.refresh)),
        IconButton(onPressed: loading ? null : _addStudent, icon: const Icon(Icons.add)),
      ]),
      body: loading
          ? const Busy()
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: students.length,
              itemBuilder: (_, i) {
                final s = students[i];
                return Card(
                  child: ListTile(
                    title: Text("👩‍🎓 ${s.fullName}", style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text("កូដ៖ ${s.code}"),
                    trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => _deleteStudent(s)),
                  ),
                );
              },
            ),
    );
  }
}
