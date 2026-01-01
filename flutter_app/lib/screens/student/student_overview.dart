import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../services/api_client.dart';
import '../../widgets/ui.dart';

class StudentOverview extends StatefulWidget {
  const StudentOverview({super.key});

  @override
  State<StudentOverview> createState() => _StudentOverviewState();
}

class _StudentOverviewState extends State<StudentOverview> {
  bool loading = true;
  List<TermItem> terms = [];
  int? termId;

  Map<String, dynamic>? overview;

  @override
  void initState() {
    super.initState();
    _loadTerms();
  }

  Future<void> _loadTerms() async {
    setState(() => loading = true);
    try {
      final res = await ApiClient.I.get("/api/student/terms");
      terms = (res.data["terms"] as List).map((e) => TermItem.fromJson(e)).toList();
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
      final res = await ApiClient.I.get("/api/student/overview", query: {"term_id": termId});
      if (res.data["ok"] == true) {
        overview = Map<String, dynamic>.from(res.data);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(snackErr("មិនអាចទាញទិន្នន័យ"));
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(snackErr("មិនអាចទាញទិន្នន័យ"));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return loading
        ? const Busy()
        : Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DropdownButtonFormField<int?>(
                  value: termId,
                  decoration: const InputDecoration(labelText: "📅 ប្រចាំខែ"),
                  items: terms.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                  onChanged: (v) => setState(() => termId = v),
                ),
                const SizedBox(height: 10),
                SizedBox(width: double.infinity, child: FilledButton(onPressed: _load, child: const Text("📥 មើលលទ្ធផល"))),
                const SizedBox(height: 10),
                Expanded(
                  child: overview == null
                      ? const Center(child: Text("សូមជ្រើសប្រចាំខែ rồi ចុច មើលលទ្ធផល"))
                      : _panel(),
                )
              ],
            ),
          );
  }

  Widget _panel() {
    final student = overview!["student"] as Map<String, dynamic>;
    final avg = (overview!["average"] ?? 0).toDouble();
    final rank = overview!["rank"];
    final subjects = (overview!["subjects"] as List).cast<Map>();
    final scores = (overview!["scores"] as Map);
    final att = overview!["attendance"] as Map<String, dynamic>;
    return ListView(
      children: [
        Card(
          child: ListTile(
            title: Text("👩‍🎓 ${(student["full_name"] ?? "")}", style: const TextStyle(fontWeight: FontWeight.w900)),
            subtitle: Text("កូដ៖ ${(student["student_code"] ?? "")}"),
          ),
        ),
        Card(
          child: ListTile(
            title: Text("📊 ពិន្ទុមធ្យម៖ ${avg.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w900)),
            subtitle: Text("🏆 ចំណាត់ថ្នាក់៖ ${rank ?? '-'}"),
          ),
        ),
        Card(
          child: ListTile(
            title: const Text("📒 អវត្តមាន/ច្បាប់", style: TextStyle(fontWeight: FontWeight.w900)),
            subtitle: Text("❌ អវត្តមាន: ${att["absent"] ?? 0}   📝 ច្បាប់: ${att["permission"] ?? 0}\n📌 ${(att["note"] ?? "")}"),
          ),
        ),
        const SizedBox(height: 8),
        const Text("📚 ពិន្ទុតាមមុខវិជ្ជា", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        ...subjects.map((s) {
          final sid = s["id"];
          final sc = scores["$sid"];
          return Card(
            child: ListTile(
              title: Text("📘 ${s["name"]}"),
              trailing: Text(sc == null ? "-" : sc.toString(), style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          );
        }),
      ],
    );
  }
}
