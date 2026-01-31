import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tour_guid/screens/complete_profile_screen.dart';
import 'package:tour_guid/screens/main_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/favorites_provider.dart';
import '../utils/app_localization.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final locale = AppLocalizations.of(context);

    final success = await authProvider.register(
      _nameController.text.trim(),
      _phoneController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      // Set Supabase user ID for favorites provider
      if (authProvider.supabaseUserId != null) {
        final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);
        favoritesProvider.setSupabaseUserId(authProvider.supabaseUserId);
      }

      // Navigate to profile completion screen after successful registration
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const CompleteProfileScreen(
            isFromRegistration: true,
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? locale.t('service_saved')),
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
                  // Logo
                  Center(
                    child: Image.asset(
                      'assets/images/splash_logo.png',
                      width: w * 0.4,
                    ),
                  ),

                  // Title
                  Text(
                    locale.t('create_account'),
                    style: TextStyle(
                      fontSize: w * 0.07,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.labelLarge!.color
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: h * 0.01),

                  Text(
                    locale.t('add_service_subtitle'),
                    style: TextStyle(
                      fontSize: w * 0.035,
                      color:  Theme.of(context).textTheme.displayMedium!.color
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: h * 0.03),

                  // Name Field
                  _buildTextField(
                    label: locale.t('name'),
                    hint: locale.t('service_name_hint'),
                    controller: _nameController,
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return locale.t('required_field');
                      }
                      if (value.trim().length < 3) {
                        return locale.t('name_min_3');
                      }
                      return null;
                    },
                    w: w,
                    h: h,
                  ),
                  SizedBox(height: h * 0.02),

                  // Phone Field
                  _buildTextField(
                    label: locale.t('phone_number'),
                    hint: '07XX XXX XXXX',
                    controller: _phoneController,
                    icon: Icons.phone_outlined,
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
                    w: w,
                    h: h,
                  ),
                  SizedBox(height: h * 0.02),

                  // Password Field
                  _buildTextField(
                    label: locale.t('password'),
                    hint: locale.t('enter_password'),
                    controller: _passwordController,
                    icon: Icons.lock_outline,
                    obscureText: _obscurePassword,
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return locale.t('required_field');
                      }
                      if (value.length < 6) {
                        return locale.t('password_min_6');
                      }
                      return null;
                    },
                    w: w,
                    h: h,
                  ),
                  SizedBox(height: h * 0.02),

                  // Confirm Password Field
                  _buildTextField(
                    label: locale.t('confirm_password'),
                    hint: locale.t('confirm_password_des'),
                    controller: _confirmPasswordController,
                    icon: Icons.lock_outline,
                    obscureText: _obscureConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: const Color(0xFF64748B),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return locale.t('required_field');
                      }
                      if (value != _passwordController.text) {
                        return locale.t('passwords_not_match');
                      }
                      return null;
                    },
                    w: w,
                    h: h,
                  ),
                  SizedBox(height: h * 0.03),

                  // Register Button
                  Consumer<AuthProvider>(
                    builder: (context, auth, child) {
                      return SizedBox(
                        width: double.infinity,
                        height: h * 0.07,
                        child: ElevatedButton(
                          onPressed: auth.isLoading ? null : _handleRegister,
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
                            locale.t('create_account'),
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

                  // Already have account
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        locale.t('already_have_account'),
                        style: TextStyle(
                          fontSize: w * 0.035,
                          color: Theme.of(context).textTheme.displaySmall!.color,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          locale.t('login'),
                          style: TextStyle(
                            fontSize: w * 0.035,
                            color: const Color(0xFF3B82F6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Continue as Guest
                  OutlinedButton(
                    onPressed: () {
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
                        color: Theme.of(context).textTheme.displaySmall!.color,
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

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    required String? Function(String?) validator,
    required double w,
    required double h,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: w * 0.035,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.displayLarge!.color
          ),
        ),
        SizedBox(height: h * 0.01),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Theme.of(context).textTheme.displaySmall!.color,
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
            prefixIcon: Icon(icon, color: Theme.of(context).textTheme.displaySmall!.color,),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}