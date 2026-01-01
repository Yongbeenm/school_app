import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../services/api_client.dart';
import '../../widgets/ui.dart';

class TeacherRanking extends StatefulWidget {
  const TeacherRanking({super.key});

  @override
  State<TeacherRanking> createState() => _TeacherRankingState();
}

class _TeacherRankingState extends State<TeacherRanking> {
  bool loading = true;
  List<TermItem> terms = [];
  int? termId;
  List<RankingRow> rows = [];
  String className = "";

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
      final res = await ApiClient.I.get("/api/teacher/ranking", query: {"term_id": termId});
      if (res.data["ok"] == true) {
        className = (res.data["classroom"]["name"] ?? "") as String;
        rows = (res.data["rows"] as List).map((e) => RankingRow.fromJson(e)).toList();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(snackErr("មិនអាចទាញចំណាត់ថ្នាក់"));
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(snackErr("មិនអាចទាញចំណាត់ថ្នាក់"));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("🏆 ចំណាត់ថ្នាក់ $className"), actions: [
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
                      SizedBox(width: double.infinity, child: FilledButton(onPressed: _load, child: const Text("🔎 មើលចំណាត់ថ្នាក់"))),
                    ],
                  ),
                ),
                Expanded(
                  child: rows.isEmpty
                      ? const Center(child: Text("មិនមានទិន្នន័យ"))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: rows.length,
                          itemBuilder: (_, i) {
                            final r = rows[i];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(child: Text("${r.rank ?? (i + 1)}")),
                                title: Text("👩‍🎓 ${r.fullName}", style: const TextStyle(fontWeight: FontWeight.w900)),
                                subtitle: Text("កូដ៖ ${r.code}  •  ពិន្ទុមធ្យម៖ ${r.average.toStringAsFixed(2)}"),
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
