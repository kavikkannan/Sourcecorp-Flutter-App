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
    'Leave', // From date to date
  ];

  // Permission Types
  static const List<String> permissionTypes = [
    '1hr permission',
    '10 min permission',
    '5 mins permission',
  ];

  // All leave and permission types combined
  static List<String> getAllTypes() {
    return [...leaveTypes, ...permissionTypes];
  }

  // Leave Status
  static const String statusPending = 'Pending';
  static const String statusApproved = 'Approved';
  static const String statusRejected = 'Rejected';
}

