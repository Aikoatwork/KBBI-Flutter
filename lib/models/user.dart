class User {
  final int? id;
  final String username;
  final String password;
  final String? profilePicture;

  User({
    this.id,
    required this.username,
    required this.password,
    this.profilePicture,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'profilePicture': profilePicture,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      profilePicture: map['profilePicture'],
    );
  }
}
