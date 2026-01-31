import 'package:flutter/material.dart';
import '../services/supabase_auth_service.dart';
import '../utils/app_localization.dart';
import '../utils/app_texts_style.dart';
import '../utils/app_icons.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authService = SupabaseAuthService();
    final success = await authService.updatePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      final loc = AppLocalizations.of(context);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.t('password_changed')),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.t('password_change_failed')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: AppBackButton.light(),
        ),
        title: Text(
          loc.t('change_password'),
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
            fontSize: AppTextSizes.h2,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(w * 0.04),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Security Icon
              Center(
                child: Container(
                  width: w * 0.25,
                  height: w * 0.25,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    size: w * 0.12,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
              ),
              SizedBox(height: h * 0.02),

              // Info Text
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: w * 0.05),
                  child: Text(
                    loc.t('password_requirements'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppTextSizes.bodySmall,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              SizedBox(height: h * 0.04),

              // Current Password
              _buildLabel(loc.t('current_password')),
              SizedBox(height: h * 0.01),
              _buildPasswordField(
                controller: _currentPasswordController,
                hint: loc.t('enter_current_password'),
                obscure: _obscureCurrentPassword,
                onToggle: () {
                  setState(() => _obscureCurrentPassword = !_obscureCurrentPassword);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc.t('required_field');
                  }
                  return null;
                },
              ),
              SizedBox(height: h * 0.02),

              // New Password
              _buildLabel(loc.t('new_password')),
              SizedBox(height: h * 0.01),
              _buildPasswordField(
                controller: _newPasswordController,
                hint: loc.t('enter_new_password'),
                obscure: _obscureNewPassword,
                onToggle: () {
                  setState(() => _obscureNewPassword = !_obscureNewPassword);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc.t('required_field');
                  }
                  if (value.length < 6) {
                    return loc.t('password_min_6');
                  }
                  if (value == _currentPasswordController.text) {
                    return loc.t('password_must_be_different');
                  }
                  return null;
                },
              ),
              SizedBox(height: h * 0.02),

              // Confirm Password
              _buildLabel(loc.t('confirm_password')),
              SizedBox(height: h * 0.01),
              _buildPasswordField(
                controller: _confirmPasswordController,
                hint: loc.t('confirm_new_password'),
                obscure: _obscureConfirmPassword,
                onToggle: () {
                  setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc.t('required_field');
                  }
                  if (value != _newPasswordController.text) {
                    return loc.t('passwords_not_match');
                  }
                  return null;
                },
              ),
              SizedBox(height: h * 0.01),

              // Password Strength Indicator
              _buildPasswordStrength(_newPasswordController.text),
              SizedBox(height: h * 0.04),

              // Change Password Button
              SizedBox(
                width: double.infinity,
                height: h * 0.065,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    disabledBackgroundColor: Colors.grey.shade400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          loc.t('change_password'),
                          style: TextStyle(
                            fontSize: AppTextSizes.button,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              SizedBox(height: h * 0.02),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: AppTextSizes.bodyMedium,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
        ),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: const Color(0xFFF59E0B),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        prefixIcon: Icon(
          Icons.lock_outline,
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }

  Widget _buildPasswordStrength(String password) {
    if (password.isEmpty) return const SizedBox.shrink();

    int strength = 0;
    if (password.length >= 6) strength++;
    if (password.length >= 8) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;

    Color color;
    String label;
    final loc = AppLocalizations.of(context);

    if (strength <= 1) {
      color = Colors.red;
      label = loc.t('weak');
    } else if (strength <= 3) {
      color = Colors.orange;
      label = loc.t('medium');
    } else {
      color = Colors.green;
      label = loc.t('strong');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: strength / 5,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 6,
                ),
              ),
            ),
            SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
