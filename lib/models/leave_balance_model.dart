class LeaveBalanceModel {
  final String leaveType;
  final int totalLeaves;
  final int usedLeaves;
  final int remainingLeaves;

  LeaveBalanceModel({
    required this.leaveType,
    required this.totalLeaves,
    required this.usedLeaves,
    required this.remainingLeaves,
  });

  factory LeaveBalanceModel.fromJson(Map<String, dynamic> json) {
    return LeaveBalanceModel(
      leaveType: json['leave_type'] ?? '',
      totalLeaves: json['total_leaves'] ?? 0,
      usedLeaves: json['used_leaves'] ?? 0,
      remainingLeaves: json['remaining_leaves'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'leave_type': leaveType,
      'total_leaves': totalLeaves,
      'used_leaves': usedLeaves,
      'remaining_leaves': remainingLeaves,
    };
  }
}

