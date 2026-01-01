import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_client.dart';
import '../services/session_service.dart';
import '../widgets/ui.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String msg = "កំពុងពិនិត្យការចូល...";

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final token = await SessionService.I.getToken();
    final role = await SessionService.I.getRole();

    // no token -> login
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      context.go("/login");
      return;
    }

    // validate token
    try {
      final res = await ApiClient.I.get("/api/me");
      if ((res.data?["ok"] ?? false) != true) throw Exception("bad");
    } catch (_) {
      await SessionService.I.clear();
      if (!mounted) return;
      context.go("/login");
      return;
    }

    final r = (role ?? "").toUpperCase();
    if (!mounted) return;

    if (r == "ADMIN") {
      context.go("/admin");
    } else if (r == "TEACHER") {
      context.go("/teacher");
    } else {
      context.go("/student");
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Busy(text: "កំពុងបើកកម្មវិធី..."));
  }
}
