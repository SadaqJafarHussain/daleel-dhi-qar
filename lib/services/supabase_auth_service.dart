import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart' as app;
import 'cache_manager.dart';
import 'supabase_service.dart';

/// Supabase authentication service
class SupabaseAuthService {
  // Singleton instance
  static final SupabaseAuthService _instance = SupabaseAuthService._internal();
  factory SupabaseAuthService() => _instance;
  SupabaseAuthService._internal();

  final SupabaseService _supabase = SupabaseService();
  final CacheManager _cache = CacheManager();

  /// Get current Supabase auth user
  User? get currentUser => _supabase.client.auth.currentUser;

  /// Get current session
  Session? get currentSession => _supabase.client.auth.currentSession;

  /// Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  /// Auth state changes stream
  Stream<AuthState> get authStateChanges => _supabase.client.auth.onAuthStateChange;

  // ========================================
  // PHONE OTP AUTHENTICATION
  // ========================================

  /// Send OTP to phone number for sign up
  Future<AuthResult> sendSignUpOtp({
    required String phone,
    required String name,
  }) async {
    try {
      final formattedPhone = _formatPhoneNumber(phone);

      await _supabase.client.auth.signInWithOtp(
        phone: formattedPhone,
        data: {
          'name': name,
          'phone': phone,
        },
      );

      debugPrint('SupabaseAuthService: OTP sent to $formattedPhone');
      return AuthResult.otpSent(phone: formattedPhone, name: name);
    } on AuthException catch (e) {
      debugPrint('SupabaseAuthService: Send OTP error: ${e.message}');
      return AuthResult.failure(_mapAuthError(e));
    } catch (e) {
      debugPrint('SupabaseAuthService: Send OTP error: $e');
      return AuthResult.failure('Failed to send OTP. Please try again.');
    }
  }

  /// Send OTP to phone number for sign in
  Future<AuthResult> sendSignInOtp({
    required String phone,
  }) async {
    try {
      final formattedPhone = _formatPhoneNumber(phone);

      await _supabase.client.auth.signInWithOtp(
        phone: formattedPhone,
      );

      debugPrint('SupabaseAuthService: OTP sent to $formattedPhone');
      return AuthResult.otpSent(phone: formattedPhone);
    } on AuthException catch (e) {
      debugPrint('SupabaseAuthService: Send OTP error: ${e.message}');
      return AuthResult.failure(_mapAuthError(e));
    } catch (e) {
      debugPrint('SupabaseAuthService: Send OTP error: $e');
      return AuthResult.failure('Failed to send OTP. Please try again.');
    }
  }

  /// Verify OTP and complete sign in/up
  Future<AuthResult> verifyOtp({
    required String phone,
    required String otp,
    String? name,
  }) async {
    try {
      final formattedPhone = _formatPhoneNumber(phone);

      final response = await _supabase.client.auth.verifyOTP(
        phone: formattedPhone,
        token: otp,
        type: OtpType.sms,
      );

      if (response.user == null) {
        return AuthResult.failure('Verification failed');
      }

      // Wait for trigger to create profile
      await Future.delayed(const Duration(milliseconds: 500));

      // Fetch or create profile
      final profile = await _fetchProfile(response.user!.id);

      debugPrint('SupabaseAuthService: User verified: ${response.user!.id}');

      return AuthResult.success(
        user: _mapToAppUser(
          response.user!,
          name: name ?? profile?['name'],
          phone: phone,
          profile: profile,
        ),
        session: response.session,
      );
    } on AuthException catch (e) {
      debugPrint('SupabaseAuthService: Verify OTP error: ${e.message}');
      return AuthResult.failure(_mapAuthError(e));
    } catch (e) {
      debugPrint('SupabaseAuthService: Verify OTP error: $e');
      return AuthResult.failure('Verification failed. Please try again.');
    }
  }

  /// Resend OTP
  Future<AuthResult> resendOtp({required String phone}) async {
    return await sendSignInOtp(phone: phone);
  }

  // ========================================
  // LEGACY SIGN UP (Email/Password fallback)
  // ========================================

  /// Sign up with phone and password (legacy - uses email workaround)
  Future<AuthResult> signUp({
    required String phone,
    required String password,
    required String name,
  }) async {
    try {
      // Format phone for auth (use as email substitute)
      final email = _phoneToEmail(phone);

      // Sign up with Supabase Auth
      final response = await _supabase.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'phone': phone,
        },
      );

      if (response.user == null) {
        return AuthResult.failure('Registration failed');
      }

      // Profile is created automatically by database trigger (handle_new_user)
      // Wait a moment for the trigger to complete
      await Future.delayed(const Duration(milliseconds: 500));

      debugPrint('SupabaseAuthService: User registered: ${response.user!.id}');

