import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'storage_service.dart';

class AuthService {
  static const _keyUsername = 'username';
  static const _keyPassword = 'password';
  static const _keyPin = 'user_pin';
  static const _secureStorage = FlutterSecureStorage();

  static Future<void> saveCredentials(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsername, username);
    await _secureStorage.write(key: _keyPassword, value: password);
  }

  static Future<bool> login(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final storedUser = prefs.getString(_keyUsername);
    final storedPass = await _secureStorage.read(key: _keyPassword);

    if (storedUser == null || storedPass == null) {
      await saveCredentials(username, password);
      await switchUser(username);
      return true;
    }

    if (storedUser == username && storedPass == password) {
      await switchUser(username);
      return true;
    }

    return false;
  }

  static Future<void> savePin(String pin) async {
    await _secureStorage.write(key: _keyPin, value: pin);
  }

  static Future<bool> hasPin() async {
    final pin = await _secureStorage.read(key: _keyPin);
    return pin != null && pin.isNotEmpty;
  }

  static Future<bool> validatePin(String pin) async {
    final storedPin = await _secureStorage.read(key: _keyPin);
    return storedPin == pin;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUsername);
    await _secureStorage.delete(key: _keyPassword);
  }

  static Future<String?> getStoredUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername);
  }
}
