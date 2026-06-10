import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../core/services/firebase_service.dart';
import '../core/services/notification_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseService _db = FirebaseService();
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _user?.role == 'admin';

  Future<void> checkCurrentUser() async {
    _isLoading = true;
    notifyListeners();
    try {
      _user = await _db.getCurrentUser();
      if (_user != null) {
        await NotificationService().setupUserFCMToken(_user!.uid);
      }
    } catch (e) {
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String name, String mobile, String password, String confirmPassword) async {
    if (name.trim().isEmpty || mobile.trim().isEmpty || password.trim().isEmpty) {
      _errorMessage = 'All fields are required.';
      notifyListeners();
      return false;
    }

    if (password != confirmPassword) {
      _errorMessage = 'Passwords do not match.';
      notifyListeners();
      return false;
    }

    if (mobile.length < 10) {
      _errorMessage = 'Please enter a valid 10-digit mobile number.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String role = (mobile == '9999999999' || mobile == '9515639193') ? 'admin' : 'customer';
      _user = await _db.register(name, mobile, password, role);
      await NotificationService().setupUserFCMToken(_user!.uid);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String mobile, String password) async {
    if (mobile.trim().isEmpty || password.trim().isEmpty) {
      _errorMessage = 'Please fill in all fields.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _db.login(mobile, password);
      await NotificationService().setupUserFCMToken(_user!.uid);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    await _db.logout();
    _user = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateNotificationSettings(bool enabled) async {
    if (_user == null) return;
    try {
      if (enabled) {
        await NotificationService().requestFCMPermissions();
      }
      await _db.updateUserNotificationSettings(_user!.uid, enabled);
      _user = _user!.copyWith(notificationsEnabled: enabled);
      notifyListeners();
    } catch (e) {
      print("CampusKart AuthProvider: Failed to update notification settings: $e");
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
