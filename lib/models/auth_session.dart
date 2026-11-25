import 'dart:convert';

enum AccountRole { household, admin }

/// The backend-issued session. Role is used for navigation only.
class AuthSession {
  const AuthSession._(this.token, this.userId, this.role, this.expiresAt);

  final String token;
  final int userId;
  final AccountRole role;
  final DateTime expiresAt;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final token = json['token'] as String?;
    final role = switch (json['role']) {
      'HOUSEHOLD_USER' => AccountRole.household,
      'ADMIN' => AccountRole.admin,
      _ => throw const FormatException('Unsupported account role'),
    };
    if (token == null) throw const FormatException('Missing access token');
    final parts = token.split('.');
    if (parts.length != 3) throw const FormatException('Invalid token');
    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
    if (payload is! Map<String, dynamic> || payload['role'] != json['role']) {
      throw const FormatException('Invalid session role');
    }
    final userId = int.tryParse('${payload['sub']}');
    final expires = payload['exp'];
    if (userId == null || userId <= 0 || expires is! int) {
      throw const FormatException('Invalid session claims');
    }
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(
      expires * 1000,
      isUtc: true,
    );
    if (!expiresAt.isAfter(DateTime.now())) {
      throw const FormatException('Expired session');
    }
    return AuthSession._(token, userId, role, expiresAt);
  }
}
