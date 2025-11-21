import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user_model.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}${Constants.loginEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['code'] == 'LOGIN_SUCCESS') {
        // Extract JWT token from Set-Cookie header
        final cookies = response.headers['set-cookie'];
        String? jwtToken;
        if (cookies != null) {
          final cookieParts = cookies.split(';');
          for (var part in cookieParts) {
            if (part.trim().startsWith('jwt=')) {
              jwtToken = part.trim().substring(4);
              break;
            }
          }
        }
        
        if (jwtToken != null) {
          await StorageService.saveToken(jwtToken);
        }
        
        await StorageService.saveUserEmail(email);
        
        // Fetch user details
        final userResponse = await getUserInfo();
        if (userResponse['success'] == true) {
          final user = userResponse['user'] as UserModel;
          await StorageService.saveUserId(user.id);
          await StorageService.saveUserName(user.name);
          await StorageService.saveIsAdmin(user.isAdmin);
          await StorageService.saveUserRole(user.role);
        }

        return {
          'success': true,
          'message': 'Login successful',
          'user': userResponse['user'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Login failed',
          'code': data['code'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> getUserInfo() async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}${Constants.userEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'jwt=${StorageService.getToken() ?? ""}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = UserModel.fromJson(data);
        return {
          'success': true,
          'user': user,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch user info',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<void> logout() async {
    try {
      await http.post(
        Uri.parse('${Constants.baseUrl}/api/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'jwt=${StorageService.getToken() ?? ""}',
        },
      );
    } catch (e) {
      // Ignore errors on logout
    } finally {
      await StorageService.clearAll();
    }
  }

  static bool isAuthenticated() {
    return StorageService.getUserId() != null;
  }

  static bool isAdmin() {
    return StorageService.getIsAdmin() ?? false;
  }
}

