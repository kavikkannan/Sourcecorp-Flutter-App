import 'package:flutter/material.dart';
import '../models/leave_request_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/leave_card.dart';
import 'login_screen.dart';

class LeaveHistoryScreen extends StatefulWidget {
  const LeaveHistoryScreen({super.key});

  @override
  State<LeaveHistoryScreen> createState() => _LeaveHistoryScreenState();
}

class _LeaveHistoryScreenState extends State<LeaveHistoryScreen> {
  bool _isLoading = false;
  List<LeaveRequestModel> _leaveRequests = [];
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Pending', 'Approved', 'Rejected'];

  @override
  void initState() {
    super.initState();
    _loadLeaveRequests();
  }

  Future<void> _loadLeaveRequests() async {
    setState(() {
      _isLoading = true;
    });

    final result = await ApiService.getLeaveRequests(
      status: _selectedFilter == 'All' ? null : _selectedFilter,
    );

    if (result['success'] == true) {
      setState(() {
        _leaveRequests = result['data'] as List<LeaveRequestModel>;
        // Sort by created_at descending (most recent first)
        _leaveRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  List<LeaveRequestModel> _getFilteredRequests() {
    if (_selectedFilter == 'All') {
      return _leaveRequests;
    }
    return _leaveRequests.where((r) => r.status == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = AuthService.isAdmin();

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'All Leave History' : 'My Leave History'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                        _loadLeaveRequests();
                      },
                      selectedColor: AppTheme.primaryOrange,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.gray600,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Leave Requests List
          Expanded(
            child: _isLoading
                ? const LoadingIndicator()
                : RefreshIndicator(
                    onRefresh: _loadLeaveRequests,
                    child: _getFilteredRequests().isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.history,
                                  size: 64,
                                  color: AppTheme.gray200,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No leave requests found',
                                  style: AppTheme.bodyText.copyWith(
                                    color: AppTheme.gray600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _getFilteredRequests().length,
                            itemBuilder: (context, index) {
                              final request = _getFilteredRequests()[index];
                              return LeaveCard(
                                leaveRequest: request,
                                onTap: () {
                                  // Show detailed view
                                  showDialog(
                                    context: context,
                                    builder: (context) => _LeaveRequestDetailDialog(
                                      request: request,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LeaveRequestDetailDialog extends StatelessWidget {
  final LeaveRequestModel request;

  const _LeaveRequestDetailDialog({required this.request});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Leave Request Details',
                  style: AppTheme.heading2,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            _buildDetailRow('Employee', request.userName),
            _buildDetailRow('Leave Type', request.leaveType),
            _buildDetailRow('From Date', request.fromDate),
            _buildDetailRow('To Date', request.toDate),
            _buildDetailRow('Number of Days', '${request.numberOfDays}'),
            _buildDetailRow('Status', request.status),
            const SizedBox(height: 8),
            Text(
              'Reason:',
              style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.gray100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                request.reason,
                style: AppTheme.bodyText,
              ),
            ),
            if (request.remarks != null && request.remarks!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Remarks:',
                style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.gray100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  request.remarks!,
                  style: AppTheme.bodyText,
                ),
              ),
            ],
            if (request.approverName != null && request.approverName!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildDetailRow('Approved By', request.approverName!),
            ],
            const SizedBox(height: 8),
            _buildDetailRow('Created At', request.createdAt),
            _buildDetailRow('Updated At', request.updatedAt),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTheme.bodyText.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.gray600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodyText,
            ),
          ),
        ],
      ),
    );
  }
}

