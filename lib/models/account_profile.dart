class AccountProfile {
  const AccountProfile({required this.username, required this.email});

  final String username;
  final String email;

  factory AccountProfile.fromJson(Map<String, dynamic> json) => AccountProfile(
    username: json['username'] as String,
    email: json['email'] as String,
  );
}
