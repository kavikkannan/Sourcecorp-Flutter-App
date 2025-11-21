import 'package:flutter/material.dart';
import '../models/leave_request_model.dart';
import '../utils/theme.dart';

class LeaveCard extends StatelessWidget {
  final LeaveRequestModel leaveRequest;
  final VoidCallback? onTap;
  final bool showActions;
  final Function(String, String)? onApprove;
  final Function(String, String)? onReject;

  const LeaveCard({
    super.key,
    required this.leaveRequest,
    this.onTap,
    this.showActions = false,
    this.onApprove,
    this.onReject,
  });

  Color getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return AppTheme.green;
      case 'Rejected':
        return AppTheme.red;
      case 'Pending':
        return AppTheme.yellow;
      default:
        return AppTheme.gray600;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      leaveRequest.userName,
                      style: AppTheme.heading3,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: getStatusColor(leaveRequest.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      leaveRequest.status,
                      style: TextStyle(
                        color: getStatusColor(leaveRequest.status),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: AppTheme.gray600),
                  const SizedBox(width: 8),
                  Text(
                    '${leaveRequest.fromDate} to ${leaveRequest.toDate}',
                    style: AppTheme.bodyTextSmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.category, size: 16, color: AppTheme.gray600),
                  const SizedBox(width: 8),
                  Text(
                    leaveRequest.leaveType,
                    style: AppTheme.bodyTextSmall,
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.event, size: 16, color: AppTheme.gray600),
                  const SizedBox(width: 8),
                  Text(
                    '${leaveRequest.numberOfDays} day${leaveRequest.numberOfDays > 1 ? 's' : ''}',
                    style: AppTheme.bodyTextSmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                leaveRequest.reason,
                style: AppTheme.bodyText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (leaveRequest.remarks != null && leaveRequest.remarks!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.gray100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.comment, size: 16, color: AppTheme.gray600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Remarks: ${leaveRequest.remarks}',
                          style: AppTheme.bodyTextSmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (showActions && leaveRequest.status == 'Pending') ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => _RemarksDialog(
                            title: 'Reject Leave Request',
                            onSubmit: (remarks) {
                              if (onReject != null) {
                                onReject!(leaveRequest.id.toString(), remarks);
                              }
                            },
                          ),
                        );
                      },
                      child: const Text('Reject', style: TextStyle(color: AppTheme.red)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => _RemarksDialog(
                            title: 'Approve Leave Request',
                            onSubmit: (remarks) {
                              if (onApprove != null) {
                                onApprove!(leaveRequest.id.toString(), remarks);
                              }
                            },
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Approve'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RemarksDialog extends StatefulWidget {
  final String title;
  final Function(String) onSubmit;

  const _RemarksDialog({required this.title, required this.onSubmit});

  @override
  State<_RemarksDialog> createState() => _RemarksDialogState();
}

class _RemarksDialogState extends State<_RemarksDialog> {
  final _remarksController = TextEditingController();

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _remarksController,
        decoration: const InputDecoration(
          labelText: 'Remarks (optional)',
          hintText: 'Enter remarks...',
        ),
        maxLines: 3,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSubmit(_remarksController.text);
            Navigator.pop(context);
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }
}

