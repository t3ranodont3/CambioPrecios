class UserConfig {
  final String username;
  final String password; // in a real app you wouldn't store plaintext

  UserConfig({required this.username, required this.password});

  factory UserConfig.fromJson(Map<String, dynamic> json) =>
      UserConfig(username: json['username'], password: json['password']);

  Map<String, dynamic> toJson() => {
        'username': username,
        'password': password,
      };
}
