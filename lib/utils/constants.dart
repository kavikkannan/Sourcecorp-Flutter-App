class Constants {
  // API Configuration
  static const String baseUrl = 'https://vfinserv.in';
  static const String loginEndpoint = '/api/login';
  static const String userEndpoint = '/api/user';
  static const String leaveRequestEndpoint = '/api/leave/request';
  static const String leaveRequestsEndpoint = '/api/leave/requests';
  static const String leaveRequestByIdEndpoint = '/api/leave/request';
  static const String updateLeaveStatusEndpoint = '/api/leave/request';
  static const String leaveBalancesEndpoint = '/api/leave/balances';
  static const String leaveBalancesByUserIdEndpoint = '/api/leave/balances';

  // Storage Keys
  static const String jwtTokenKey = 'jwt_token';
  static const String userIdKey = 'user_id';
  static const String userNameKey = 'user_name';
  static const String userEmailKey = 'user_email';
  static const String isAdminKey = 'is_admin';
  static const String userRoleKey = 'user_role';

  // Leave Types
  static const List<String> leaveTypes = [
    'Sick Leave',
    'Casual Leave',
    'Annual Leave',
    'Personal Leave',
  ];

  // Leave Status
  static const String statusPending = 'Pending';
  static const String statusApproved = 'Approved';
  static const String statusRejected = 'Rejected';
}

