class AuthResponse {
  final bool success;
  final String message;
  final AuthData? data;

  AuthResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    // ✅ Support Odoo format: {"Status": "auth successful", "User": "...", "api-key": "..."}
    if (json.containsKey('Status') && json.containsKey('api-key')) {
      final isSuccess = json['Status'] == 'auth successful';
      return AuthResponse(
        success: isSuccess,
        message: json['Status'] ?? '',
        data: isSuccess
            ? AuthData(
                accessToken: json['api-key'] ?? '',
                refreshToken:
                    json['api-key'] ?? '', // Odoo uses same key for both
                username: json['User'],
              )
            : null,
      );
    }

    // ✅ Support legacy format: {"Success": true, "Message": "...", "Data": {...}}
    return AuthResponse(
      success: json['Success'] ?? false,
      message: json['Message'] ?? '',
      data: json['Data'] != null ? AuthData.fromJson(json['Data']) : null,
    );
  }
}

class AuthData {
  final String accessToken;
  final String refreshToken;
  final String? username;

  AuthData({
    required this.accessToken,
    required this.refreshToken,
    this.username,
  });

  factory AuthData.fromJson(Map<String, dynamic> json) {
    return AuthData(
      accessToken: json['access_token'] ?? '',
      refreshToken: json['refresh_token'] ?? '',
      username: json['username'],
    );
  }
}
