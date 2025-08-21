import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/auth_service.dart';
import '../models/task.dart';
import '../models/report.dart';
import '../models/submission.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000'; // Replace with your API URL

  Future<Map<String, String>> _getHeaders(BuildContext context) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = await authService.getToken();
      
      if (token == null) {
        throw Exception('No authentication token available');
      }
      
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
    } catch (e) {
      print('Error getting headers: $e');
      throw Exception('Authentication failed: $e');
    }
  }

  // Helper method to get auth token
  Future<String> _getAuthToken(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pushReplacementNamed(context, '/login');
      throw Exception('User not authenticated');
    }
    final token = await user.getIdToken();
    if (token == null) {
      throw Exception('Failed to get authentication token');
    }
    return token;
  }

  // Test connection to backend
  Future<bool> testConnection() async {
    try {
      print('Testing connection to $baseUrl...');
      final response = await http.get(
        Uri.parse('$baseUrl/health/'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 10));

      print('Connection test response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }

  // User Registration (called by AuthService)
  Future<Map<String, dynamic>> registerUser({
    required String token,
    required String email,
    required String name,
    required String role,
  }) async {
    try {
      print('Registering user with API: $email, $name, $role');
      
      final response = await http.post(
        Uri.parse('$baseUrl/register/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'email': email,
          'name': name,
          'role': role,
        }),
      );

      print('Registration API response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['detail'] ?? 'Registration failed');
      }
    } catch (e) {
      print('Registration API error: $e');
      throw Exception('Network error during registration: $e');
    }
  }

  // Get current user data
  Future<Map<String, dynamic>> getCurrentUser(String token) async {
    try {
      print('Getting current user with token: ${token.substring(0, 50)}...');
      
      final response = await http.get(
        Uri.parse('$baseUrl/users/me/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(Duration(seconds: 15));

      print('Get user API response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed - please login again');
      } else {
        throw Exception('Failed to load user data: ${response.statusCode}');
      }
    } catch (e) {
      print('Get user API error: $e');
      throw Exception('Network error: $e');
    }
  }

  // Tasks
  Future<List<Task>> getTasks(BuildContext context) async {
    try {
      final headers = await _getHeaders(context);
      final response = await http.get(
        Uri.parse('$baseUrl/tasks/'),
        headers: headers,
      ).timeout(Duration(seconds: 15));

      print('Get tasks response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Task.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed - please login again');
      } else {
        throw Exception('Failed to load tasks: ${response.statusCode}');
      }
    } catch (e) {
      print('Get tasks error: $e');
      rethrow;
    }
  }

  Future<void> createTask(BuildContext context, Map<String, dynamic> taskData) async {
    try {
      final headers = await _getHeaders(context);
      final response = await http.post(
        Uri.parse('$baseUrl/tasks/'),
        headers: headers,
        body: json.encode(taskData),
      ).timeout(Duration(seconds: 15));

      print('Create task response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        // Task created successfully
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed - please login again');
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['detail'] ?? 'Failed to create task');
      }
    } catch (e) {
      print('Create task error: $e');
      rethrow;
    }
  }

  Future<void> updateTask(BuildContext context, int taskId, Map<String, dynamic> updates) async {
    try {
      final headers = await _getHeaders(context);
      final response = await http.put(
        Uri.parse('$baseUrl/tasks/$taskId/'),
        headers: headers,
        body: json.encode(updates),
      ).timeout(Duration(seconds: 15));

      print('Update task response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        // Task updated successfully
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed - please login again');
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['detail'] ?? 'Failed to update task');
      }
    } catch (e) {
      print('Update task error: $e');
      rethrow;
    }
  }

  Future<void> deleteTask(BuildContext context, int taskId) async {
    try {
      final headers = await _getHeaders(context);
      final response = await http.delete(
        Uri.parse('$baseUrl/tasks/$taskId/'),
        headers: headers,
      ).timeout(Duration(seconds: 15));

      print('Delete task response: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Task deleted successfully
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed - please login again');
      } else {
        throw Exception('Failed to delete task');
      }
    } catch (e) {
      print('Delete task error: $e');
      rethrow;
    }
  }

  // Get all internees (for admins) - Primary method
  Future<List<Map<String, dynamic>>> getInternees(BuildContext context) async {
    try {
      print('Getting internees from: $baseUrl/users/internees/');
      
      // Test connection first
      final isConnected = await testConnection();
      if (!isConnected) {
        throw Exception('Cannot connect to server. Please check if the backend is running on $baseUrl');
      }
      
      final headers = await _getHeaders(context);
      print('Request headers: $headers');
      
      final response = await http.get(
        Uri.parse('$baseUrl/users/internees/'),
        headers: headers,
      ).timeout(Duration(seconds: 15));

      print('Get internees response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('Parsed ${data.length} internees');
        return data.cast<Map<String, dynamic>>();
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed - please login again');
      } else if (response.statusCode == 404) {
        throw Exception('Internees endpoint not found. Please check your backend API.');
      } else {
        final errorBody = response.body.isNotEmpty ? json.decode(response.body) : {'detail': 'Unknown error'};
        throw Exception(errorBody['detail'] ?? 'Failed to load internees: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('Get internees error: $e');
      if (e.toString().contains('SocketException') || e.toString().contains('TimeoutException')) {
        throw Exception('Network error: Cannot reach server at $baseUrl. Please check if your backend is running.');
      }
      rethrow;
    }
  }

  // Alternative method using direct token for backward compatibility
  Future<List<Map<String, dynamic>>> getInterneesWithToken(BuildContext context) async {
    try {
      print('Using alternative method to get internees...');
      
      final token = await _getAuthToken(context);
      print('Got token for alternative method');
      
      final response = await http.get(
        Uri.parse('$baseUrl/users/internees/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: 15));
      
      print('Alternative method response: ${response.statusCode}');
      print('Alternative method body: ${response.body}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('Alternative method parsed ${data.length} internees');
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else if (response.statusCode == 401) {
        // Handle unauthorized access
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
        throw Exception('Unauthorized access - please login again');
      } else if (response.statusCode == 404) {
        throw Exception('Internees API endpoint not found on server');
      } else {
        final error = response.body.isNotEmpty ? jsonDecode(response.body) : {'detail': 'Unknown error'};
        throw Exception(error['detail'] ?? 'Failed to fetch internees: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('Alternative internees method error: $e');
      if (e.toString().contains('Unauthorized')) {
        rethrow;
      }
      if (e.toString().contains('SocketException') || e.toString().contains('TimeoutException')) {
        throw Exception('Network connection failed. Please check if your backend server at $baseUrl is running and accessible.');
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  // Updated submitTask method with proper error handling
  Future<void> submitTask(BuildContext context, int taskId, Map<String, dynamic> submissionData) async {
    try {
      print('Submitting task $taskId with data: $submissionData'); // Debug log
      
      final headers = await _getHeaders(context);
      
      // Ensure the submission data has the required fields
      final requestData = {
        'description': submissionData['description'] ?? '',
        'attachment_url': submissionData['attachment_url'], // Can be null
      };
      
      print('Request data: $requestData'); // Debug log
      
      final response = await http.post(
        Uri.parse('$baseUrl/tasks/$taskId/submit/'),
        headers: headers,
        body: json.encode(requestData),
      ).timeout(Duration(seconds: 15));

      print('Submit task response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Task submitted successfully
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed - please login again');
      } else if (response.statusCode == 422) {
        // Validation error - parse the detailed error message
        final errorBody = json.decode(response.body);
        if (errorBody['detail'] is List) {
          final errors = errorBody['detail'] as List;
          final errorMessages = errors.map((error) => 
            '${error['loc']?.join('.') ?? 'Field'}: ${error['msg'] ?? 'Invalid'}'
          ).join(', ');
          throw Exception('Validation error: $errorMessages');
        } else {
          throw Exception('Validation error: ${errorBody['detail']}');
        }
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['detail'] ?? 'Failed to submit task');
      }
    } catch (e) {
      print('Submit task error: $e');
      rethrow;
    }
  }

  // Method to mark task as completed (status update)
  Future<void> markTaskAsCompleted(BuildContext context, int taskId) async {
    try {
      print('Marking task $taskId as completed');
      
      final headers = await _getHeaders(context);
      final updateData = {
        'status': 'completed',
      };
      
      final response = await http.put(
        Uri.parse('$baseUrl/tasks/$taskId/'),
        headers: headers,
        body: json.encode(updateData),
      ).timeout(Duration(seconds: 15));

      print('Mark completed response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        // Task status updated successfully
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed - please login again');
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['detail'] ?? 'Failed to update task status');
      }
    } catch (e) {
      print('Mark completed error: $e');
      rethrow;
    }
  }

  // Method to submit task and mark as completed in one operation
  Future<void> submitAndCompleteTask(BuildContext context, int taskId, String description) async {
    try {
      // First submit the task
      await submitTask(context, taskId, {
        'description': description,
        'attachment_url': null,
      });
      
      // Then mark as completed
      await markTaskAsCompleted(context, taskId);
      
    } catch (e) {
      print('Submit and complete error: $e');
      rethrow;
    }
  }

  Future<List<TaskSubmission>> getTaskSubmissions(BuildContext context, int taskId) async {
    try {
      final headers = await _getHeaders(context);
      final response = await http.get(
        Uri.parse('$baseUrl/tasks/$taskId/submissions/'),
        headers: headers,
      ).timeout(Duration(seconds: 15));

      print('Get submissions response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => TaskSubmission.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed - please login again');
      } else {
        throw Exception('Failed to load submissions');
      }
    } catch (e) {
      print('Get submissions error: $e');
      rethrow;
    }
  }

  // Reports - FIXED METHOD
  Future<List<ProgressReport>> getProgressReports(BuildContext context) async {
    try {
      final headers = await _getHeaders(context);
      final response = await http.get(
        Uri.parse('$baseUrl/reports/'),
        headers: headers,
      ).timeout(Duration(seconds: 15));

      print('Get reports response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ProgressReport.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed - please login again');
      } else {
        throw Exception('Failed to load reports');
      }
    } catch (e) {
      print('Get reports error: $e');
      rethrow;
    }
  }

  // FIXED: Create Progress Report with correct data structure
  Future<void> createProgressReport(BuildContext context, Map<String, dynamic> reportData) async {
    try {
      print('Creating progress report with data: $reportData');
      
      final headers = await _getHeaders(context);
      
      // Ensure all required fields are present and properly formatted
      final requestData = {
        'internee_id': reportData['internee_id'],
        'period_start': reportData['period_start'],
        'period_end': reportData['period_end'],
        'tasks_completed': reportData['tasks_completed'],
        'tasks_pending': reportData['tasks_pending'],
        'overall_performance': reportData['overall_performance'],
        if (reportData['comments'] != null) 'comments': reportData['comments'],
      };
      
      print('Sending report data: $requestData'); // Debug log
      
      final response = await http.post(
        Uri.parse('$baseUrl/reports/'),
        headers: headers,
        body: json.encode(requestData),
      ).timeout(Duration(seconds: 15));

      print('Create report response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Report created successfully
        print('Progress report created successfully');
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed - please login again');
      } else if (response.statusCode == 422) {
        // Validation error - parse the detailed error message
        final errorBody = json.decode(response.body);
        if (errorBody['detail'] is List) {
          final errors = errorBody['detail'] as List;
          final errorMessages = errors.map((error) => 
            '${error['loc']?.join('.') ?? 'Field'}: ${error['msg'] ?? 'Invalid'}'
          ).join('\n');
          throw Exception('Validation errors:\n$errorMessages');
        } else {
          throw Exception('Validation error: ${errorBody['detail']}');
        }
      } else {
        final errorBody = response.body.isNotEmpty ? json.decode(response.body) : {'detail': 'Unknown error'};
        throw Exception(errorBody['detail'] ?? 'Failed to create report: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('Create report error: $e');
      rethrow;
    }
  }

  // Health check
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health/'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('Health check error: $e');
      return false;
    }
  }


// Add this method to your ApiService class

  // Get reports for the current internee (only their own reports)
  Future<List<ProgressReport>> getMyProgressReports(BuildContext context) async {
    try {
      print('Getting my progress reports from: $baseUrl/reports/my/');
      
      final headers = await _getHeaders(context);
      final response = await http.get(
        Uri.parse('$baseUrl/reports/my/'), // Assuming this endpoint exists for internees
        headers: headers,
      ).timeout(Duration(seconds: 15));

      print('Get my reports response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ProgressReport.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed - please login again');
      } else if (response.statusCode == 404) {
        // If endpoint doesn't exist, try filtering from all reports
        return await _getFilteredReports(context);
      } else {
        throw Exception('Failed to load my reports: ${response.statusCode}');
      }
    } catch (e) {
      print('Get my reports error: $e');
      if (e.toString().contains('404')) {
        // Fallback to filtering all reports
        return await _getFilteredReports(context);
      }
      rethrow;
    }
  }

  // Fallback method: get all reports and filter for current user
  Future<List<ProgressReport>> _getFilteredReports(BuildContext context) async {
    try {
      print('Using fallback method to get filtered reports...');
      
      // Get current user info first
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = await authService.getToken();
      final currentUser = await getCurrentUser(token!);
      final currentUserName = currentUser['name'];
      
      // Get all reports
      final allReports = await getProgressReports(context);
      
      // Filter reports for current user
      final myReports = allReports.where((report) => 
        report.interneeName.toLowerCase() == currentUserName.toLowerCase()
      ).toList();
      
      print('Filtered ${myReports.length} reports for current user: $currentUserName');
      return myReports;
      
    } catch (e) {
      print('Filtered reports error: $e');
      rethrow;
    }
  }
}