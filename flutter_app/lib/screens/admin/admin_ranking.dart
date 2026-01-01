import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../services/api_client.dart';
import '../../widgets/ui.dart';

class AdminRanking extends StatefulWidget {
  const AdminRanking({super.key});

  @override
  State<AdminRanking> createState() => _AdminRankingState();
}

class _AdminRankingState extends State<AdminRanking> {
  bool loading = true;
  List<AdminClassRoom> classes = [];
  List<TermItem> terms = [];
  int? classId;
  int? termId;
  List<RankingRow> rows = [];

  @override
  void initState() {
    super.initState();
    _loadPickers();
  }

  Future<void> _loadPickers() async {
    setState(() => loading = true);
    try {
      final cRes = await ApiClient.I.get("/api/admin/classes");
      final tRes = await ApiClient.I.get("/api/admin/terms");
      classes = (cRes.data["classes"] as List).map((e) => AdminClassRoom.fromJson(e)).toList();
      terms = (tRes.data["terms"] as List).map((e) => TermItem.fromJson(e)).toList();
      classId ??= classes.isNotEmpty ? classes.first.id : null;
      termId ??= terms.isNotEmpty ? terms.first.id : null;
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(snackErr("មិនអាចទាញទិន្នន័យបាន"));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _loadRanking() async {
    if (classId == null || termId == null) return;
    setState(() => loading = true);
    try {
      final res = await ApiClient.I.get("/api/admin/ranking", query: {"class_id": classId, "term_id": termId});
      rows = (res.data["rows"] as List).map((e) => RankingRow.fromJson(e)).toList();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(snackErr("មិនអាចទាញចំណាត់ថ្នាក់បាន"));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🏆 ចំណាត់ថ្នាក់"), actions: [
        IconButton(onPressed: loading ? null : _loadPickers, icon: const Icon(Icons.refresh)),
        IconButton(onPressed: loading ? null : _loadRanking, icon: const Icon(Icons.search)),
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
                        value: classId,
                        decoration: const InputDecoration(labelText: "🏫 ថ្នាក់"),
                        items: classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                        onChanged: (v) => setState(() => classId = v),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int?>(
                        value: termId,
                        decoration: const InputDecoration(labelText: "📅 ប្រចាំខែ"),
                        items: terms.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                        onChanged: (v) => setState(() => termId = v),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(onPressed: _loadRanking, child: const Text("🔎 មើលចំណាត់ថ្នាក់")),
                      ),
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
                                title: Text("👩‍🎓 ${r.fullName}", style: const TextStyle(fontWeight: FontWeight.w800)),
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
