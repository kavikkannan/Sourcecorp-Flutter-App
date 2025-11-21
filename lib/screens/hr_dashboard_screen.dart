import 'package:flutter/material.dart';
import '../models/leave_request_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/leave_card.dart';
import 'leave_history_screen.dart';
import 'login_screen.dart';

class HRDashboardScreen extends StatefulWidget {
  const HRDashboardScreen({super.key});

  @override
  State<HRDashboardScreen> createState() => _HRDashboardScreenState();
}

class _HRDashboardScreenState extends State<HRDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<LeaveRequestModel> _allRequests = [];
  List<LeaveRequestModel> _pendingRequests = [];
  List<LeaveRequestModel> _approvedRequests = [];
  List<LeaveRequestModel> _rejectedRequests = [];

  String _selectedStatus = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadLeaveRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaveRequests() async {
    setState(() {
      _isLoading = true;
    });

    final result = await ApiService.getLeaveRequests();
    if (result['success'] == true) {
      setState(() {
        _allRequests = result['data'] as List<LeaveRequestModel>;
        _pendingRequests = _allRequests.where((r) => r.status == 'Pending').toList();
        _approvedRequests = _allRequests.where((r) => r.status == 'Approved').toList();
        _rejectedRequests = _allRequests.where((r) => r.status == 'Rejected').toList();
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  List<LeaveRequestModel> _getFilteredRequests() {
    List<LeaveRequestModel> requests;
    switch (_tabController.index) {
      case 0:
        requests = _pendingRequests;
        break;
      case 1:
        requests = _approvedRequests;
        break;
      case 2:
        requests = _rejectedRequests;
        break;
      default:
        requests = _allRequests;
    }

    if (_searchQuery.isNotEmpty) {
      requests = requests.where((r) {
        return r.userName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            r.leaveType.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            r.reason.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return requests;
  }

  Future<void> _handleApprove(String requestId, String remarks) async {
    final result = await ApiService.updateLeaveStatus(
      requestId: int.parse(requestId),
      status: Constants.statusApproved,
      remarks: remarks,
    );

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leave request approved'),
          backgroundColor: Colors.green,
        ),
      );
      _loadLeaveRequests();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to approve request'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleReject(String requestId, String remarks) async {
    final result = await ApiService.updateLeaveStatus(
      requestId: int.parse(requestId),
      status: Constants.statusRejected,
      remarks: remarks,
    );

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leave request rejected'),
          backgroundColor: Colors.red,
        ),
      );
      _loadLeaveRequests();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to reject request'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HR Dashboard'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Pending'),
                  if (_pendingRequests.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_pendingRequests.length}',
                        style: const TextStyle(
                          color: AppTheme.primaryBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Approved'),
            const Tab(text: 'Rejected'),
          ],
          onTap: (index) {
            setState(() {});
          },
        ),
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
      body: Column(
        children: [
          // Statistics Cards
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.gray100,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard('Pending', _pendingRequests.length, AppTheme.yellow),
                _buildStatCard('Approved', _approvedRequests.length, AppTheme.green),
                _buildStatCard('Rejected', _rejectedRequests.length, AppTheme.red),
              ],
            ),
          ),
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name, type, or reason...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
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
                                  Icons.inbox,
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
                                showActions: _tabController.index == 0,
                                onApprove: _handleApprove,
                                onReject: _handleReject,
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTheme.bodyTextSmall,
          ),
        ],
      ),
    );
  }
}

