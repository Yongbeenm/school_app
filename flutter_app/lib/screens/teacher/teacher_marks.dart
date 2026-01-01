import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../services/api_client.dart';
import '../../widgets/ui.dart';

class TeacherMarks extends StatefulWidget {
  const TeacherMarks({super.key});

  @override
  State<TeacherMarks> createState() => _TeacherMarksState();
}

class _TeacherMarksState extends State<TeacherMarks> {
  bool loading = true;
  List<TermItem> terms = [];
  List<SubjectItem> subjects = [];
  int? termId;
  int? subjectId;

  List<StudentItem> students = [];
  Map<int, double> scores = {};
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
      final sRes = await ApiClient.I.get("/api/teacher/subjects");
      terms = (tRes.data["terms"] as List).map((e) => TermItem.fromJson(e)).toList();
      subjects = (sRes.data["subjects"] as List).map((e) => SubjectItem.fromJson(e)).toList();
      termId ??= terms.isNotEmpty ? terms.first.id : null;
      subjectId ??= subjects.isNotEmpty ? subjects.first.id : null;
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(snackErr("មិនអាចទាញប្រចាំខែ/មុខវិជ្ជា"));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _loadMarks() async {
    if (termId == null || subjectId == null) return;
    setState(() => loading = true);
    try {
      final res = await ApiClient.I.get("/api/teacher/marks", query: {"term_id": termId, "subject_id": subjectId});
      students = (res.data["students"] as List).map((e) => StudentItem.fromJson(e)).toList();
      scores = {};
      (res.data["scores"] as Map).forEach((k, v) {
        scores[int.parse(k.toString())] = (v ?? 0).toDouble();
      });
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(snackErr("មិនអាចទាញពិន្ទុ"));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _onScoreChanged(int studentId, String txt) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () async {
      try {
        await ApiClient.I.post("/api/teacher/marks", {
          "student_id": studentId,
          "term_id": termId,
          "subject_id": subjectId,
          "score": txt.trim(),
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
      appBar: AppBar(title: const Text("📝 បញ្ចូលពិន្ទុ"), actions: [
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
                      DropdownButtonFormField<int?>(
                        value: subjectId,
                        decoration: const InputDecoration(labelText: "📚 មុខវិជ្ជា"),
                        items: subjects.map((s) => DropdownMenuItem(value: s.id, child: Text("${s.name} (w=${s.weight})"))).toList(),
                        onChanged: (v) => setState(() => subjectId = v),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(onPressed: _loadMarks, child: const Text("📥 បង្ហាញបញ្ជី")),
                      ),
                      const SizedBox(height: 8),
                      const Text("💡 វាយពិន្ទុ => រក្សាទុកស្វ័យប្រវត្តិ", textAlign: TextAlign.center),
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
                            final val = scores[s.id];
                            final c = TextEditingController(text: val == null ? "" : val.toString());
                            return Card(
                              child: ListTile(
                                title: Text("👩‍🎓 ${s.fullName}", style: const TextStyle(fontWeight: FontWeight.w800)),
                                subtitle: Text("កូដ៖ ${s.code}"),
                                trailing: SizedBox(
                                  width: 90,
                                  child: TextField(
                                    controller: c,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(hintText: "0-100"),
                                    onChanged: (txt) => _onScoreChanged(s.id, txt),
                                  ),
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
