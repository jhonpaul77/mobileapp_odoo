class User {
  final String uuid;
  final String username;
  final String organization;
  final List<String> roles;

  User({
    required this.uuid,
    required this.username,
    required this.organization,
    required this.roles,
  });

  factory User.fromToken(Map<String, dynamic> decoded) {
    return User(
      uuid: decoded['uuid'] ?? '',
      username: decoded['username'] ?? '',
      organization: decoded['org'] ?? '',
      roles: List<String>.from(decoded['roles'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'uuid': uuid,
    'username': username,
    'organization': organization,
    'roles': roles,
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    uuid: json['uuid'],
    username: json['username'],
    organization: json['organization'],
    roles: List<String>.from(json['roles']),
  );
}