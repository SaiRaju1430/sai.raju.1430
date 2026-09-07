class UserModel {
  final String uid;
  final String name;
  final String mobile;
  final String role; // 'customer' or 'admin'
  final String? email;
  final bool notificationsEnabled;
  final String? fcmToken;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.mobile,
    required this.role,
    this.email,
    this.notificationsEnabled = true,
    this.fcmToken,
    this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return UserModel(
      uid: id.isNotEmpty ? id : (data['id'] ?? data['uid'] ?? ''),
      name: data['name'] ?? '',
      mobile: data['mobile'] ?? '',
      role: data['role'] ?? 'customer',
      email: data['email'],
      notificationsEnabled: data['notificationsEnabled'] ?? data['notifications_enabled'] ?? true,
      fcmToken: data['fcmToken'] ?? data['fcm_token'],
      createdAt: parseDate(data['created_at'] ?? data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': uid,
      'uid': uid,
      'name': name,
      'mobile': mobile,
      'role': role,
      'email': email,
      'notifications_enabled': notificationsEnabled,
      'notificationsEnabled': notificationsEnabled,
      'fcm_token': fcmToken,
      'fcmToken': fcmToken,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? mobile,
    String? role,
    String? email,
    bool? notificationsEnabled,
    String? fcmToken,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      role: role ?? this.role,
      email: email ?? this.email,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

