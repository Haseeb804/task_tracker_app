import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';

class CreateReportScreen extends StatefulWidget {
  @override
  _CreateReportScreenState createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentsController = TextEditingController();
  final _tasksCompletedController = TextEditingController();
  final _tasksPendingController = TextEditingController();
  
  DateTime? _periodStart;
  DateTime? _periodEnd;
  bool _isLoading = false;
  bool _isLoadingInternees = true;
  
  List<Map<String, dynamic>> _internees = [];
  int? _selectedInterneeId;
  String? _selectedInterneeName;
  String _selectedPerformance = 'Good';
  
  final List<String> _performanceOptions = [
    'Excellent',
    'Good', 
    'Average',
    'Poor'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInternees();
    });
  }

  @override
  void dispose() {
    _commentsController.dispose();
    _tasksCompletedController.dispose();
    _tasksPendingController.dispose();
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
        _showErrorSnackBar('Failed to load internees: $e');
        
        // Try alternative method
        _tryAlternativeLoadMethod();
      }
    }
  }

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
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: 5),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _createReport() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedInterneeId == null) {
      _showErrorSnackBar('Please select an internee for the report');
      return;
    }

    if (_periodStart == null || _periodEnd == null) {
      _showErrorSnackBar('Please select both start and end dates for the report period');
      return;
    }

    if (_periodStart!.isAfter(_periodEnd!)) {
      _showErrorSnackBar('Start date must be before end date');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create the report data with all required fields
      final reportData = {
        'internee_id': _selectedInterneeId!,
        'period_start': _formatDate(_periodStart!),
        'period_end': _formatDate(_periodEnd!),
        'tasks_completed': int.parse(_tasksCompletedController.text.trim()),
        'tasks_pending': int.parse(_tasksPendingController.text.trim()),
        'overall_performance': _selectedPerformance,
        'comments': _commentsController.text.trim().isEmpty ? null : _commentsController.text.trim(),
      };

      print('Creating report with data: $reportData'); // Debug log

      await Provider.of<ApiService>(context, listen: false)
          .createProgressReport(context, reportData);

      if (mounted) {
        _showSuccessSnackBar('Progress report created successfully for $_selectedInterneeName');
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      print('Create report error: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to create report: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _periodStart ?? DateTime.now() : _periodEnd ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
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
        if (isStartDate) {
          _periodStart = picked;
        } else {
          _periodEnd = picked;
        }
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
          'Create Progress Report',
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
                          Icons.assessment,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Create Progress Report',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Generate performance report for internee',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 40),

                // Select Internee Dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Select Internee',
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
                                    hintText: 'Select internee for report',
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
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedInterneeId = value;
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

                // Period Selection
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Period Start',
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
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: Icon(Icons.date_range, color: Colors.deepOrange),
                              title: Text(
                                _periodStart == null
                                    ? 'Select start date'
                                    : _formatDate(_periodStart!),
                                style: TextStyle(
                                  color: _periodStart == null ? Colors.grey.shade500 : Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              onTap: () => _selectDate(context, true),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Period End',
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
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: Icon(Icons.date_range, color: Colors.deepOrange),
                              title: Text(
                                _periodEnd == null
                                    ? 'Select end date'
                                    : _formatDate(_periodEnd!),
                                style: TextStyle(
                                  color: _periodEnd == null ? Colors.grey.shade500 : Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              onTap: () => _selectDate(context, false),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // Tasks Statistics
                Row(
                  children: [
                    Expanded(
                      child: _buildNumberInputField(
                        label: 'Tasks Completed',
                        controller: _tasksCompletedController,
                        icon: Icons.check_circle,
                        hint: '0',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (int.tryParse(value) == null || int.parse(value) < 0) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildNumberInputField(
                        label: 'Tasks Pending',
                        controller: _tasksPendingController,
                        icon: Icons.hourglass_empty,
                        hint: '0',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (int.tryParse(value) == null || int.parse(value) < 0) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // Overall Performance Dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Overall Performance',
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
                    DropdownButtonFormField<String>(
                      value: _selectedPerformance,
                      style: TextStyle(color: Colors.white),
                      dropdownColor: Colors.grey.shade800,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.trending_up, color: Colors.deepOrange),
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade400),
                      items: _performanceOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _getPerformanceColor(value),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                value,
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedPerformance = newValue!;
                        });
                      },
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // Comments Field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comments (Optional)',
                      style: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _commentsController,
                      maxLines: 4,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Add additional comments about performance, achievements, areas for improvement...',
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
                SizedBox(height: 32),

                // Create Report Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (_isLoading || _isLoadingInternees) ? null : _createReport,
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
                                Icons.assessment,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Create Report',
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
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
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
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

  Color _getPerformanceColor(String performance) {
    switch (performance.toLowerCase()) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.blue;
      case 'average':
        return Colors.deepOrange;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}