import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  String _username = '';
  bool _isLoading = false;

  bool get isLoggedIn => _isLoggedIn;
  String get username => _username;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _checkInitialAuth();
  }

  Future<void> _checkInitialAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final username = await AuthService.getStoredUsername();
      if (username != null && username.isNotEmpty) {
        _username = username;
        _isLoggedIn = true;
      }
    } catch (e) {
      debugPrint('Error checking initial auth: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await AuthService.login(username, password);
      if (success) {
        _username = username;
        _isLoggedIn = true;
        await switchUser(username);
      }
      return success;
    } catch (e) {
      debugPrint('Error during login: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await AuthService.logout();
      _isLoggedIn = false;
      _username = '';
      notifyListeners();
    } catch (e) {
      debugPrint('Error during logout: $e');
    }
  }
}
