import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../models/task.dart';

class EditTaskScreen extends StatefulWidget {
  final Task task;

  EditTaskScreen({required this.task});

  @override
  _EditTaskScreenState createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late String _status;
  DateTime? _deadline;
  bool _isLoading = false;
  bool _isLoadingInternees = true;
  
  List<Map<String, dynamic>> _internees = [];
  int? _selectedInterneeId;
  String? _selectedInterneeName;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(text: widget.task.description);
    _status = widget.task.status;
    _deadline = widget.task.deadline;
    
    // Delay the API call to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInternees();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadInternees() async {
    if (!mounted) return;
    
    try {
      setState(() => _isLoadingInternees = true);
      
      final apiService = Provider.of<ApiService>(context, listen: false);
      final internees = await apiService.getInternees(context);
      
      if (mounted) {
        setState(() {
          _internees = internees;
          _isLoadingInternees = false;
          
          // Find and set the currently assigned internee
          final currentAssignee = internees.firstWhere(
            (internee) => internee['name'] == widget.task.assignedTo,
            orElse: () => {},
          );
          
          if (currentAssignee.isNotEmpty) {
            _selectedInterneeId = currentAssignee['id'];
            _selectedInterneeName = currentAssignee['name'];
          }
        });
        print('Loaded ${internees.length} internees successfully');
      }
    } catch (e) {
      print('Error loading internees: $e');
      
      if (mounted) {
        setState(() => _isLoadingInternees = false);
        _showErrorSnackBar('Failed to load internees: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
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

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _updateTask() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedInterneeId == null) {
      _showErrorSnackBar('Please select an internee to assign the task');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updates = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'status': _status,
        'assigned_to': _selectedInterneeId,
        'deadline': _deadline?.toIso8601String(),
      };

      await Provider.of<ApiService>(context, listen: false)
          .updateTask(context, widget.task.id, updates);

      if (mounted) {
        _showSuccessSnackBar('Task updated and assigned to $_selectedInterneeName');
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      print('Update task error: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to update task: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteTask() async {
    try {
      await Provider.of<ApiService>(context, listen: false)
          .deleteTask(context, widget.task.id);
      
      if (mounted) {
        _showSuccessSnackBar('Task deleted successfully');
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to delete task: $e');
      }
    }
  }

  Future<void> _selectDeadline(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.deepOrange,
              onPrimary: Colors.white,
              surface: Colors.grey.shade900,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _deadline = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade900,
        elevation: 0,
        leading: Container(
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          'Edit Task',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.refresh, color: Colors.deepOrange),
              onPressed: _loadInternees,
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _showDeleteDialog,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepOrange.withOpacity(0.3),
                              blurRadius: 15,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.edit_note,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Edit Task',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Update task details and assignment',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 40),

                // Task Title Field
                _buildInputField(
                  label: 'Task Title',
                  controller: _titleController,
                  icon: Icons.title,
                  hint: 'Enter task title',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a task title';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // Task Description Field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Description',
                      style: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Task description and requirements...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        filled: true,
                        fillColor: Colors.grey.shade900,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.deepOrange, width: 2),
                        ),
                        contentPadding: EdgeInsets.all(16),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // Assign To Internee Dropdown - FIXED VERSION
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reassign To Internee',
                      style: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _isLoadingInternees
                          ? Container(
                              padding: EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      color: Colors.deepOrange,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Loading internees...',
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : _internees.isEmpty
                              ? Container(
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.warning_outlined,
                                            color: Colors.orange,
                                            size: 20,
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'No internees found. Please add internees first.',
                                              style: TextStyle(
                                                color: Colors.orange,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 12),
                                      ElevatedButton.icon(
                                        onPressed: _loadInternees,
                                        icon: Icon(Icons.refresh, size: 16),
                                        label: Text('Retry Loading'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.deepOrange,
                                          foregroundColor: Colors.black,
                                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : DropdownButtonFormField<int>(
                                  value: _selectedInterneeId,
                                  style: TextStyle(color: Colors.white),
                                  dropdownColor: Colors.grey.shade800,
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(Icons.person_outline, color: Colors.deepOrange),
                                    hintText: 'Select internee to assign task',
                                    hintStyle: TextStyle(color: Colors.grey.shade500),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.deepOrange, width: 2),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  ),
                                  icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade400),
                                  items: _internees.map<DropdownMenuItem<int>>((internee) {
                                    bool isCurrentAssignee = internee['name'] == widget.task.assignedTo;
                                    return DropdownMenuItem<int>(
                                      value: internee['id'],
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.deepOrange.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Icon(
                                              Icons.person,
                                              color: Colors.deepOrange,
                                              size: 12,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '${internee['name'] ?? 'Unknown'} (${internee['email'] ?? ''})',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 14,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                          // Show current assignment indicator
                                          if (isCurrentAssignee)
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.green.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'Current',
                                                style: TextStyle(
                                                  color: Colors.green,
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedInterneeId = value;
                                      // Find the selected internee's name
                                      final selectedInternee = _internees.firstWhere(
                                        (internee) => internee['id'] == value,
                                        orElse: () => {},
                                      );
                                      _selectedInterneeName = selectedInternee['name'];
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Please select an internee';
                                    }
                                    return null;
                                  },
                                  isExpanded: true,
                                ),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // Status Selection
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Task Status',
                      style: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _status,
                        style: TextStyle(color: Colors.white),
                        dropdownColor: Colors.grey.shade800,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.flag_outlined, color: Colors.deepOrange),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.deepOrange, width: 2),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade400),
                        items: [
                          DropdownMenuItem(
                            value: 'pending',
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade400,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Pending', style: TextStyle(color: Colors.black)),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'in_progress',
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.deepOrange,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('In Progress', style: TextStyle(color: Colors.deepOrange)),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'completed',
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Completed', style: TextStyle(color: Colors.green)),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _status = value!;
                          });
                        },
                        isExpanded: true,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // Deadline Selection
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Deadline',
                      style: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Icon(
                          Icons.calendar_today,
                          color: Colors.deepOrange,
                        ),
                        title: Text(
                          _deadline == null
                              ? 'No deadline set'
                              : 'Due: ${_deadline!.toLocal()}'.split(' ')[0],
                          style: TextStyle(
                            color: _deadline == null ? Colors.grey.shade500 : Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        trailing: _deadline != null
                            ? IconButton(
                                icon: Icon(Icons.clear, color: Colors.grey.shade400),
                                onPressed: () {
                                  setState(() {
                                    _deadline = null;
                                  });
                                },
                              )
                            : null,
                        onTap: () => _selectDeadline(context),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 32),

                // Update Task Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (_isLoading || _isLoadingInternees) ? null : _updateTask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      disabledBackgroundColor: Colors.deepOrange.withOpacity(0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.save,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Update Task',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                SizedBox(height: 20),

                // Info Card
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade800),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Task Update Tips',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'You can reassign tasks, update status, and modify deadlines. All changes will be reflected immediately.',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade300,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade500),
            prefixIcon: Icon(icon, color: Colors.deepOrange),
            filled: true,
            fillColor: Colors.grey.shade900,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.deepOrange, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red, width: 2),
            ),
            errorStyle: TextStyle(color: Colors.red),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: validator,
        ),
      ],
    );
  }

  void _showDeleteDialog() {
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
              _deleteTask();
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
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1).toLowerCase()}";
  }
}