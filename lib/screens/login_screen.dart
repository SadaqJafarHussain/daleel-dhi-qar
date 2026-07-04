import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tour_guid/screens/main_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../providers/app_config_provider.dart';
import '../providers/favorites_provider.dart';
import '../services/supabase_auth_service.dart';
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

  Future<void> _showForgotPasswordDialog() async {
    final locale = AppLocalizations.of(context);
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    // step: 'phone' | 'loading' | 'success' | 'not_found' | 'already_pending' | 'error'
    String step = 'phone';

    await showDialog(
      context: context,
      barrierDismissible: step == 'loading' ? false : true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final primaryColor = Theme.of(context).primaryColor;

          // ── Loading ────────────────────────────────────────────────────────
          if (step == 'loading') {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: primaryColor),
                    const SizedBox(height: 16),
                    Text(
                      locale.t('please_wait'),
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          }

          // ── Success ────────────────────────────────────────────────────────
          if (step == 'success') {
            final whatsapp = context.read<AppConfigProvider>().whatsapp;
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 4),
              actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check_circle_outline, color: Colors.green.shade600, size: 40),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    locale.t('reset_request_success_title'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    locale.t('reset_request_success_desc'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.55),
                  ),
                  if (whatsapp.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Divider(color: Colors.grey.shade200),
                    const SizedBox(height: 10),
                    Text(
                      locale.t('reset_request_contact'),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.chat_bubble_outline, size: 16, color: Color(0xFF25D366)),
                        label: Text(
                          locale.t('reset_request_whatsapp'),
                          style: const TextStyle(color: Color(0xFF25D366), fontWeight: FontWeight.w600),
                        ),
                        onPressed: () {
                          final cleaned = whatsapp.replaceAll(RegExp(r'[\s+\-()]'), '');
                          launchUrl(
                            Uri.parse('https://wa.me/$cleaned'),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF25D366)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(locale.t('confirm'), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            );
          }

          // ── Non-success result views (not_found / already_pending / error) ─
          if (step != 'phone') {
            final isAlreadyPending = step == 'already_pending';
            final isNotFound = step == 'not_found';

            final Color iconBgColor = isAlreadyPending
                ? Colors.blue.shade50
                : isNotFound
                    ? Colors.orange.shade50
                    : Colors.red.shade50;
            final Color iconColor = isAlreadyPending
                ? Colors.blue.shade600
                : isNotFound
                    ? Colors.orange.shade600
                    : Colors.red.shade600;
            final IconData icon = isAlreadyPending
                ? Icons.hourglass_top_rounded
                : isNotFound
                    ? Icons.phone_disabled_outlined
                    : Icons.error_outline;
            final String message = isAlreadyPending
                ? locale.t('reset_request_already_pending')
                : isNotFound
                    ? locale.t('reset_request_phone_not_found')
                    : locale.t('reset_request_failed');

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 4),
              actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
                    child: Icon(icon, color: iconColor, size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.55),
                  ),
                ],
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(locale.t('cancel')),
                      ),
                    ),
                    if (!isAlreadyPending) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => setS(() => step = 'phone'),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(locale.t('try_again')),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            );
          }

          // ── Phone input (default) ──────────────────────────────────────────
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
            actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            title: Row(
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.lock_reset, color: primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    locale.t('forgot_password'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    locale.t('reset_request_desc'),
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: '07XX XXX XXXX',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return locale.t('required_field');
                      final cleaned = v.replaceAll(RegExp(r'[\s-]'), '');
                      if (!RegExp(r'^07[3-9]\d{8}$').hasMatch(cleaned)) {
                        return locale.t('invalid_phone_number');
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(locale.t('cancel')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: Text(locale.t('reset_request_submit')),
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        setS(() => step = 'loading');
                        final result = await SupabaseAuthService()
                            .submitPasswordResetRequest(phoneController.text.trim());
                        if (!ctx.mounted) return;
                        setS(() {
                          switch (result) {
                            case ResetRequestResult.success:
                              step = 'success';
                            case ResetRequestResult.phoneNotFound:
                              step = 'not_found';
                            case ResetRequestResult.alreadyPending:
                              step = 'already_pending';
                            default:
                              step = 'error';
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    phoneController.dispose();
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
          content: Text(authProvider.errorMessage ?? locale.t('login_failed')),
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
                            onTap: _showForgotPasswordDialog,
                            child: Text(
                              locale.t('forgot_password'),
                              style: TextStyle(
                                fontSize: w * 0.035,
                                color: Theme.of(context).primaryColor,
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
                            backgroundColor: Theme.of(context).colorScheme.secondary,
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