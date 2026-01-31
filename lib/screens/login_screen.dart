import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tour_guid/screens/main_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/favorites_provider.dart';
import '../utils/app_localization.dart';
import 'register_screen.dart';
import 'complete_profile_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.login(
      _phoneController.text.trim(),
      _passwordController.text,
    );

    final locale = AppLocalizations.of(context);

    if (success && mounted) {
      // Set Supabase user ID for favorites provider
      if (authProvider.supabaseUserId != null) {
        final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);
        favoritesProvider.setSupabaseUserId(authProvider.supabaseUserId);
      }

      // Check if user needs to complete profile
      if (authProvider.needsProfileCompletion) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CompleteProfileScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? locale.t('logout_confirm')),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;
    final locale = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(w * 0.06),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: h * 0.05),

                  // Logo
                  Center(
                    child: Image.asset(
                      'assets/images/splash_logo.png',
                      width: w * 0.5,
                    ),
                  ),

                  // Title
                  Text(
                    locale.t('login'),
                    style: TextStyle(
                      fontSize: w * 0.07,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.labelLarge!.color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: h * 0.01),

                  Text(
                    locale.t('login_message'),
                    style: TextStyle(
                      fontSize: w * 0.035,
                      color: Theme.of(context).textTheme.displayMedium!.color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: h * 0.04),

                  // Phone Number Field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locale.t('phone_number'),
                        style: TextStyle(
                          fontSize: w * 0.035,
                          fontWeight: FontWeight.w600,
                            color: Theme.of(context).textTheme.bodyLarge!.color
                        ),
                      ),
                      SizedBox(height: h * 0.01),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return locale.t('required_field');
                          }
                          String cleaned = value.replaceAll(RegExp(r'[\s-]'), '');
                          if (!RegExp(r'^07[3-9]\d{8}$').hasMatch(cleaned)) {
                            return locale.t('invalid_phone_number');
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: '07XX XXX XXXX',
                          hintStyle: TextStyle(
                            color: Theme.of(context).textTheme.displayMedium!.color,
                            fontSize: w * 0.035,
                          ),
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF3B82F6),
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFEF4444),
                              width: 2,
                            ),
                          ),
                          prefixIcon:  Icon(
                            Icons.phone_outlined,
                            color: Theme.of(context).textTheme.displayMedium!.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: h * 0.02),

                  // Password Field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            locale.t('password'),
                            style: TextStyle(
                              fontSize: w * 0.035,
                              fontWeight: FontWeight.w600,
                                color: Theme.of(context).textTheme.bodyLarge!.color
                            ),
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: Text(
                              locale.t('forgot_password'),
                              style: TextStyle(
                                fontSize: w * 0.035,
                                color: const Color(0xFFB91C4C),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: h * 0.01),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return locale.t('required_field');
                          }
                          if (value.length < 3) {
                            return locale.t('password_too_short');
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: locale.t('enter_password'),
                          hintStyle: TextStyle(
                            color:Theme.of(context).textTheme.displayMedium!.color,
                            fontSize: w * 0.035,
                          ),
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF3B82F6),
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFEF4444),
                              width: 2,
                            ),
                          ),
                          prefixIcon:  Icon(
                            Icons.lock_outline,
                            color: Theme.of(context).textTheme.displayMedium!.color,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: const Color(0xFF64748B),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: h * 0.015),

                  // Register Link
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: Text(
                        locale.t('create_account'),
                        style: TextStyle(
                          fontSize: w * 0.035,
                          color: const Color(0xFF3B82F6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: h * 0.03),

                  // Login Button
                  Consumer<AuthProvider>(
                    builder: (context, auth, child) {
                      return SizedBox(
                        width: double.infinity,
                        height: h * 0.07,
                        child: ElevatedButton(
                          onPressed: auth.isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A2C),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: auth.isLoading
                              ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : Text(
                            locale.t('login'),
                            style: TextStyle(
                              fontSize: w * 0.045,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: h * 0.02),

                  // Continue as Guest
                  OutlinedButton(
                    onPressed: () {
                      // Clear all favorites data for guest mode (not just the user ID)
                      final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);
                      favoritesProvider.clearFavorites(); // This clears favorites list and sets userId to null

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MainScreen(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: h * 0.018),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      locale.t('guest'),
                      style: TextStyle(
                        fontSize: w * 0.04,
                        color: Theme.of(context).textTheme.displayMedium!.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}