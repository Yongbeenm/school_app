import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../services/api_client.dart';
import '../../widgets/ui.dart';

class AdminTeachers extends StatefulWidget {
  const AdminTeachers({super.key});

  @override
  State<AdminTeachers> createState() => _AdminTeachersState();
}

class _AdminTeachersState extends State<AdminTeachers> {
  bool loading = true;
  List<AdminTeacher> teachers = [];
  List<AdminClassRoom> classes = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final tRes = await ApiClient.I.get("/api/admin/teachers");
      final cRes = await ApiClient.I.get("/api/admin/classes");
      teachers = (tRes.data["teachers"] as List).map((e) => AdminTeacher.fromJson(e)).toList();
      classes = (cRes.data["classes"] as List).map((e) => AdminClassRoom.fromJson(e)).toList();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(snackErr("មិនអាចទាញទិន្នន័យបាន"));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _addTeacher() async {
    final username = TextEditingController();
    final password = TextEditingController();
    final full = TextEditingController();
    int? classId;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("➕ បន្ថែមគ្រូ"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: full, decoration: const InputDecoration(labelText: "👩‍🏫 ឈ្មោះពេញ")),
              TextField(controller: username, decoration: const InputDecoration(labelText: "👤 ឈ្មោះអ្នកប្រើ")),
              TextField(controller: password, decoration: const InputDecoration(labelText: "🔑 លេខសម្ងាត់")),
              const SizedBox(height: 10),
              DropdownButtonFormField<int?>(
                value: classId,
                decoration: const InputDecoration(labelText: "🏫 ជ្រើសថ្នាក់ (១ថ្នាក់=១គ្រូ)"),
                items: [
                  const DropdownMenuItem(value: null, child: Text("មិនកំណត់")),
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
      final res = await ApiClient.I.post("/api/admin/teachers", {
        "username": username.text.trim(),
        "password": password.text.trim(),
        "full_name": full.text.trim(),
        "class_id": classId
      });
      if (res.data["ok"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(snackOk("បានបន្ថែមគ្រូ"));
        await _load();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(snackErr("បរាជ័យ: ${res.data["error"] ?? ""}"));
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(snackErr("បរាជ័យ"));
    }
  }

  Future<void> _deleteTeacher(AdminTeacher t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("🗑️ លុបគ្រូ"),
        content: Text("ចង់លុប '${t.fullName}' មែនទេ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("ទេ")),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text("លុប")),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final res = await ApiClient.I.delete("/api/admin/teachers/${t.teacherId}");
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

  Future<void> _editTeacher(AdminTeacher t) async {
    final full = TextEditingController(text: t.fullName);
    final username = TextEditingController(text: t.username);
    final password = TextEditingController(text: "");
    int? classId = t.classId;
    bool active = t.active;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("✏️ កែប្រែគ្រូ"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: full, decoration: const InputDecoration(labelText: "👩‍🏫 ឈ្មោះពេញ")),
              TextField(controller: username, decoration: const InputDecoration(labelText: "👤 ឈ្មោះអ្នកប្រើ")),
              TextField(controller: password, decoration: const InputDecoration(labelText: "🔑 លេខសម្ងាត់ថ្មី (ចាំបាច់បើចង់ប្ដូរ)")),
              const SizedBox(height: 10),
              DropdownButtonFormField<int?>(
                value: classId,
                decoration: const InputDecoration(labelText: "🏫 ថ្នាក់"),
                items: [
                  const DropdownMenuItem(value: null, child: Text("មិនកំណត់")),
                  ...classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                ],
                onChanged: (v) => classId = v,
              ),
              SwitchListTile(
                value: active,
                onChanged: (v) => active = v,
                title: const Text("✅ សកម្ម"),
              )
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
      final body = {
        "full_name": full.text.trim(),
        "username": username.text.trim(),
        "password": password.text.trim(),
        "class_id": classId,
        "active": active,
      };
      final res = await ApiClient.I.put("/api/admin/teachers/${t.teacherId}", body);
      if (res.data["ok"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(snackOk("បានកែប្រែ"));
        await _load();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(snackErr("បរាជ័យ: ${res.data["error"] ?? ""}"));
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(snackErr("បរាជ័យ"));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("👩‍🏫 គ្រូ"), actions: [
        IconButton(onPressed: loading ? null : _load, icon: const Icon(Icons.refresh)),
        IconButton(onPressed: loading ? null : _addTeacher, icon: const Icon(Icons.add)),
      ]),
      body: loading
          ? const Busy()
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: teachers.length,
              itemBuilder: (_, i) {
                final t = teachers[i];
                return Card(
                  child: ListTile(
                    title: Text("👩‍🏫 ${t.fullName}", style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text("👤 ${t.username}  •  🏫 ${t.className.isEmpty ? 'មិនកំណត់ថ្នាក់' : t.className}"),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == "edit") _editTeacher(t);
                        if (v == "del") _deleteTeacher(t);
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
    );
  }
}
