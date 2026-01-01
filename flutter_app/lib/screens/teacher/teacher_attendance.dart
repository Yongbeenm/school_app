import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../services/api_client.dart';
import '../../widgets/ui.dart';

class TeacherAttendance extends StatefulWidget {
  const TeacherAttendance({super.key});

  @override
  State<TeacherAttendance> createState() => _TeacherAttendanceState();
}

class _TeacherAttendanceState extends State<TeacherAttendance> {
  bool loading = true;
  List<TermItem> terms = [];
  int? termId;

  List<StudentItem> students = [];
  Map<int, AttendanceItem> monthly = {};
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadPickers();
  }

  Future<void> _loadPickers() async {
    setState(() => loading = true);
    try {
      final tRes = await ApiClient.I.get("/api/teacher/terms");
      terms = (tRes.data["terms"] as List).map((e) => TermItem.fromJson(e)).toList();
      termId ??= terms.isNotEmpty ? terms.first.id : null;
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(snackErr("មិនអាចទាញប្រចាំខែ"));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _load() async {
    if (termId == null) return;
    setState(() => loading = true);
    try {
      final sRes = await ApiClient.I.get("/api/teacher/students");
      students = (sRes.data["students"] as List).map((e) => StudentItem.fromJson(e)).toList();

      final aRes = await ApiClient.I.get("/api/teacher/attendance", query: {"term_id": termId});
      monthly = {};
      (aRes.data["monthly"] as Map).forEach((k, v) {
        monthly[int.parse(k.toString())] = AttendanceItem.fromJson(v);
      });
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(snackErr("មិនអាចទាញទិន្នន័យ"));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _save(int studentId, AttendanceItem item) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () async {
      try {
        await ApiClient.I.post("/api/teacher/attendance", {
          "student_id": studentId,
          "term_id": termId,
          "absent": item.absent,
          "permission": item.permission,
          "note": item.note,
        });
      } catch (_) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(snackErr("រក្សាទុកបរាជ័យ"));
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📒 អវត្តមាន/ច្បាប់"), actions: [
        IconButton(onPressed: loading ? null : _loadPickers, icon: const Icon(Icons.refresh)),
      ]),
      body: loading
          ? const Busy()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      DropdownButtonFormField<int?>(
                        value: termId,
                        decoration: const InputDecoration(labelText: "📅 ប្រចាំខែ"),
                        items: terms.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                        onChanged: (v) => setState(() => termId = v),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(width: double.infinity, child: FilledButton(onPressed: _load, child: const Text("📥 បង្ហាញបញ្ជី"))),
                      const SizedBox(height: 8),
                      const Text("💡 កែតម្លៃ => រក្សាទុកស្វ័យប្រវត្តិ", textAlign: TextAlign.center),
                    ],
                  ),
                ),
                Expanded(
                  child: students.isEmpty
                      ? const Center(child: Text("មិនមានសិស្ស"))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: students.length,
                          itemBuilder: (_, i) {
                            final s = students[i];
                            final cur = monthly[s.id] ?? AttendanceItem(absent: 0, permission: 0, note: "");
                            final absentC = TextEditingController(text: cur.absent.toString());
                            final permC = TextEditingController(text: cur.permission.toString());
                            final noteC = TextEditingController(text: cur.note);
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("👩‍🎓 ${s.fullName}", style: const TextStyle(fontWeight: FontWeight.w900)),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: absentC,
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(labelText: "❌ អវត្តមាន"),
                                            onChanged: (v) {
                                              final item = AttendanceItem(
                                                absent: int.tryParse(v) ?? 0,
                                                permission: cur.permission,
                                                note: cur.note,
                                              );
                                              monthly[s.id] = item;
                                              _save(s.id, item);
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: TextField(
                                            controller: permC,
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(labelText: "📝 ច្បាប់"),
                                            onChanged: (v) {
                                              final item = AttendanceItem(
                                                absent: cur.absent,
                                                permission: int.tryParse(v) ?? 0,
                                                note: cur.note,
                                              );
                                              monthly[s.id] = item;
                                              _save(s.id, item);
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: noteC,
                                      decoration: const InputDecoration(labelText: "📌 កំណត់ចំណាំ"),
                                      onChanged: (v) {
                                        final item = AttendanceItem(absent: cur.absent, permission: cur.permission, note: v);
                                        monthly[s.id] = item;
                                        _save(s.id, item);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                )
              ],
            ),
    );
  }
}
