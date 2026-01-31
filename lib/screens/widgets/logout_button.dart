import 'package:flutter/material.dart';
import 'package:tour_guid/utils/app_localization.dart';
import 'package:tour_guid/utils/app_texts_style.dart';

class LogoutButton extends StatelessWidget {
  final double width;
  final double height;
  final VoidCallback onTap;

  const LogoutButton({
    super.key,
    required this.width,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = width;
    final h = height;
    final loc=AppLocalizations.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w * 0.045),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDarkMode
              ? const Color(0xFFE11D48)  // Lighter rose for dark mode
              : const Color(0xFFB91C4C),  // Original rose for light mode
          boxShadow: [
            BoxShadow(
              color: (isDarkMode
                  ? const Color(0xFFE11D48)
                  : const Color(0xFFEF4444)).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: h * 0.02),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, color: Colors.white, size: w * 0.06),
                  SizedBox(width: w * 0.03),
                  Text(
                    loc.t("logout"),
                    style: TextStyle(
                      fontSize: AppTextSizes.cardTitle,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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