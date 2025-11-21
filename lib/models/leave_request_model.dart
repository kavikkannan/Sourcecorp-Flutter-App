class LeaveRequestModel {
  final int id;
  final int userId;
  final String userName;
  final String leaveType;
  final String fromDate;
  final String toDate;
  final int numberOfDays;
  final String reason;
  final String status;
  final String? remarks;
  final int? approvedBy;
  final String? approverName;
  final String createdAt;
  final String updatedAt;

  LeaveRequestModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.leaveType,
    required this.fromDate,
    required this.toDate,
    required this.numberOfDays,
    required this.reason,
    required this.status,
    this.remarks,
    this.approvedBy,
    this.approverName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LeaveRequestModel.fromJson(Map<String, dynamic> json) {
    return LeaveRequestModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      userName: json['user_name'] ?? '',
      leaveType: json['leave_type'] ?? '',
      fromDate: json['from_date'] ?? '',
      toDate: json['to_date'] ?? '',
      numberOfDays: json['number_of_days'] ?? 0,
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'Pending',
      remarks: json['remarks'],
      approvedBy: json['approved_by'],
      approverName: json['approver_name'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'leave_type': leaveType,
      'from_date': fromDate,
      'to_date': toDate,
      'number_of_days': numberOfDays,
      'reason': reason,
      'status': status,
      'remarks': remarks,
      'approved_by': approvedBy,
      'approver_name': approverName,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

