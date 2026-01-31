import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tour_guid/providers/language_provider.dart';

import '../../utils/app_localization.dart';
import '../../utils/app_texts_style.dart';

class LanguageSelector extends StatelessWidget {
  final double width;
  final double height;

  const LanguageSelector({
    Key? key,
    required this.width,
    required this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final loc = AppLocalizations.of(context);
    final w = width;
    final h = height;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: w * 0.045, vertical: w * 0.015),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showLanguageBottomSheet(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.018),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.language,
                    color: const Color(0xFF8B5CF6),
                    size: w * 0.055,
                  ),
                ),
                SizedBox(width: w * 0.035),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.t('language'),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: AppTextSizes.cardTitle,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        languageProvider.isArabic
                            ? loc.t('arabic')
                            : loc.t('english'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: w * 0.032,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: w * 0.04,
                  color: Theme.of(context).iconTheme.color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLanguageBottomSheet(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final loc = AppLocalizations.of(context);
    final w = MediaQuery.of(context).size.width;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Theme.of(context).cardColor,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(w * 0.05),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: w * 0.05),

              // Title
              Text(
                loc.t('language'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: w * 0.05,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: w * 0.04),

              // Arabic Option
              _buildLanguageOption(
                context,
                language: loc.t('arabic'),
                languageCode: 'ar',
                icon: '🇮🇶', // 🇮🇶 Iraq flag
                isSelected: languageProvider.isArabic,
                onTap: () {
                  languageProvider.changeLanguage('ar');
                  Navigator.pop(context);
                },
              ),
              SizedBox(height: w * 0.03),

              // English Option
              _buildLanguageOption(
                context,
                language: 'English',
                languageCode: 'en',
                icon: '🇺🇸',
                isSelected: languageProvider.isEnglish,
                onTap: () {
                  languageProvider.changeLanguage('en');
                  Navigator.pop(context);
                },
              ),
              SizedBox(height: w * 0.05),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(
      BuildContext context, {
        required String language,
        required String languageCode,
        required String icon,
        required bool isSelected,
        required VoidCallback onTap,
      }) {
    final w = MediaQuery.of(context).size.width;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(w * 0.04),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Theme.of(context).dividerColor,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Text(
              icon,
              style: TextStyle(fontSize: w * 0.08),
            ),
            SizedBox(width: w * 0.04),
            Expanded(
              child: Text(
                language,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: w * 0.045,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Theme.of(context).primaryColor : null,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).primaryColor,
                size: w * 0.06,
              ),
          ],
        ),
      ),
    );
  }
}