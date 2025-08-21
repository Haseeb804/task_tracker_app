import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user.dart' as app_user;

class AuthService {
  final firebase.FirebaseAuth _auth = firebase.FirebaseAuth.instance;
  static const String baseUrl = 'http://127.0.0.1:8000'; 
  // Create user object based on Firebase User
  app_user.User? _userFromFirebaseUser(firebase.User? user) {
    return user != null 
        ? app_user.User(
            uid: user.uid,
            email: user.email,
          ) 
        : null;
  }

  // Auth change user stream
  Stream<app_user.User?> get user {
    return _auth.authStateChanges().asyncMap((firebase.User? user) async {
      if (user != null) {
        // Get additional user data from your backend
        try {
          final userData = await _getUserDataFromBackend(user);
          print('User data fetched: $userData'); // Debug statement
          return app_user.User(
            uid: user.uid,
            email: user.email,
            name: userData['name'],
            role: userData['role'],
          );
        } catch (e) {
          print('Error fetching user data: $e');
          return app_user.User(
            uid: user.uid,
            email: user.email,
          );
        }
      }
      return null;
    });
  }

  // Get user data from backend
  Future<Map<String, dynamic>> _getUserDataFromBackend(firebase.User user) async {
    try {
      final token = await user.getIdToken();
      print('Fetching user data with token: $token'); // Debug statement
      final response = await http.get(
        Uri.parse('$baseUrl/users/me/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load user data');
      }
    } catch (e) {
      throw Exception('Failed to fetch user data: $e');
    }
  }

  // Get current user
  app_user.User? get currentUser {
    firebase.User? user = _auth.currentUser;
    return _userFromFirebaseUser(user);
  }

  // Get Firebase ID token
  Future<String?> getToken() async {
    firebase.User? user = _auth.currentUser;
    if (user != null) {
      return await user.getIdToken();
    }
    return null;
  }

  // Sign in with email and password
  Future<app_user.User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      firebase.UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      firebase.User? user = result.user;
      return _userFromFirebaseUser(user);
    } catch (error) {
      print('Sign in error: $error');
      throw error;
    }
  }

  // Register with email and password and store in database
  Future<app_user.User?> registerWithEmailAndPassword(
    String email, 
    String password,
    String name,
    String role,
  ) async {
    try {
      // Create user in Firebase
      firebase.UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      firebase.User? user = result.user;

      if (user != null) {
        // Update Firebase user profile
        await user.updateDisplayName(name);
        
        // Store additional user data in your backend database
        await _registerUserInBackend(user, name, role);
        
        return app_user.User(
          uid: user.uid,
          email: user.email,
          name: name,
          role: role,
        );
      }
      
      return null;
    } catch (error) {
      print('Registration error: $error');
      throw error;
    }
  }

  // Register user in backend database
  Future<void> _registerUserInBackend(firebase.User user, String name, String role) async {
    try {
      final token = await user.getIdToken();
      final response = await http.post(
        Uri.parse('$baseUrl/register/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'email': user.email,
          'name': name,
          'role': role,
        }),
      );

      if (response.statusCode != 200) {
        final errorBody = json.decode(response.body);
        throw Exception('Failed to register user in database: ${errorBody['detail'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('Backend registration error: $e');
      throw Exception('Failed to complete registration: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      return await _auth.signOut();
    } catch (error) {
      print('Sign out error: $error');
      throw error;
    }
  }
}