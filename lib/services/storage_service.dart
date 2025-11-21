import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // JWT Token
  static Future<void> saveToken(String token) async {
    await _prefs?.setString(Constants.jwtTokenKey, token);
  }

  static String? getToken() {
    return _prefs?.getString(Constants.jwtTokenKey);
  }

  static Future<void> removeToken() async {
    await _prefs?.remove(Constants.jwtTokenKey);
  }

  // User ID
  static Future<void> saveUserId(int userId) async {
    await _prefs?.setInt(Constants.userIdKey, userId);
  }

  static int? getUserId() {
    return _prefs?.getInt(Constants.userIdKey);
  }

  static Future<void> removeUserId() async {
    await _prefs?.remove(Constants.userIdKey);
  }

  // User Name
  static Future<void> saveUserName(String userName) async {
    await _prefs?.setString(Constants.userNameKey, userName);
  }

  static String? getUserName() {
    return _prefs?.getString(Constants.userNameKey);
  }

  // User Email
  static Future<void> saveUserEmail(String email) async {
    await _prefs?.setString(Constants.userEmailKey, email);
  }

  static String? getUserEmail() {
    return _prefs?.getString(Constants.userEmailKey);
  }

  // Is Admin
  static Future<void> saveIsAdmin(bool isAdmin) async {
    await _prefs?.setBool(Constants.isAdminKey, isAdmin);
  }

  static bool? getIsAdmin() {
    return _prefs?.getBool(Constants.isAdminKey);
  }

  // User Role
  static Future<void> saveUserRole(String role) async {
    await _prefs?.setString(Constants.userRoleKey, role);
  }

  static String? getUserRole() {
    return _prefs?.getString(Constants.userRoleKey);
  }

  // Clear all data
  static Future<void> clearAll() async {
    await _prefs?.clear();
  }
}

