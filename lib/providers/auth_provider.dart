import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/supabase_auth_service.dart';
import '../services/connectivity_service.dart';

class AuthProvider with ChangeNotifier {
  final SupabaseAuthService _supabaseAuth = SupabaseAuthService();
  final ConnectivityService _connectivity = ConnectivityService();

  bool _isLoading = false;
  String? _token;
  UserModel? _user;
  String? _errorMessage;
  StreamSubscription? _authSubscription;

  bool get isLoading => _isLoading;
  String? get token => _token;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _token != null && _user != null;

  // =========================================================
  // Initialize - Restore user session if saved
  // =========================================================
  Future<void> init() async {
    // Initialize connectivity service
    await _connectivity.init();

    // Initialize with Supabase
    await _initSupabase();
  }

  /// Initialize with Supabase
  Future<void> _initSupabase() async {
    try {
      // Listen to auth state changes
      _authSubscription = _supabaseAuth.authStateChanges.listen((state) {
        debugPrint('AuthProvider: Auth state changed: ${state.event}');
        if (state.event == AuthChangeEvent.signedOut) {
          _handleSignedOut();
        }
      });

      // Try to restore session
      final result = await _supabaseAuth.restoreSession();
      if (result.isSuccess && result.user != null) {
        _user = result.user!.toUserModel();
        _token = result.session?.accessToken ?? 'supabase_session';
        debugPrint('AuthProvider: Session restored for: ${_user?.name}');
      }
    } catch (e) {
      debugPrint('AuthProvider: Init error: $e');
    }

    notifyListeners();
  }

  /// Handle signed out event
  void _handleSignedOut() {
    _token = null;
    _user = null;
    notifyListeners();
  }

  // =========================================================
  // Login
  // =========================================================
  Future<bool> login(String phone, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      return await _loginSupabase(phone, password);
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'network_error';
      debugPrint('AuthProvider: Login exception: $e');
      notifyListeners();
      return false;
    }
  }

  /// Login using Supabase
  Future<bool> _loginSupabase(String phone, String password) async {
    final result = await _supabaseAuth.signIn(
      phone: phone,
      password: password,
    );

    _isLoading = false;

    if (result.isSuccess && result.user != null) {
      _user = result.user!.toUserModel();
      // Only set token if we have a valid access token
      _token = result.session?.accessToken;
      if (_token == null || _token!.isEmpty) {
        debugPrint('AuthProvider: Warning - No valid access token received');
      }
      await _saveSession();
      debugPrint('AuthProvider: Login successful for ${_user?.name}');
      notifyListeners();
      return true;
    } else {
      _errorMessage = result.errorMessage ?? 'login_failed';
      debugPrint('AuthProvider: Login failed: $_errorMessage');
      notifyListeners();
      return false;
    }
  }

  // =========================================================
  // Register
  // =========================================================
  Future<bool> register(String name, String phone, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      return await _registerSupabase(name, phone, password);
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'network_error';
      debugPrint('AuthProvider: Registration exception: $e');
      notifyListeners();
      return false;
    }
  }

  /// Register using Supabase
  Future<bool> _registerSupabase(String name, String phone, String password) async {
    final result = await _supabaseAuth.signUp(
      name: name,
      phone: phone,
      password: password,
    );

    _isLoading = false;

    if (result.isSuccess && result.user != null) {
      _user = result.user!.toUserModel();
      // Only set token if we have a valid access token
      _token = result.session?.accessToken;
      if (_token == null || _token!.isEmpty) {
        debugPrint('AuthProvider: Warning - No valid access token received');
      }
      await _saveSession();
      debugPrint('AuthProvider: Registration successful for ${_user?.name}');
      notifyListeners();
      return true;
    } else {
      _errorMessage = result.errorMessage ?? 'registration_failed';
      debugPrint('AuthProvider: Registration failed: $_errorMessage');
      notifyListeners();
      return false;
    }
  }

  // =========================================================
  // Save session to SharedPreferences
  // =========================================================
  Future<void> _saveSession() async {
    if (_token != null && _user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      await prefs.setString('user_data', json.encode(_user!.toJson()));
      debugPrint('AuthProvider: Session saved');
    }
  }

  // =========================================================
  // Clear session (used in logout or failed restore)
  // =========================================================
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    _token = null;
    _user = null;
    debugPrint('AuthProvider: Session cleared');
  }

  // =========================================================
  // Logout safely
  // =========================================================
  Future<void> logout() async {
    debugPrint('AuthProvider: Logging out...');

    // Sign out from Supabase
    try {
      await _supabaseAuth.signOut();
    } catch (e) {
      debugPrint('AuthProvider: Supabase signout error: $e');
    }

    await clearSession();

    _errorMessage = null;
    _isLoading = false;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 100));
  }

  // =========================================================
  // Utility
  // =========================================================
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void updateUser(UserModel updatedUser) {
    _user = updatedUser;
    _saveSession();
    notifyListeners();
  }

  // =========================================================
  // Update User Profile (for profile completion)
  // =========================================================
  Future<bool> updateUserProfile(UserModel updatedUser) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      return await _updateProfileSupabase(updatedUser);
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'network_error';
      debugPrint('AuthProvider: Profile update exception: $e');
      notifyListeners();
      return false;
    }
  }

  /// Update profile using Supabase
  Future<bool> _updateProfileSupabase(UserModel updatedUser) async {
    final success = await _supabaseAuth.updateProfile({
      'name': updatedUser.name,
      'gender': updatedUser.gender?.name,
      'birth_date': updatedUser.birthDate?.toIso8601String().split('T').first,
      'city': updatedUser.city,
      'interests': updatedUser.interests,
      'occupation': updatedUser.occupation,
      'avatar_url': updatedUser.avatarUrl,
    });

    _isLoading = false;

    if (success) {
      _user = updatedUser;
      await _saveSession();
      debugPrint('AuthProvider: Profile updated successfully');
      notifyListeners();
      return true;
    } else {
      _errorMessage = 'error_saving_profile';
      notifyListeners();
      return false;
    }
  }

  // =========================================================
  // Check if profile needs completion
  // =========================================================
  bool get needsProfileCompletion => _user?.needsProfileCompletion ?? false;

  // =========================================================
  // Get Supabase user ID (for real-time subscriptions)
  // =========================================================
  String? get supabaseUserId => _supabaseAuth.currentUser?.id;

  // =========================================================
  // Dispose
  // =========================================================
  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

/// Auth state change event type
enum AuthChangeEvent {
  signedIn,
  signedOut,
  tokenRefreshed,
  userUpdated,
}
