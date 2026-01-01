import 'package:flutter/material.dart';

class CuteCard extends StatelessWidget {
  final Widget child;
  const CuteCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white.withOpacity(0.92),
      child: Padding(padding: const EdgeInsets.all(14), child: child),
    );
  }
}

class Busy extends StatelessWidget {
  final String text;
  const Busy({super.key, this.text = "កំពុងដំណើរការ..."});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 6),
        const CircularProgressIndicator(),
        const SizedBox(height: 12),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

SnackBar snackOk(String msg) => SnackBar(content: Text("✅ $msg"));
SnackBar snackErr(String msg) => SnackBar(content: Text("⚠️ $msg"));
