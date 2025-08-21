// Fixed TaskCard Component with proper imports and StatefulWidget
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task.dart';
import '../../services/api_service.dart';
import '../screens/admin/edit_task.dart'; // Fixed import path

class TaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback? onTaskUpdated;
  final String userRole;
  final int? userId;

  TaskCard({
    required this.task,
    required this.onTap,
    this.onTaskUpdated,
    required this.userRole,
    this.userId,
  });

  @override
  _TaskCardState createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade800),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with status and action buttons
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getStatusColor(widget.task.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getStatusIcon(widget.task.status),
                        color: _getStatusColor(widget.task.status),
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.task.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Status badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(widget.task.status).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _getStatusColor(widget.task.status),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        widget.task.status.replaceAll('_', ' ').capitalize(),
                        style: TextStyle(
                          color: _getStatusColor(widget.task.status),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 12),
                
                // Description
                if (widget.task.description != null && widget.task.description!.isNotEmpty) ...[
                  Text(
                    widget.task.description!,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 12),
                ],

                // Assigned to section
                if (widget.task.assignedTo != null && widget.task.assignedTo!.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        color: Colors.grey.shade400,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Assigned to: ${widget.task.assignedTo}',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                ],
                
                // Bottom row with deadline and actions
                Row(
                  children: [
                    // Deadline info
                    if (widget.task.deadline != null) ...[
                      Icon(
                        Icons.schedule,
                        color: _isOverdue(widget.task.deadline!) ? Colors.red : Colors.grey.shade400,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Due: ${widget.task.deadline!.toLocal()}'.split(' ')[0],
                        style: TextStyle(
                          color: _isOverdue(widget.task.deadline!) ? Colors.red : Colors.grey.shade400,
                          fontSize: 14,
                          fontWeight: _isOverdue(widget.task.deadline!) ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ] else ...[
                      Text(
                        'No deadline set',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                    
                    Spacer(),
                    
                    // Role-based action buttons
                    if (widget.userRole == 'admin') ...[
                      // Edit button for admin
                      Container(
                        margin: EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => _editTask(context),
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(
                                Icons.edit_outlined,
                                color: Colors.blue,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // Delete button for admin
                      Container(
                        margin: EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => _showDeleteConfirmation(context),
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ] else if (widget.userRole == 'internee' && 
                               widget.task.status != 'completed' &&
                               _isTaskAssignedToUser()) ...[
                      // Mark as Complete button for internee (only for their own incomplete tasks)
                      Container(
                        margin: EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => _showMarkCompleteDialog(context),
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(
                                Icons.check_circle_outline,
                                color: Colors.green,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    
                    // Regular arrow for navigation (only show if no admin actions)
                    if (widget.userRole != 'admin') ...[
                      SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.deepOrange,
                        size: 20,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isOverdue(DateTime deadline) {
    return DateTime.now().isAfter(deadline) && widget.task.status != 'completed';
  }

  bool _isTaskAssignedToUser() {
    // Check if task is assigned to the current user
    if (widget.userId != null && widget.task.assignedToId != null) {
      return widget.task.assignedToId == widget.userId;
    }
    return false;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.deepOrange;
      case 'pending':
      default:
        return Colors.grey.shade400;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle_outline;
      case 'in_progress':
        return Icons.hourglass_empty;
      case 'pending':
      default:
        return Icons.radio_button_unchecked;
    }
  }

  void _editTask(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTaskScreen(task: widget.task),
      ),
    );
    
    // If task was updated, refresh the parent list
    if (result == true && widget.onTaskUpdated != null) {
      widget.onTaskUpdated!();
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_outlined,
              color: Colors.red,
              size: 28,
            ),
            SizedBox(width: 12),
            Text(
              'Delete Task',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this task?',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.red, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone.',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Task: ${widget.task.title}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTask(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showMarkCompleteDialog(BuildContext context) {
    final TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 28,
            ),
            SizedBox(width: 12),
            Text(
              'Mark as Complete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task: ${widget.task.title}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Please provide a brief description of your work:',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              style: TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Describe what you accomplished...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                filled: true,
                fillColor: Colors.grey.shade800,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.green, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (descriptionController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please provide a description'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(context);
              _markAsComplete(context, descriptionController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Mark Complete',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteTask(BuildContext context) async {
    try {
      await Provider.of<ApiService>(context, listen: false)
          .deleteTask(context, widget.task.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Task "${widget.task.title}" deleted successfully',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        
        // Refresh the parent list
        if (widget.onTaskUpdated != null) {
          widget.onTaskUpdated!();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to delete task: $e',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _markAsComplete(BuildContext context, String description) async {
    try {
      print('Marking task ${widget.task.id} as complete with description: $description');
      
      // Use the new combined method from ApiService
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      // First submit the task with description
      await apiService.submitTask(context, widget.task.id, {
        'description': description,
        'attachment_url': null,
      });
      
      // Then update task status to completed
      await apiService.updateTask(context, widget.task.id, {
        'status': 'completed',
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Task marked as complete successfully!',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        
        // Refresh the parent list
        if (widget.onTaskUpdated != null) {
          widget.onTaskUpdated!();
        }
      }
    } catch (e) {
      print('Mark complete error: $e');
      if (mounted) {
        String errorMessage = 'Failed to mark task as complete';
        
        // Parse the error for better user feedback
        if (e.toString().contains('Validation error')) {
          errorMessage = e.toString().replaceFirst('Exception: ', '');
        } else if (e.toString().contains('Authentication failed')) {
          errorMessage = 'Please login again';
        } else {
          errorMessage = 'Failed to mark task as complete: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }
}

// Extension removed - using the one from utils/helpers.dart or edit_task.dart