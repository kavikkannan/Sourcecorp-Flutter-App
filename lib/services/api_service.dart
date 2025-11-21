import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/leave_request_model.dart';
import '../models/leave_balance_model.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

class ApiService {
  static Map<String, String> getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Cookie': 'jwt=${StorageService.getToken() ?? ""}',
    };
  }

  // Create Leave Request
  static Future<Map<String, dynamic>> createLeaveRequest({
    required String leaveType,
    required String fromDate,
    required String toDate,
    required String reason,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}${Constants.leaveRequestEndpoint}'),
        headers: getHeaders(),
        body: jsonEncode({
          'leave_type': leaveType,
          'from_date': fromDate,
          'to_date': toDate,
          'reason': reason,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        return {
          'success': true,
          'message': data['message'] ?? 'Leave request created successfully',
          'id': data['id'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to create leave request',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get Leave Requests
  static Future<Map<String, dynamic>> getLeaveRequests({
    String? status,
    String? userId,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (userId != null && userId.isNotEmpty) queryParams['user_id'] = userId;
      if (fromDate != null && fromDate.isNotEmpty) queryParams['from_date'] = fromDate;
      if (toDate != null && toDate.isNotEmpty) queryParams['to_date'] = toDate;

      final uri = Uri.parse('${Constants.baseUrl}${Constants.leaveRequestsEndpoint}')
          .replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final response = await http.get(
        uri,
        headers: getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final requests = (data['data'] as List)
              .map((json) => LeaveRequestModel.fromJson(json))
              .toList();
          return {
            'success': true,
            'data': requests,
            'count': data['count'] ?? requests.length,
          };
        }
      }

      return {
        'success': false,
        'message': 'Failed to fetch leave requests',
        'data': <LeaveRequestModel>[],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': <LeaveRequestModel>[],
      };
    }
  }

  // Get Leave Request by ID
  static Future<Map<String, dynamic>> getLeaveRequestById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}${Constants.leaveRequestByIdEndpoint}/$id'),
        headers: getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return {
            'success': true,
            'data': LeaveRequestModel.fromJson(data['data']),
          };
        }
      }

      return {
        'success': false,
        'message': 'Failed to fetch leave request',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Update Leave Status (HR only)
  static Future<Map<String, dynamic>> updateLeaveStatus({
    required int requestId,
    required String status,
    String? remarks,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}${Constants.updateLeaveStatusEndpoint}/$requestId/status'),
        headers: getHeaders(),
        body: jsonEncode({
          'status': status,
          'remarks': remarks ?? '',
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        return {
          'success': true,
          'message': data['message'] ?? 'Leave request status updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update leave request status',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get Leave Balances
  static Future<Map<String, dynamic>> getLeaveBalances({int? userId}) async {
    try {
      final uri = userId != null
          ? Uri.parse('${Constants.baseUrl}${Constants.leaveBalancesByUserIdEndpoint}/$userId')
          : Uri.parse('${Constants.baseUrl}${Constants.leaveBalancesEndpoint}');

      final response = await http.get(
        uri,
        headers: getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final balances = (data['data'] as List)
              .map((json) => LeaveBalanceModel.fromJson(json))
              .toList();
          return {
            'success': true,
            'data': balances,
          };
        }
      }

      return {
        'success': false,
        'message': 'Failed to fetch leave balances',
        'data': <LeaveBalanceModel>[],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': <LeaveBalanceModel>[],
      };
    }
  }
}

