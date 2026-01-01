import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../services/api_client.dart';
import '../../widgets/ui.dart';

class AdminClasses extends StatefulWidget {
  const AdminClasses({super.key});

  @override
  State<AdminClasses> createState() => _AdminClassesState();
}

class _AdminClassesState extends State<AdminClasses> {
  bool loading = true;
  List<AdminClassRoom> classes = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final res = await ApiClient.I.get("/api/admin/classes");
      classes = (res.data["classes"] as List).map((e) => AdminClassRoom.fromJson(e)).toList();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(snackErr("មិនអាចទាញទិន្នន័យបាន"));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _addOrEdit({AdminClassRoom? c}) async {
    final name = TextEditingController(text: c?.name ?? "");
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(c == null ? "➕ បន្ថែមថ្នាក់" : "✏️ កែប្រែថ្នាក់"),
        content: TextField(controller: name, decoration: const InputDecoration(labelText: "🏫 ឈ្មោះថ្នាក់")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("បោះបង់")),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text("រក្សាទុក")),
        ],
      ),
    );
    if (ok != true) return;

    try {
      if (c == null) {
        final res = await ApiClient.I.post("/api/admin/classes", {"name": name.text.trim()});
        if (res.data["ok"] == true) {
          ScaffoldMessenger.of(context).showSnackBar(snackOk("បានបន្ថែមថ្នាក់"));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(snackErr("បរាជ័យ: ${res.data["error"] ?? ""}"));
        }
      } else {
        final res = await ApiClient.I.put("/api/admin/classes/${c.id}", {"name": name.text.trim()});
        if (res.data["ok"] == true) {
          ScaffoldMessenger.of(context).showSnackBar(snackOk("បានកែប្រែ"));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(snackErr("បរាជ័យ"));
        }
      }
      await _load();
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(snackErr("បរាជ័យ"));
    }
  }

  Future<void> _delete(AdminClassRoom c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("🗑️ លុបថ្នាក់"),
        content: Text("ចង់លុប '${c.name}' មែនទេ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("ទេ")),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text("លុប")),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final res = await ApiClient.I.delete("/api/admin/classes/${c.id}");
      if (res.data["ok"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(snackOk("បានលុប"));
        await _load();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(snackErr("មិនអាចលុបបាន (អាចមានគ្រូ/សិស្សនៅក្នុងថ្នាក់)"));
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(snackErr("បរាជ័យ"));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🏫 ថ្នាក់"), actions: [
        IconButton(onPressed: loading ? null : _load, icon: const Icon(Icons.refresh)),
        IconButton(onPressed: loading ? null : () => _addOrEdit(), icon: const Icon(Icons.add)),
      ]),
      body: loading
          ? const Busy()
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: classes.length,
              itemBuilder: (_, i) {
                final c = classes[i];
                return Card(
                  child: ListTile(
                    title: Text("🏫 ${c.name}", style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(c.teacherName.isEmpty ? "👩‍🏫 មិនទាន់មានគ្រូ" : "👩‍🏫 ${c.teacherName}"),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == "edit") _addOrEdit(c: c);
                        if (v == "del") _delete(c);
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
