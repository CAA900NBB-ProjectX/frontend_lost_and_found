class User {
  final int id;
  final String username;
  final String email;
  final bool enabled;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.enabled,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      enabled: json['enabled'],
    );
  }
}