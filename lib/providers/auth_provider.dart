import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../core/services/supabase_service.dart';
import '../core/services/notification_service.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseService _db = SupabaseService();
  UserModel? _user;
  User? _tempGoogleUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isExistingAccountLoaded = false;

  UserModel? get user => _user;
  User? get tempGoogleUser => _tempGoogleUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _user?.role == 'admin';
  bool get isExistingAccountLoaded => _isExistingAccountLoaded;

  /// Helper to validate Indian Mobile Numbers (10 digits starting with 6, 7, 8, or 9)
  static bool isValidIndianMobile(String mobile) {
    final cleanMobile = cleanIndianMobile(mobile);
    final regExp = RegExp(r'^[6-9]\d{9}$');
    return regExp.hasMatch(cleanMobile);
  }

  /// Helper to clean Indian Mobile Numbers (strip non-digits, optional +91 or 91 prefix)
  static String cleanIndianMobile(String mobile) {
    String cleaned = mobile.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length == 12 && cleaned.startsWith('91')) {
      cleaned = cleaned.substring(2);
    } else if (cleaned.length == 11 && cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }
    return cleaned;
  }

  Future<void> checkCurrentUser() async {
    _isLoading = true;
    notifyListeners();
    try {
      final sbUser = _db.client.auth.currentUser;
      if (sbUser != null) {
        _user = await _db.getCurrentUser();
        if (_user != null) {
          await NotificationService().setupUserFCMToken(_user!.uid);
          _tempGoogleUser = null;
        } else {
          // Returning from Google OAuth redirect, needs profile completion
          _tempGoogleUser = sbUser;
        }
      } else {
        _user = null;
        _tempGoogleUser = null;
      }
    } catch (e) {
      _user = null;
      _tempGoogleUser = null;
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

    if (!isValidIndianMobile(mobile)) {
      _errorMessage = 'Please enter a valid 10-digit Indian mobile number starting with 6, 7, 8, or 9.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cleanMobile = cleanIndianMobile(mobile);
      String role = (cleanMobile == '9515639193') ? 'admin' : 'customer';
      _user = await _db.register(name.trim(), cleanMobile, password, role);
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

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    _isExistingAccountLoaded = false;
    notifyListeners();
    try {
      final sbUser = await _db.signInWithGoogle();
      if (sbUser == null) {
        // User cancelled picker
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      // Check if profile exists in database
      final profile = await _db.checkProfileExists(sbUser.id);
      if (profile != null) {
        _user = profile;
        await NotificationService().setupUserFCMToken(_user!.uid);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // Profile does not exist, set temporary google user and return false
        _tempGoogleUser = sbUser;
        _isLoading = false;
        notifyListeners();
        return false; // Indicates registration details are required
      }
    } catch (e) {
      _errorMessage = _formatAuthError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> authenticateGoogleForRegistration() async {
    _isLoading = true;
    _errorMessage = null;
    _tempGoogleUser = null;
    _isExistingAccountLoaded = false;
    notifyListeners();
    try {
      final sbUser = await _db.signInWithGoogle();
      if (sbUser == null) {
        // User cancelled Google picker
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Check if profile already exists in Supabase
      final profile = await _db.checkProfileExists(sbUser.id);
      if (profile != null) {
        // Google account already has a CampusKart profile. Load existing profile safely!
        _user = profile;
        _tempGoogleUser = null;
        _isExistingAccountLoaded = true;
        await NotificationService().setupUserFCMToken(_user!.uid);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      // Profile does not exist yet. This is a valid new registration.
      _tempGoogleUser = sbUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _formatAuthError(e);
      _isLoading = false;
      _tempGoogleUser = null;
      notifyListeners();
      return false;
    }
  }

  void clearTempGoogleUser() {
    _tempGoogleUser = null;
    _errorMessage = null;
    _isExistingAccountLoaded = false;
    _db.logout();
    notifyListeners();
  }

  Future<bool> completeRegistration(String name, String mobile) async {
    if (name.trim().isEmpty) {
      _errorMessage = 'Full Name is required.';
      notifyListeners();
      return false;
    }

    if (!isValidIndianMobile(mobile)) {
      _errorMessage = 'Please enter a valid 10-digit Indian mobile number starting with 6, 7, 8, or 9.';
      notifyListeners();
      return false;
    }

    if (_tempGoogleUser == null) {
      _errorMessage = 'Please sign in with Google first.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cleanMobile = cleanIndianMobile(mobile);
      final String role = (cleanMobile == '9515639193') ? 'admin' : 'customer';
      
      _user = await _db.completeProfileRegistration(
        uid: _tempGoogleUser!.id,
        name: name.trim(),
        mobile: cleanMobile,
        role: role,
        email: _tempGoogleUser!.email,
      );

      await NotificationService().setupUserFCMToken(_user!.uid);
      _tempGoogleUser = null;
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
      final cleanMobile = cleanIndianMobile(mobile);
      _user = await _db.login(cleanMobile, password);
      await NotificationService().setupUserFCMToken(_user!.uid);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _formatAuthError(e);
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
    _tempGoogleUser = null;
    _isExistingAccountLoaded = false;
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
      debugPrint("CampusKart AuthProvider: Failed to update notification settings: $e");
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _formatAuthError(dynamic e) {
    final str = e.toString();
    if (str.contains('people.googleapis.com') || str.contains('People API')) {
      return 'Google People API is propagating in Google Cloud. Please try again in 1-2 minutes.';
    }
    if (str.contains('popup_closed_by_user') || str.contains('cancelled') || str.contains('canceled')) {
      return 'Google sign-in was cancelled.';
    }
    if (str.contains('origin_mismatch') || str.contains('access_denied') || str.contains('PERMISSION_DENIED')) {
      return 'Google sign-in permission denied. Please verify your connection or try again.';
    }
    if (str.contains('SocketException') || str.contains('network_error') || str.contains('Failed host lookup')) {
      return 'Network connection error. Please check your internet connection.';
    }
    if (str.startsWith('Exception:')) {
      return str.replaceFirst('Exception:', '').trim();
    }
    if (str.contains('"message":')) {
      final match = RegExp(r'"message":\s*"([^"]+)"').firstMatch(str);
      if (match != null && match.group(1) != null) {
        return match.group(1)!;
      }
    }
    return str.length > 100 ? '${str.substring(0, 97)}...' : str;
  }
}
