import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/task.dart';
import '../internee/task_detail.dart';
import 'create_task.dart';
import 'view_reports.dart';
import '../../widgets/task_card.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late Future<List<Task>> _tasksFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _tasksFuture = _apiService.getTasks(context);
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
        backgroundColor: Colors.grey.shade900,
        elevation: 0,
        title: Text(
          'Admin Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          Container(
            margin: EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.deepOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(Icons.refresh, color: Colors.deepOrange),
              onPressed: _refreshTasks,
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(Icons.logout, color: Colors.red),
              onPressed: () {
                _showLogoutDialog();
              },
            ),
          ),
          SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.grey.shade900,
        child: Column(
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepOrange, Colors.deepOrange.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.admin_panel_settings,
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
                      Text(
                        'Administrator',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(vertical: 16),
                children: [
                  _buildDrawerItem(
                    icon: Icons.dashboard,
                    title: 'Dashboard',
                    onTap: () {
                      Navigator.pop(context);
                      _refreshTasks();
                    },
                    isSelected: true,
                  ),
                  _buildDrawerItem(
                    icon: Icons.task_alt,
                    title: 'Tasks',
                    onTap: () {
                      Navigator.pop(context);
                      _refreshTasks();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.assessment,
                    title: 'Progress Reports',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ViewReportsScreen()),
                      );
                    },
                  ),
                  Divider(color: Colors.grey.shade700, height: 32),
                  _buildDrawerItem(
                    icon: Icons.settings,
                    title: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.deepOrange.withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.deepOrange,
          elevation: 0,
          child: Icon(Icons.add, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CreateTaskScreen()),
            ).then((_) => _refreshTasks());
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome Back!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Manage and track all tasks efficiently',
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
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: FutureBuilder<List<Task>>(
                  future: _tasksFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: Colors.deepOrange,
                              strokeWidth: 3,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Loading tasks...',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 64,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Error loading tasks',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '${snapshot.error}',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade800,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.task_alt,
                                color: Colors.deepOrange,
                                size: 64,
                              ),
                            ),
                            SizedBox(height: 24),
                            Text(
                              'No tasks found',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Start by creating your first task',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      return ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final task = snapshot.data![index];
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
                            userRole: 'admin',
                            // Admin doesn't need userId for task operations
                            userId: null,
                          );
                        },
                      );
                    }
                  },
                ),
              ),
            ),
          ],
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
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.deepOrange.withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.deepOrange : Colors.grey.shade400,
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.deepOrange : Colors.grey.shade300,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 16,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
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

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Logout',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(
            color: Colors.grey.shade400,
          ),
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
              Provider.of<AuthService>(context, listen: false).signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
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
      ),
    );
  }
}