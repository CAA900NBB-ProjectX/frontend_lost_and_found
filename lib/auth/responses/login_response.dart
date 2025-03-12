class LoginResponse {
  final String token;
  final int expiresIn;

  LoginResponse({
    required this.token,
    required this.expiresIn,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'],
      expiresIn: json['expiresIn'],
    );
  }
}