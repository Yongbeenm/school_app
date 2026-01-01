import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../services/api_client.dart';
import '../../widgets/ui.dart';

class AdminStudents extends StatefulWidget {
  const AdminStudents({super.key});

  @override
  State<AdminStudents> createState() => _AdminStudentsState();
}

class _AdminStudentsState extends State<AdminStudents> {
  bool loading = true;
  List<AdminStudent> students = [];
  List<AdminClassRoom> classes = [];
  int? classFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final cRes = await ApiClient.I.get("/api/admin/classes");
      classes = (cRes.data["classes"] as List).map((e) => AdminClassRoom.fromJson(e)).toList();
      final sRes = await ApiClient.I.get("/api/admin/students", query: classFilter == null ? null : {"class_id": classFilter});
      students = (sRes.data["students"] as List).map((e) => AdminStudent.fromJson(e)).toList();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(snackErr("មិនអាចទាញទិន្នន័យបាន"));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _addStudent() async {
    final full = TextEditingController();
    int? classId = classFilter;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("➕ បន្ថែមសិស្ស"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: full, decoration: const InputDecoration(labelText: "👩‍🎓 ឈ្មោះពេញ")),
              const SizedBox(height: 10),
              DropdownButtonFormField<int?>(
                value: classId,
                decoration: const InputDecoration(labelText: "🏫 ជ្រើសថ្នាក់"),
                items: [
                  const DropdownMenuItem(value: null, child: Text("ជ្រើសថ្នាក់...")),
                  ...classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                ],
                onChanged: (v) => classId = v,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("បោះបង់")),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text("រក្សាទុក")),
        ],
      ),
    );

    if (ok != true) return;

    try {
      final res = await ApiClient.I.post("/api/admin/students", {"full_name": full.text.trim(), "class_id": classId});
      if (res.data["ok"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(snackOk("បានបន្ថែមសិស្ស"));
        await _load();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(snackErr("បរាជ័យ: ${res.data["error"] ?? ""}"));
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(snackErr("បរាជ័យ"));
    }
  }

  Future<void> _editStudent(AdminStudent s) async {
    final full = TextEditingController(text: s.fullName);
    int? classId = s.classId;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("✏️ កែប្រែសិស្ស"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              Text("កូដ៖ ${s.code}", style: const TextStyle(fontWeight: FontWeight.w700)),
              TextField(controller: full, decoration: const InputDecoration(labelText: "👩‍🎓 ឈ្មោះពេញ")),
              const SizedBox(height: 10),
              DropdownButtonFormField<int?>(
                value: classId,
                decoration: const InputDecoration(labelText: "🏫 ថ្នាក់"),
                items: [
                  ...classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                ],
                onChanged: (v) => classId = v,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("បោះបង់")),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text("រក្សាទុក")),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final res = await ApiClient.I.put("/api/admin/students/${s.studentId}", {"full_name": full.text.trim(), "class_id": classId});
      if (res.data["ok"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(snackOk("បានកែប្រែ"));
        await _load();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(snackErr("បរាជ័យ"));
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(snackErr("បរាជ័យ"));
    }
  }

  Future<void> _deleteStudent(AdminStudent s) async {
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
      final res = await ApiClient.I.delete("/api/admin/students/${s.studentId}");
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
      appBar: AppBar(title: const Text("👩‍🎓 សិស្ស"), actions: [
        IconButton(onPressed: loading ? null : _load, icon: const Icon(Icons.refresh)),
        IconButton(onPressed: loading ? null : _addStudent, icon: const Icon(Icons.add)),
      ]),
      body: loading
          ? const Busy()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: DropdownButtonFormField<int?>(
                    value: classFilter,
                    decoration: const InputDecoration(labelText: "🏫 តម្រងតាមថ្នាក់"),
                    items: [
                      const DropdownMenuItem(value: null, child: Text("ទាំងអស់")),
                      ...classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                    ],
                    onChanged: (v) async {
                      setState(() => classFilter = v);
                      await _load();
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: students.length,
                    itemBuilder: (_, i) {
                      final s = students[i];
                      return Card(
                        child: ListTile(
                          title: Text("👩‍🎓 ${s.fullName}", style: const TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Text("កូដ៖ ${s.code}  •  🏫 ${s.className}"),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == "edit") _editStudent(s);
                              if (v == "del") _deleteStudent(s);
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: "edit", child: Text("✏️ កែ")),
                              PopupMenuItem(value: "del", child: Text("🗑️ លុប")),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
