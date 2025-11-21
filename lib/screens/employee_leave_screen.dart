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
  final _reasonController = TextEditingController();
  bool _isLoading = false;
  bool _isSubmitting = false;

  List<LeaveBalanceModel> _balances = [];
  List<LeaveRequestModel> _leaveRequests = [];
  int _numberOfDays = 0;

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
    if (_fromDate != null && _toDate != null) {
      setState(() {
        _numberOfDays = _toDate!.difference(_fromDate!).inDays + 1;
      });
    }
  }

  int _getRemainingLeaves(String leaveType) {
    final balance = _balances.firstWhere(
      (b) => b.leaveType == leaveType,
      orElse: () => LeaveBalanceModel(
        leaveType: leaveType,
        totalLeaves: 0,
        usedLeaves: 0,
        remainingLeaves: 0,
      ),
    );
    return balance.remainingLeaves;
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

    if (_fromDate == null || _toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select dates')),
      );
      return;
    }

    final remaining = _getRemainingLeaves(_selectedLeaveType!);
    if (remaining < _numberOfDays) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient leave balance. Available: $remaining, Requested: $_numberOfDays'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final result = await ApiService.createLeaveRequest(
      leaveType: _selectedLeaveType!,
      fromDate: DateFormat('yyyy-MM-dd').format(_fromDate!),
      toDate: DateFormat('yyyy-MM-dd').format(_toDate!),
      reason: _reasonController.text.trim(),
    );

    setState(() {
      _isSubmitting = false;
    });

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leave request submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _formKey.currentState!.reset();
      setState(() {
        _selectedLeaveType = null;
        _fromDate = null;
        _toDate = null;
        _numberOfDays = 0;
        _reasonController.clear();
      });
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to submit leave request'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate ? DateTime.now() : (_fromDate ?? DateTime.now()),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
          if (_toDate != null && _toDate!.isBefore(_fromDate!)) {
            _toDate = null;
          }
        } else {
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
                    // Leave Balance Cards
                    Text('Leave Balances', style: AppTheme.heading2),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: Constants.leaveTypes.length,
                        itemBuilder: (context, index) {
                          final leaveType = Constants.leaveTypes[index];
                          final remaining = _getRemainingLeaves(leaveType);
                          return Container(
                            width: 150,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: AppTheme.cardDecoration,
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
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$remaining',
                                  style: AppTheme.heading2.copyWith(
                                    color: AppTheme.primaryOrange,
                                  ),
                                ),
                                Text(
                                  'remaining',
                                  style: AppTheme.bodyTextSmall,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Leave Request Form
                    Text('Request Leave', style: AppTheme.heading2),
                    const SizedBox(height: 16),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Leave Type Dropdown
                          DropdownButtonFormField<String>(
                            decoration: AppTheme.inputDecoration('Leave Type', Icons.category),
                            value: _selectedLeaveType,
                            items: Constants.leaveTypes.map((type) {
                              final remaining = _getRemainingLeaves(type);
                              return DropdownMenuItem(
                                value: type,
                                child: Text('$type ($remaining remaining)'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedLeaveType = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a leave type';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // From Date
                          InkWell(
                            onTap: () => _selectDate(context, true),
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
                          // To Date
                          InkWell(
                            onTap: () => _selectDate(context, false),
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
                                  : const Text('Submit Leave Request'),
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
                          child: Text('No leave requests yet'),
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

