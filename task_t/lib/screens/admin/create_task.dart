import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../models/task.dart';

class CreateTaskScreen extends StatefulWidget {
  @override
  _CreateTaskScreenState createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _deadline;
  bool _isLoading = false;
  bool _isLoadingInternees = true;
  
  List<Map<String, dynamic>> _internees = [];
  int? _selectedInterneeId;
  String? _selectedInterneeName;

  @override
  void initState() {
    super.initState();
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
        });
        print('Loaded ${internees.length} internees successfully');
      }
    } catch (e) {
      print('Error loading internees: $e');
      
      if (mounted) {
        setState(() => _isLoadingInternees = false);
        
        // Show error message
        _showErrorSnackBar('Failed to load internees: $e');
        
        // Try alternative method if main method fails
        _tryAlternativeLoadMethod();
      }
    }
  }

  // Alternative method to load internees if the main method fails
  Future<void> _tryAlternativeLoadMethod() async {
    if (!mounted) return;
    
    try {
      print('Trying alternative internees loading method...');
      setState(() => _isLoadingInternees = true);
      
      final apiService = Provider.of<ApiService>(context, listen: false);
      final internees = await apiService.getInterneesWithToken(context);
      
      if (mounted) {
        setState(() {
          _internees = internees;
          _isLoadingInternees = false;
        });
        print('Loaded ${internees.length} internees with alternative method');
      }
    } catch (e) {
      print('Alternative method also failed: $e');
      if (mounted) {
        setState(() => _isLoadingInternees = false);
        _showErrorSnackBar('Unable to load internees. Please check your connection and try again.');
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

  Future<void> _createTask() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedInterneeId == null) {
      _showErrorSnackBar('Please select an internee to assign the task');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final taskData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'assigned_to': _selectedInterneeId!,
        'deadline': _deadline?.toIso8601String(),
      };

      await Provider.of<ApiService>(context, listen: false)
          .createTask(context, taskData);

      if (mounted) {
        _showSuccessSnackBar('Task created and assigned to $_selectedInterneeName');
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      print('Create task error: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to create task: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDeadline(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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
          'Create Task',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.refresh, color: Colors.deepOrange),
              onPressed: _loadInternees,
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
                          Icons.add_task,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Create New Task',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Assign a new task to team members',
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
                      'Description (Optional)',
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
                        hintText: 'Provide task details and requirements...',
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

                // Assign To Internee Dropdown - COMPLETELY FIXED VERSION
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Assign To Internee',
                          style: TextStyle(
                            color: Colors.grey.shade300,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          ' *',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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
                                              'No internees found. Please add internees first or check your connection.',
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
                                          foregroundColor: Colors.white,
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
                                                color: Colors.deepOrange,
                                                fontSize: 14,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
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

                // Deadline Selection
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Deadline (Optional)',
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
                              ? 'Select deadline date'
                              : 'Deadline: ${_deadline!.toLocal()}'.split(' ')[0],
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

                // Create Task Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (_isLoading || _isLoadingInternees) ? null : _createTask,
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
                                Icons.add_task,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Create Task',
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
                SizedBox(height: 24),

                // // Debug Info (remove in production)
                // if (_internees.isNotEmpty)
                //   Container(
                //     padding: EdgeInsets.all(12),
                //     decoration: BoxDecoration(
                //       color: Colors.green.withOpacity(0.1),
                //       borderRadius: BorderRadius.circular(8),
                //       border: Border.all(color: Colors.green.withOpacity(0.3)),
                //     ),
                //     child: Row(
                //       children: [
                //         Icon(Icons.check_circle, color: Colors.green, size: 16),
                //         SizedBox(width: 8),
                //         Text(
                //           'Successfully loaded ${_internees.length} internees',
                //           style: TextStyle(
                //             color: Colors.green,
                //             fontSize: 12,
                //             fontWeight: FontWeight.w500,
                //           ),
                //         ),
                //       ],
                //     ),
                //   ),
                SizedBox(height: 16),

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
                              'Task Assignment Tips',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Select the appropriate internee and set realistic deadlines. The internee will receive the task assignment immediately.',
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
    TextInputType keyboardType = TextInputType.text,
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
          keyboardType: keyboardType,
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
}