class UserModel {
  final String uid;
  final String name;
  final String mobile;
  final String role; // 'customer' or 'admin'
  final bool notificationsEnabled;
  final String? fcmToken;

  UserModel({
    required this.uid,
    required this.name,
    required this.mobile,
    required this.role,
    this.notificationsEnabled = true,
    this.fcmToken,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      uid: id,
      name: data['name'] ?? '',
      mobile: data['mobile'] ?? '',
      role: data['role'] ?? 'customer',
      notificationsEnabled: data['notificationsEnabled'] ?? true,
      fcmToken: data['fcmToken'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'mobile': mobile,
      'role': role,
      'notificationsEnabled': notificationsEnabled,
      'fcmToken': fcmToken,
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? mobile,
    String? role,
    bool? notificationsEnabled,
    String? fcmToken,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      role: role ?? this.role,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}
