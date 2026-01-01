import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'services/session_service.dart';
import 'screens/login.dart';
import 'screens/splash.dart';
import 'screens/admin/admin_home.dart';
import 'screens/teacher/teacher_home.dart';
import 'screens/student/student_home.dart';

void main() {
  runApp(const SchoolApp());
}

class SchoolApp extends StatelessWidget {
  const SchoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: "/",
      routes: [
        GoRoute(path: "/", builder: (_, __) => const SplashScreen()),
        GoRoute(path: "/login", builder: (_, __) => const LoginScreen()),
        GoRoute(path: "/admin", builder: (_, __) => const AdminHome()),
        GoRoute(path: "/teacher", builder: (_, __) => const TeacherHome()),
        GoRoute(path: "/student", builder: (_, __) => const StudentHome()),
      ],
      redirect: (ctx, state) async {
        final token = await SessionService.I.getToken();
        if (state.fullPath == "/" || state.fullPath == "/login") return null;
        if (token == null || token.isEmpty) return "/login";
        return null;
      },
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: "🏫 កម្មវិធីសាលា",
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFF8FBFF),
        appBarTheme: const AppBarTheme(centerTitle: true),
      ),
      routerConfig: router,
    );
  }
}
