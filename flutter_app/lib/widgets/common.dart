import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/session_service.dart';

List<Widget> appActions(BuildContext context) => [
  IconButton(
    tooltip: "ចេញ",
    onPressed: () async {
      await SessionService.I.clear();
      if (context.mounted) context.go("/login");
    },
    icon: const Icon(Icons.logout),
  ),
];
