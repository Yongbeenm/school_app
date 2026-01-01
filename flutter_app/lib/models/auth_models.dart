class LoginResult {
  final bool ok;
  final String? token;
  final String? role;
  final String? error;
  LoginResult({required this.ok, this.token, this.role, this.error});

  factory LoginResult.fromJson(Map<String, dynamic> j) => LoginResult(
        ok: (j["ok"] ?? false) as bool,
        token: j["token"] as String?,
        role: j["role"] as String?,
        error: j["error"] as String?,
      );
}
