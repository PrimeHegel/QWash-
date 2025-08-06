class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? room;
  final String role; // tambah role

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.room,
    required this.role, // wajib di constructor
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      room: map['room'],
      role: map['role'] ?? 'user', // default ke 'user' kalau ga ada
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'room': room,
      'role': role, // simpan role juga
    };
  }
}