      return AuthResult.success(
        user: _mapToAppUser(response.user!, name: name, phone: phone),
        session: response.session,
      );
    } on AuthException catch (e) {
      debugPrint('SupabaseAuthService: Auth error: ${e.message}');
      return AuthResult.failure(_mapAuthError(e));
    } catch (e) {
      debugPrint('SupabaseAuthService: Sign up error: $e');
      return AuthResult.failure('Registration failed. Please try again.');
    }
  }

  // ========================================
  // LEGACY SIGN IN (Email/Password fallback)
  // ========================================

  /// Sign in with phone and password (legacy - uses email workaround)
  Future<AuthResult> signIn({
    required String phone,
    required String password,
  }) async {
    try {
      final email = _phoneToEmail(phone);
      debugPrint('SupabaseAuthService: Attempting sign in with email: $email');

      final response = await _supabase.client.auth.signInWithPassword(
        email: email,
        password: password,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('SupabaseAuthService: Sign in TIMEOUT after 15 seconds');
          throw Exception('Connection timeout. Please check your internet connection.');
        },
      );
      debugPrint('SupabaseAuthService: Sign in response received');

      if (response.user == null) {
        debugPrint('SupabaseAuthService: User is null in response');
        return AuthResult.failure('Login failed');
      }

      debugPrint('SupabaseAuthService: User signed in: ${response.user!.id}');

      // Fetch profile
      debugPrint('SupabaseAuthService: Fetching profile...');
      final profile = await _fetchProfile(response.user!.id);
      debugPrint('SupabaseAuthService: Profile fetched: ${profile != null}');

      return AuthResult.success(
        user: _mapToAppUser(
          response.user!,
          name: profile?['name'],
          phone: profile?['phone'] ?? phone,
          profile: profile,
        ),
        session: response.session,
      );
    } on AuthException catch (e) {
      debugPrint('SupabaseAuthService: Auth error: ${e.message}');
      return AuthResult.failure(_mapAuthError(e));
    } catch (e) {
      debugPrint('SupabaseAuthService: Sign in error: $e');
      return AuthResult.failure('Login failed. Please check your credentials.');
    }
  }

  // ========================================
  // SIGN OUT
  // ========================================

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _supabase.client.auth.signOut();
      await _cache.clearAll();
      debugPrint('SupabaseAuthService: User signed out');
    } catch (e) {
      debugPrint('SupabaseAuthService: Sign out error: $e');
      rethrow;
    }
  }

  // ========================================
  // SESSION MANAGEMENT
  // ========================================

  /// Restore session from storage
  Future<AuthResult> restoreSession() async {
    try {
      final session = currentSession;
      final user = currentUser;

      if (session == null || user == null) {
        return AuthResult.failure('No session found');
      }

      // Check if session is expired
      if (session.isExpired) {
        debugPrint('SupabaseAuthService: Session expired, refreshing...');
        final refreshed = await refreshSession();
        if (!refreshed.isSuccess) {
          return refreshed;
        }
      }

      // Fetch profile
      final profile = await _fetchProfile(user.id);

      return AuthResult.success(
        user: _mapToAppUser(user, profile: profile),
        session: currentSession,
      );
    } catch (e) {
      debugPrint('SupabaseAuthService: Restore session error: $e');
      return AuthResult.failure('Session restore failed');
    }
  }

  /// Refresh the current session
  Future<AuthResult> refreshSession() async {
    try {
      final response = await _supabase.client.auth.refreshSession();

      if (response.user == null || response.session == null) {
        return AuthResult.failure('Session refresh failed');
      }

      // Validate the refreshed session is actually valid
      final session = response.session!;
      if (session.isExpired) {
        debugPrint('SupabaseAuthService: Refreshed session is still expired');
        // Force sign out to clear invalid session
        await signOut();
        return AuthResult.failure('session_expired');
      }

      // Verify token is not empty
      if (session.accessToken.isEmpty) {
        debugPrint('SupabaseAuthService: Refreshed session has empty token');
        return AuthResult.failure('Invalid session token');
      }

      final profile = await _fetchProfile(response.user!.id);

      return AuthResult.success(
        user: _mapToAppUser(response.user!, profile: profile),
        session: response.session,
      );
    } catch (e) {
      debugPrint('SupabaseAuthService: Refresh session error: $e');
      return AuthResult.failure('Session refresh failed');
    }
  }

  // ========================================
  // PROFILE MANAGEMENT
  // ========================================

  /// Fetch user profile from database
  Future<Map<String, dynamic>?> _fetchProfile(String userId) async {
    try {
      // Check cache first
      final cached = await _cache.getProfile(userId);
      if (cached != null) return cached;

      final response = await _supabase.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        await _cache.setProfile(userId, response);
      }

      return response;
    } catch (e) {
      debugPrint('SupabaseAuthService: Error fetching profile: $e');
      return null;
    }
  }

  /// Get current user profile
  Future<Map<String, dynamic>?> getProfile() async {
    if (currentUser == null) return null;
    return await _fetchProfile(currentUser!.id);
  }

  /// Update user profile
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    if (currentUser == null) return false;

    try {
      await _supabase.client
          .from('profiles')
          .update(data)
          .eq('id', currentUser!.id);

      // Update cache
      final profile = await _fetchProfile(currentUser!.id);
      if (profile != null) {
        await _cache.setProfile(currentUser!.id, {...profile, ...data});
      }

      debugPrint('SupabaseAuthService: Profile updated');
      return true;
    } catch (e) {
      debugPrint('SupabaseAuthService: Update profile error: $e');
      return false;
    }
  }

  /// Check if profile needs completion
  Future<bool> needsProfileCompletion() async {
    if (currentUser == null) return false;

    try {
      final profile = await _fetchProfile(currentUser!.id);
      if (profile == null) return true;

      // Check required fields
      return profile['gender'] == null ||
          profile['city'] == null ||
          profile['birth_date'] == null;
    } catch (e) {
      debugPrint('SupabaseAuthService: Error checking profile completion: $e');
      return false;
    }
  }

  // ========================================
  // PASSWORD MANAGEMENT
  // ========================================

  /// Update password
  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // Re-authenticate first
      final user = currentUser;
      if (user?.email == null) return false;

      await _supabase.client.auth.signInWithPassword(
        email: user!.email!,
        password: currentPassword,
      );

      // Update password
      await _supabase.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      debugPrint('SupabaseAuthService: Password updated');
      return true;
    } on AuthException catch (e) {
      debugPrint('SupabaseAuthService: Password update error: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('SupabaseAuthService: Password update error: $e');
      return false;
    }
  }

  /// Request password reset
  Future<bool> resetPassword(String phone) async {
    try {
      final email = _phoneToEmail(phone);
      await _supabase.client.auth.resetPasswordForEmail(email);
      debugPrint('SupabaseAuthService: Password reset email sent');
      return true;
    } catch (e) {
      debugPrint('SupabaseAuthService: Reset password error: $e');
      return false;
    }
  }

  // ========================================
  // HELPER METHODS
  // ========================================

  /// Format phone number for Supabase (international format)
  String _formatPhoneNumber(String phone) {
    // Remove spaces, dashes, and parentheses
    String cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Handle Iraqi numbers
    if (cleaned.startsWith('07')) {
      // Iraqi mobile: 07xx -> +9647xx
      cleaned = '+964${cleaned.substring(1)}';
    } else if (cleaned.startsWith('964')) {
      // Already has country code without +
      cleaned = '+$cleaned';
    } else if (!cleaned.startsWith('+')) {
      // Add + if missing
      cleaned = '+$cleaned';
    }

    return cleaned;
  }

  /// Convert phone to email format for Supabase auth (legacy fallback)
  String _phoneToEmail(String phone) {
    // Remove spaces and dashes
    final cleaned = phone.replaceAll(RegExp(r'[\s-]'), '');
    return '$cleaned@daleel.app';
  }

  /// Map Supabase user to app User model
  app.User _mapToAppUser(
    User supabaseUser, {
    String? name,
    String? phone,
    Map<String, dynamic>? profile,
  }) {
    return app.User(
      id: supabaseUser.id.hashCode, // Convert UUID to int for compatibility
      name: name ?? profile?['name'] ?? supabaseUser.userMetadata?['name'] ?? '',
      phone: phone ?? profile?['phone'] ?? '',
      gender: profile?['gender'],
      birthDate: profile?['birth_date'],
      city: profile?['city'],
      interests: profile?['interests'] != null
          ? List<String>.from(profile!['interests'])
          : null,
      occupation: profile?['occupation'],
      avatarUrl: profile?['avatar_url'],
      createdAt: supabaseUser.createdAt,
    );
  }

  /// Map auth errors to user-friendly messages
  String _mapAuthError(AuthException e) {
    switch (e.message) {
      case 'Invalid login credentials':
        return 'Invalid phone number or password';
      case 'Email not confirmed':
        return 'Please verify your account';
      case 'User already registered':
        return 'This phone number is already registered';
      case 'Password should be at least 6 characters':
        return 'Password must be at least 6 characters';
      default:
        return e.message;
    }
  }
}

/// Result of an authentication operation
class AuthResult {
  final bool isSuccess;
  final bool isOtpSent;
  final app.User? user;
  final Session? session;
  final String? errorMessage;
  final String? phone;
  final String? name;

  AuthResult._({
    required this.isSuccess,
    this.isOtpSent = false,
    this.user,
    this.session,
    this.errorMessage,
    this.phone,
    this.name,
  });

  factory AuthResult.success({
    required app.User user,
    Session? session,
  }) {
    return AuthResult._(
      isSuccess: true,
      user: user,
      session: session,
    );
  }

  factory AuthResult.failure(String message) {
    return AuthResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }

  factory AuthResult.otpSent({
    required String phone,
    String? name,
  }) {
    return AuthResult._(
      isSuccess: false,
      isOtpSent: true,
      phone: phone,
      name: name,
    );
  }
}
