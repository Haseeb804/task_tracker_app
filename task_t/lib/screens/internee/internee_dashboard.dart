import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/task.dart';
import '../../utils/helpers.dart';
import 'task_detail.dart';
import 'view_my_reports.dart';
import '../../widgets/task_card.dart';

class InterneeDashboard extends StatefulWidget {
  @override
  _InterneeDashboardState createState() => _InterneeDashboardState();
}

class _InterneeDashboardState extends State<InterneeDashboard> {
  late Future<List<Task>> _tasksFuture;
  final ApiService _apiService = ApiService();
  int? currentUserId; // Store current user ID

  @override
  void initState() {
    super.initState();
    _tasksFuture = _apiService.getTasks(context);
    _getCurrentUserId();
  }

  // Get current user ID - FIXED VERSION
  void _getCurrentUserId() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userData = authService.currentUser;
      if (userData != null && userData.id != null) { // Fixed: use .id instead of ['id']
        setState(() {
          currentUserId = userData.id; // Fixed: use .id instead of ['id']
        });
      }
    } catch (e) {
      print('Error getting current user ID: $e');
    }
  }

  void _refreshTasks() {
    setState(() {
      _tasksFuture = _apiService.getTasks(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          'Internee Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: Icon(Icons.refresh, color: Colors.deepOrange),
              onPressed: _refreshTasks,
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: Icon(Icons.logout, color: Colors.deepOrange),
              onPressed: () {
                _showLogoutDialog();
              },
            ),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Color(0xFF1A1A1A),
        width: 280,
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(24, 60, 24, 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.deepOrange,
                    Colors.deepOrange.shade700,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.school,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Task Tracker',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Internee',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            // Menu Items Section
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    _buildDrawerItem(
                      icon: Icons.dashboard,
                      title: 'Dashboard',
                      isSelected: true,
                      onTap: () {
                        Navigator.pop(context);
                        _refreshTasks();
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.task_alt,
                      title: 'My Tasks',
                      onTap: () {
                        Navigator.pop(context);
                        _refreshTasks();
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.bar_chart,
                      title: 'Progress Reports',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ViewMyReportsScreen()),
                        );
                      },
                    ),
                    
                    // Spacer to push settings to bottom
                    Spacer(),
                    
                    // Divider
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      height: 1,
                      color: Colors.grey.shade800,
                    ),
                    
                    _buildDrawerItem(
                      icon: Icons.settings,
                      title: 'Settings',
                      onTap: () {
                        Navigator.pop(context);
                        // Add settings navigation if needed
                      },
                    ),
                    
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<List<Task>>(
          future: _tasksFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  color: Colors.deepOrange,
                ),
              );
            } else if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState();
            } else {
              // Filter tasks to show only tasks assigned to current user
              final userTasks = currentUserId != null 
                  ? snapshot.data!.where((task) => task.assignedToId == currentUserId).toList()
                  : snapshot.data!;
              
              if (userTasks.isEmpty) {
                return _buildEmptyState();
              }
              
              return _buildTasksList(userTasks);
            }
          },
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? Colors.deepOrange.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected ? Border.all(color: Colors.deepOrange.withOpacity(0.3), width: 1) : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.deepOrange : Colors.grey.shade400,
                  size: 22,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.deepOrange : Colors.grey.shade300,
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTasksList(List<Task> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Section
        Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Tasks',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '${tasks.length} tasks assigned to you',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        
        // Tasks List
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return TaskCard(
                task: task,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TaskDetailScreen(task: task),
                    ),
                  ).then((_) => _refreshTasks());
                },
                onTaskUpdated: _refreshTasks,
                userRole: 'internee',
                userId: currentUserId, // Pass current user ID
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.task_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No Tasks Assigned',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'You don\'t have any tasks assigned yet.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade400,
              ),
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _refreshTasks,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Try Again',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: Text(
            'Logout',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: Colors.grey.shade300),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey.shade400),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Provider.of<AuthService>(context, listen: false).signOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}