
class UserPublic {
  final String id;
  final String email;
  final String? fullName;
  final DateTime createdAt;

  UserPublic({required this.id, required this.email, this.fullName, required this.createdAt});

  factory UserPublic.fromJson(Map<String, dynamic> json) {
    return UserPublic(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class TokenResponse {
  final String accessToken;
  final String tokenType;

  TokenResponse({required this.accessToken, required this.tokenType});

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String? ?? 'bearer',
    );
  }
}
