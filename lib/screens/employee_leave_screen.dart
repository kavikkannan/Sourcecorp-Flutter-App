import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/leave_request_model.dart';
import '../models/leave_balance_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/leave_card.dart';
import 'leave_history_screen.dart';
import 'login_screen.dart';

class EmployeeLeaveScreen extends StatefulWidget {
  const EmployeeLeaveScreen({super.key});

  @override
  State<EmployeeLeaveScreen> createState() => _EmployeeLeaveScreenState();
}

class _EmployeeLeaveScreenState extends State<EmployeeLeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedLeaveType;
  DateTime? _fromDate;
  DateTime? _toDate;
  DateTime? _permissionDate; // For permissions (single date)
  final _reasonController = TextEditingController();
  bool _isLoading = false;
  bool _isSubmitting = false;

  List<LeaveBalanceModel> _balances = [];
  List<LeaveRequestModel> _leaveRequests = [];
  int _numberOfDays = 0;

  bool get _isPermissionType => _selectedLeaveType != null && Constants.permissionTypes.contains(_selectedLeaveType!);
  bool get _isLeaveType => _selectedLeaveType == 'Leave';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    await Future.wait([
      _loadBalances(),
      _loadLeaveRequests(),
    ]);

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadBalances() async {
    final result = await ApiService.getLeaveBalances();
    if (result['success'] == true) {
      setState(() {
        _balances = result['data'] as List<LeaveBalanceModel>;
      });
    }
  }

  Future<void> _loadLeaveRequests() async {
    final result = await ApiService.getLeaveRequests();
    if (result['success'] == true) {
      setState(() {
        _leaveRequests = result['data'] as List<LeaveRequestModel>;
      });
    }
  }

  void _calculateDays() {
    if (_isLeaveType && _fromDate != null && _toDate != null) {
      setState(() {
        _numberOfDays = _toDate!.difference(_fromDate!).inDays + 1;
      });
    } else if (_isPermissionType) {
      // For permissions: 2 times = 1 day, so 1 time = 0.5 days
      setState(() {
        _numberOfDays = 1; // We'll track as 1 "time" in the backend
      });
    }
  }

  LeaveBalanceModel _getBalance(String leaveType) {
    return _balances.firstWhere(
      (b) => b.leaveType == leaveType,
      orElse: () => LeaveBalanceModel(
        leaveType: leaveType,
        totalLeaves: 0,
        usedLeaves: 0,
        remainingLeaves: 0,
      ),
    );
  }

  bool _isUnpaid(String leaveType) {
    final balance = _getBalance(leaveType);
    if (_isPermissionType) {
      // For permissions: 2 times = 1 day paid, after that unpaid
      // usedLeaves represents "times" used
      return balance.usedLeaves >= (balance.totalLeaves * 2);
    } else {
      // For leave: usedLeaves >= totalLeaves means unpaid
      return balance.usedLeaves >= balance.totalLeaves;
    }
  }

  Future<void> _submitLeaveRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedLeaveType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a leave type')),
      );
      return;
    }

    String fromDateStr;
    String toDateStr;

    if (_isLeaveType) {
      if (_fromDate == null || _toDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select from and to dates')),
        );
        return;
      }
      fromDateStr = DateFormat('yyyy-MM-dd').format(_fromDate!);
      toDateStr = DateFormat('yyyy-MM-dd').format(_toDate!);
    } else {
      // Permission type
      if (_permissionDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a date')),
        );
        return;
      }
      fromDateStr = DateFormat('yyyy-MM-dd').format(_permissionDate!);
      toDateStr = fromDateStr; // Same date for permissions
    }

    setState(() {
      _isSubmitting = true;
    });

    final result = await ApiService.createLeaveRequest(
      leaveType: _selectedLeaveType!,
      fromDate: fromDateStr,
      toDate: toDateStr,
      reason: _reasonController.text.trim(),
    );

    setState(() {
      _isSubmitting = false;
    });

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _formKey.currentState!.reset();
      setState(() {
        _selectedLeaveType = null;
        _fromDate = null;
        _toDate = null;
        _permissionDate = null;
        _numberOfDays = 0;
        _reasonController.clear();
      });
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to submit request'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectDate(BuildContext context, {bool isFromDate = false, bool isToDate = false, bool isPermission = false}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isPermission) {
          _permissionDate = picked;
        } else if (isFromDate) {
          _fromDate = picked;
          if (_toDate != null && _toDate!.isBefore(_fromDate!)) {
            _toDate = null;
          }
        } else if (isToDate) {
          if (_fromDate == null || picked.isAfter(_fromDate!) || picked.isAtSameMomentAs(_fromDate!)) {
            _toDate = picked;
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('To date must be after from date')),
            );
            return;
          }
        }
        _calculateDays();
      });
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Management'),
        backgroundColor: AppTheme.primaryOrange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LeaveHistoryScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.logout();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Leave Balance Cards - Show "Taken" stats
                    Text('Leave Statistics', style: AppTheme.heading2),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: Constants.getAllTypes().length,
                        itemBuilder: (context, index) {
                          final leaveType = Constants.getAllTypes()[index];
                          final balance = _getBalance(leaveType);
                          final isUnpaid = _isUnpaid(leaveType);
                          final isPermission = Constants.permissionTypes.contains(leaveType);
                          
                          return Container(
                            width: 160,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: AppTheme.cardDecoration.copyWith(
                              color: isUnpaid ? Colors.red.shade50 : Colors.white,
                              border: Border.all(
                                color: isUnpaid ? Colors.red : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  leaveType,
                                  style: AppTheme.bodyTextSmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${balance.usedLeaves}',
                                  style: AppTheme.heading2.copyWith(
                                    color: isUnpaid ? Colors.red : AppTheme.primaryOrange,
                                  ),
                                ),
                                Text(
                                  isPermission ? 'times taken' : 'days taken',
                                  style: AppTheme.bodyTextSmall,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      isUnpaid ? Icons.cancel : Icons.check_circle,
                                      size: 12,
                                      color: isUnpaid ? Colors.red : Colors.green,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isUnpaid ? 'Unpaid' : 'Paid',
                                      style: AppTheme.bodyTextSmall.copyWith(
                                        color: isUnpaid ? Colors.red : Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Leave Request Form
                    Text('Request Leave/Permission', style: AppTheme.heading2),
                    const SizedBox(height: 16),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Leave Type Dropdown
                          DropdownButtonFormField<String>(
                            decoration: AppTheme.inputDecoration('Leave/Permission Type', Icons.category),
                            value: _selectedLeaveType,
                            items: [
                              // Leave option
                              ...Constants.leaveTypes.map((type) {
                                final balance = _getBalance(type);
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text('$type (${balance.usedLeaves} days taken)'),
                                );
                              }),
                              // Permission options
                              ...Constants.permissionTypes.map((type) {
                                final balance = _getBalance(type);
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text('$type (${balance.usedLeaves} times taken)'),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedLeaveType = value;
                                // Reset dates when type changes
                                _fromDate = null;
                                _toDate = null;
                                _permissionDate = null;
                                _numberOfDays = 0;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a type';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Date Selection based on type
                          if (_isLeaveType) ...[
                            // From Date for Leave
                            InkWell(
                              onTap: () => _selectDate(context, isFromDate: true),
                              child: InputDecorator(
                                decoration: AppTheme.inputDecoration('From Date', Icons.calendar_today),
                                child: Text(
                                  _fromDate == null
                                      ? 'Select from date'
                                      : DateFormat('yyyy-MM-dd').format(_fromDate!),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // To Date for Leave
                            InkWell(
                              onTap: () => _selectDate(context, isToDate: true),
                              child: InputDecorator(
                                decoration: AppTheme.inputDecoration('To Date', Icons.calendar_today),
                                child: Text(
                                  _toDate == null
                                      ? 'Select to date'
                                      : DateFormat('yyyy-MM-dd').format(_toDate!),
                                ),
                              ),
                            ),
                            if (_numberOfDays > 0) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Number of days: $_numberOfDays',
                                style: AppTheme.bodyText.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryOrange,
                                ),
                              ),
                            ],
                          ] else if (_isPermissionType) ...[
                            // Single Date for Permissions
                            InkWell(
                              onTap: () => _selectDate(context, isPermission: true),
                              child: InputDecorator(
                                decoration: AppTheme.inputDecoration('Date', Icons.calendar_today),
                                child: Text(
                                  _permissionDate == null
                                      ? 'Select date'
                                      : DateFormat('yyyy-MM-dd').format(_permissionDate!),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '1 time = 0.5 days (2 times = 1 day)',
                              style: AppTheme.bodyTextSmall.copyWith(
                                color: AppTheme.gray600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          // Reason
                          TextFormField(
                            controller: _reasonController,
                            decoration: AppTheme.inputDecoration('Reason', Icons.note),
                            maxLines: 3,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a reason';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _submitLeaveRequest,
                              style: AppTheme.primaryButtonStyle,
                              child: _isSubmitting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text('Submit Request'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Recent Leave Requests
                    Text('Recent Requests', style: AppTheme.heading2),
                    const SizedBox(height: 16),
                    if (_leaveRequests.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('No requests yet'),
                        ),
                      )
                    else
                      ..._leaveRequests.take(5).map((request) => LeaveCard(
                            leaveRequest: request,
                          )),
                  ],
                ),
              ),
            ),
    );
  }
}
