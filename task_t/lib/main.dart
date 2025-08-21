import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'auth/auth_service.dart';
import 'services/api_service.dart'; // Add this import
import 'screens/admin/admin_dashboard.dart';
import 'screens/internee/internee_dashboard.dart';
import 'auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with web-specific configuration
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDjiVGfDxp8_RUaNce4soR_0rawZtM1miM",
      authDomain: "rentelease-77e8b.firebaseapp.com",
      projectId: "rentelease-77e8b",
      storageBucket: "rentelease-77e8b.firebasestorage.app",
      messagingSenderId: "502330410824",
      appId: "1:502330410824:web:1377840b0d2db9499b557d",
      measurementId: "G-8MN03GCQXP",
    ),
  );
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<ApiService>(create: (_) => ApiService()), // Add ApiService provider
      ],
      child: MaterialApp(
        title: 'Task Tracker',
        theme: ThemeData(
          primarySwatch: Colors.deepOrange,
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.deepOrange,
            accentColor: Colors.lime,
          ).copyWith(
            surface: Colors.grey.shade100,
            onSurface: Colors.black87,
          ),
          visualDensity: VisualDensity.adaptivePlatformDensity,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.deepOrange,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.deepOrange, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red, width: 1),
            ),
          ),
        ),
        home: AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return StreamBuilder(
      stream: authService.user,
      builder: (context, snapshot) {
        // Show loading screen while checking authentication state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        // Handle error state
        if (snapshot.hasError) {
          print('Auth stream error: ${snapshot.error}');
          return _buildErrorScreen(snapshot.error.toString());
        }

        // Check if user is authenticated and has complete data
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          print('Authenticated user: ${user.toString()}');
          
          // Check if user has role information
          if (user.role != null) {
            // Navigate based on user role
            if (user.role == 'admin') {
              return AdminDashboard();
            } else if (user.role == 'internee') {
              return InterneeDashboard();
            } else {
              print('Unknown role: ${user.role}');
              return _buildErrorScreen('Unknown user role: ${user.role}');
            }
          } else {
            // User is authenticated but doesn't have role data
            // This might happen if backend fetch failed
            return _buildRetryScreen('Loading user profile...', () {
              // Trigger a retry by signing out and back in
              authService.signOut();
            });
          }
        }

        // User is not authenticated, show login screen
        print('User not authenticated, showing login screen');
        return LoginScreen();
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.deepOrange,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepOrange.withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.task_alt,
                size: 40,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Task Tracker',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(
              color: Colors.deepOrange,
              strokeWidth: 2,
            ),
            SizedBox(height: 16),
            Text(
              'Loading...',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(String error) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              SizedBox(height: 24),
              Text(
                'Authentication Error',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                error,
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // Navigate to login screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: Text(
                  'Go to Login',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRetryScreen(String message, VoidCallback onRetry) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Colors.deepOrange,
                strokeWidth: 2,
              ),
              SizedBox(height: 24),
              Text(
                message,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              TextButton(
                onPressed: onRetry,
                child: Text(
                  'Retry',
                  style: TextStyle(
                    color: Colors.deepOrange,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}