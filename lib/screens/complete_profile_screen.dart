import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../utils/app_localization.dart';
import 'main_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  final bool isFromRegistration;

  const CompleteProfileScreen({
    Key? key,
    this.isFromRegistration = true,
  }) : super(key: key);

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Form data
  Gender? _selectedGender;
  DateTime? _selectedBirthDate;
  String? _selectedCity;
  final Set<String> _selectedInterests = {};
  String? _selectedOccupation;

  // Current step
  int _currentStep = 0;
  final int _totalSteps = 4;

  bool _isLoading = false;

  // Iraqi cities - keys for localization
  final List<String> _iraqiCityKeys = [
    'city_baghdad',
    'city_basra',
    'city_mosul',
    'city_erbil',
    'city_najaf',
    'city_karbala',
    'city_nasiriyah',
    'city_sulaymaniyah',
    'city_kirkuk',
    'city_hilla',
    'city_diwaniyah',
    'city_kut',
    'city_samawah',
    'city_amarah',
    'city_ramadi',
    'city_baqubah',
    'city_tikrit',
    'city_duhok',
  ];

  // Interests for ad targeting - using localization keys
  final List<Map<String, dynamic>> _availableInterests = [
    {'id': 'restaurants', 'nameKey': 'interest_restaurants', 'icon': Icons.restaurant_rounded},
    {'id': 'hotels', 'nameKey': 'interest_hotels', 'icon': Icons.hotel_rounded},
    {'id': 'tourism', 'nameKey': 'interest_tourism', 'icon': Icons.museum_rounded},
    {'id': 'shopping', 'nameKey': 'interest_shopping', 'icon': Icons.shopping_bag_rounded},
    {'id': 'healthcare', 'nameKey': 'interest_healthcare', 'icon': Icons.local_hospital_rounded},
    {'id': 'education', 'nameKey': 'interest_education', 'icon': Icons.school_rounded},
    {'id': 'sports', 'nameKey': 'interest_sports', 'icon': Icons.sports_soccer_rounded},
    {'id': 'entertainment', 'nameKey': 'interest_entertainment', 'icon': Icons.movie_rounded},
    {'id': 'automotive', 'nameKey': 'interest_automotive', 'icon': Icons.directions_car_rounded},
    {'id': 'real_estate', 'nameKey': 'interest_real_estate', 'icon': Icons.home_rounded},
  ];

  // Occupations - using localization keys
  final List<String> _occupationKeys = [
    'occupation_student',
    'occupation_government',
    'occupation_private',
    'occupation_freelance',
    'occupation_doctor',
    'occupation_engineer',
    'occupation_teacher',
    'occupation_merchant',
    'occupation_retired',
    'occupation_housewife',
    'occupation_other',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();

    // Load existing user data if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user != null) {
        setState(() {
          _selectedGender = user.gender;
          _selectedBirthDate = user.birthDate;
          _selectedCity = user.city;
          if (user.interests != null) {
            _selectedInterests.addAll(user.interests!);
          }
          _selectedOccupation = user.occupation;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    final now = DateTime.now();
    final initialDate = _selectedBirthDate ?? DateTime(now.year - 25, 1, 1);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 10), // Must be at least 10 years old
      locale: const Locale('ar'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Theme.of(context).cardColor,
              onSurface: Theme.of(context).textTheme.bodyLarge!.color!,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      _saveProfile();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.user;

      if (currentUser != null) {
        final updatedUser = currentUser.copyWith(
          gender: _selectedGender,
          birthDate: _selectedBirthDate,
          city: _selectedCity,
          interests: _selectedInterests.toList(),
          occupation: _selectedOccupation,
          profileCompleted: true,
        );

        await authProvider.updateUserProfile(updatedUser);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final locale = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(locale.t('error_saving_profile')),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Header with progress
              _buildHeader(w, h, isDark),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildCurrentStep(w, h, isDark),
                  ),
                ),
              ),

              // Bottom buttons
              _buildBottomButtons(w, h, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(double w, double h, bool isDark) {
    final locale = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.all(w * 0.06),
      child: Column(
        children: [
          // Title
          Text(
            locale.t('complete_profile'),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),

          SizedBox(height: h * 0.01),

          Text(
            locale.t('complete_profile_subtitle'),
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: h * 0.03),

          // Progress indicator
          _buildProgressIndicator(w, isDark),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(double w, bool isDark) {
    return Row(
      children: List.generate(_totalSteps, (index) {
        final isActive = index <= _currentStep;
        return Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 4),
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: isActive
                  ? Theme.of(context).primaryColor
                  : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCurrentStep(double w, double h, bool isDark) {
    switch (_currentStep) {
      case 0:
        return _buildGenderStep(w, h, isDark);
      case 1:
        return _buildBirthDateStep(w, h, isDark);
      case 2:
        return _buildLocationStep(w, h, isDark);
      case 3:
        return _buildInterestsStep(w, h, isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildGenderStep(double w, double h, bool isDark) {
    final locale = AppLocalizations.of(context);
    return Column(
      key: const ValueKey('gender'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: h * 0.02),
        _buildStepTitle(locale.t('what_is_your_gender'), Icons.person_outline_rounded),
        SizedBox(height: h * 0.03),

        // Gender options
        ...Gender.values.map((gender) {
          final isSelected = _selectedGender == gender;
          return Padding(
            padding: EdgeInsets.only(bottom: h * 0.015),
            child: _buildOptionCard(
              title: gender == Gender.male ? locale.t('male') : locale.t('female'),
              icon: gender == Gender.male
                  ? Icons.male_rounded
                  : gender == Gender.female
                      ? Icons.female_rounded
                      : Icons.transgender_rounded,
              isSelected: isSelected,
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _selectedGender = gender;
                });
              },
              isDark: isDark,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBirthDateStep(double w, double h, bool isDark) {
    final locale = AppLocalizations.of(context);
    final age = _selectedBirthDate != null
        ? DateTime.now().year - _selectedBirthDate!.year
        : null;

    return Column(
      key: const ValueKey('birthdate'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: h * 0.02),
        _buildStepTitle(locale.t('when_were_you_born'), Icons.cake_rounded),
        SizedBox(height: h * 0.03),

        // Date picker button
        GestureDetector(
          onTap: _selectBirthDate,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A3E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _selectedBirthDate != null
                    ? Theme.of(context).primaryColor
                    : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                width: _selectedBirthDate != null ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.calendar_month_rounded,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedBirthDate != null
                            ? '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}'
                            : locale.t('select_birth_date'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                        ),
                      ),
                      if (age != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '$age ${locale.t('years_old')}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_left_rounded,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: h * 0.02),
      ],
    );
  }

  Widget _buildLocationStep(double w, double h, bool isDark) {
    final locale = AppLocalizations.of(context);
    return Column(
      key: const ValueKey('location'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: h * 0.02),
        _buildStepTitle(locale.t('where_do_you_live'), Icons.location_on_rounded),
        SizedBox(height: h * 0.03),

        // City dropdown
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A3E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _selectedCity != null
                  ? Theme.of(context).primaryColor
                  : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
              width: _selectedCity != null ? 2 : 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCity,
              hint: Text(
                locale.t('select_city'),
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              dropdownColor: isDark ? const Color(0xFF2A2A3E) : Colors.white,
              items: _iraqiCityKeys.map((cityKey) {
                return DropdownMenuItem<String>(
                  value: cityKey,
                  child: Text(
                    locale.t(cityKey),
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                HapticFeedback.lightImpact();
                setState(() {
                  _selectedCity = value;
                });
              },
            ),
          ),
        ),

        SizedBox(height: h * 0.03),

        // Occupation
        _buildStepTitle(locale.t('what_is_your_occupation'), Icons.work_outline_rounded),
        SizedBox(height: h * 0.02),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A3E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _selectedOccupation != null
                  ? Theme.of(context).primaryColor
                  : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
              width: _selectedOccupation != null ? 2 : 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedOccupation,
              hint: Text(
                locale.t('select_occupation'),
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              dropdownColor: isDark ? const Color(0xFF2A2A3E) : Colors.white,
              items: _occupationKeys.map((occupationKey) {
                return DropdownMenuItem<String>(
                  value: occupationKey,
                  child: Text(
                    locale.t(occupationKey),
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                HapticFeedback.lightImpact();
                setState(() {
                  _selectedOccupation = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInterestsStep(double w, double h, bool isDark) {
    final locale = AppLocalizations.of(context);
    return Column(
      key: const ValueKey('interests'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: h * 0.02),
        _buildStepTitle(locale.t('what_are_your_interests'), Icons.favorite_rounded),
        SizedBox(height: h * 0.01),
        Text(
          locale.t('select_interests'),
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        SizedBox(height: h * 0.03),

        // Interests grid
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _availableInterests.map((interest) {
            final isSelected = _selectedInterests.contains(interest['id']);
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  if (isSelected) {
                    _selectedInterests.remove(interest['id']);
                  } else {
                    _selectedInterests.add(interest['id']);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : (isDark ? const Color(0xFF2A2A3E) : Colors.white),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Theme.of(context).primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      interest['icon'] as IconData,
                      size: 18,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      locale.t(interest['nameKey'] as String),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white : const Color(0xFF1A1A2E)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        SizedBox(height: h * 0.03),

        // Selected count
        if (_selectedInterests.isNotEmpty)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                locale.t('interests_selected').replaceAll('{count}', '${_selectedInterests.length}'),
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStepTitle(String title, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : (isDark ? const Color(0xFF2A2A3E) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            const Spacer(),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons(double w, double h, bool isDark) {
    final locale = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.all(w * 0.06),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: h * 0.02),
                  side: BorderSide(
                    color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  locale.t('previous'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
              ),
            ),

          if (_currentStep > 0) SizedBox(width: w * 0.04),

          // Next/Save button
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: EdgeInsets.symmetric(vertical: h * 0.02),
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
                      _currentStep == _totalSteps - 1 ? locale.t('finish') : locale.t('next'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
