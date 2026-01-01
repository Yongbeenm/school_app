import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_client.dart';
import '../services/session_service.dart';
import '../widgets/ui.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final u = TextEditingController();
  final p = TextEditingController();
  bool loading = false;

  Future<void> _login() async {
    setState(() => loading = true);
    try {
      final res = await ApiClient.I.post("/api/login", {"username": u.text.trim(), "password": p.text.trim()});
      final data = res.data as Map<String, dynamic>;
      if (data["ok"] != true) {
        ScaffoldMessenger.of(context).showSnackBar(snackErr("ឈ្មោះ ឬ លេខសម្ងាត់ មិនត្រឹមត្រូវ"));
      } else {
        final token = (data["token"] ?? "") as String;
        final role = (data["role"] ?? "STUDENT") as String;
        await SessionService.I.saveSession(token: token, role: role);
        if (!mounted) return;
        if (role == "ADMIN") context.go("/admin");
        else if (role == "TEACHER") context.go("/teacher");
        else context.go("/student");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(snackErr("មិនអាចភ្ជាប់ Backend បាន"));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🔐 ចូលប្រើ")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Text("🏫 កម្មវិធីគ្រប់គ្រងពិន្ទុ", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 18),
            TextField(controller: u, decoration: const InputDecoration(labelText: "👤 ឈ្មោះអ្នកប្រើ", border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: p, obscureText: true, decoration: const InputDecoration(labelText: "🔑 លេខសម្ងាត់", border: OutlineInputBorder())),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: loading ? null : _login,
                child: Text(loading ? "កំពុងចូល..." : "✅ ចូល"),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _showHelp(context),
              child: const Text("🧩 មើលជំនួយ (URL Backend)"),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelp(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text("🧩 Backend URL"),
        content: const Text("កែ `lib/config.dart`\n\n• Backend នៅទូរស័ព្ទ (Termux): http://127.0.0.1:5001\n• Backend នៅ Laptop: http://IP:5001"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("បិទ")),
        ],
      ),
    );
  }
}
