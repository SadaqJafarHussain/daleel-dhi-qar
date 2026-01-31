import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../utils/app_localization.dart';
import '../utils/app_texts_style.dart';
import '../utils/app_icons.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  Gender? _selectedGender;
  DateTime? _selectedBirthDate;
  String? _selectedCity;
  String? _selectedOccupation;
  List<String> _selectedInterests = [];

  // Store original values to preserve when not changed
  String? _originalCity;
  String? _originalOccupation;
  List<String>? _originalInterests;

  bool _isLoading = false;
  bool _hasChanges = false;
  bool _isUploadingAvatar = false;
  String? _avatarUrl;
  File? _selectedImage;

  // City keys for localization
  final List<String> _iraqiCities = [
    'city_nasiriyah',
    'city_basra',
    'city_baghdad',
    'city_najaf',
    'city_karbala',
    'city_mosul',
    'city_erbil',
    'city_sulaymaniyah',
    'city_kirkuk',
    'city_ramadi',
    'city_baqubah',
    'city_kut',
    'city_amarah',
    'city_samawah',
    'city_diwaniyah',
    'city_hilla',
    'city_tikrit',
    'city_duhok',
  ];

  // Occupation keys for localization
  final List<String> _occupations = [
    'occupation_student',
    'occupation_government',
    'occupation_private',
    'occupation_business_owner',
    'occupation_doctor',
    'occupation_engineer',
    'occupation_teacher',
    'occupation_merchant',
    'occupation_retired',
    'occupation_housewife',
    'occupation_other',
  ];

  // Interest keys for localization
  final List<String> _interests = [
    'interest_restaurants',
    'interest_hotels',
    'interest_shopping',
    'interest_healthcare',
    'interest_education',
    'interest_tourism',
    'interest_sports',
    'interest_entertainment',
    'interest_automotive',
    'interest_real_estate',
  ];

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _selectedGender = user?.gender;
    _selectedBirthDate = user?.birthDate;
    _avatarUrl = user?.avatarUrl;

    // Store original values to preserve if user doesn't change them
    _originalCity = user?.city;
    _originalOccupation = user?.occupation;
    _originalInterests = user?.interests;

    // Only set city if it exists in the list, otherwise null (user can re-select)
    final userCity = user?.city;
    _selectedCity = (userCity != null && _iraqiCities.contains(userCity)) ? userCity : null;

    // Only set occupation if it exists in the list
    final userOccupation = user?.occupation;
    _selectedOccupation = (userOccupation != null && _occupations.contains(userOccupation)) ? userOccupation : null;

    // Filter interests to only include valid ones from the list
    _selectedInterests = (user?.interests ?? []).where((i) => _interests.contains(i)).toList();

    _nameController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: Text(AppLocalizations.of(context).t('camera')),
              onTap: () async {
                Navigator.pop(context);
                final image = await picker.pickImage(
                  source: ImageSource.camera,
                  maxWidth: 512,
                  maxHeight: 512,
                  imageQuality: 75,
                );
                if (image != null) {
                  setState(() {
                    _selectedImage = File(image.path);
                    _hasChanges = true;
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(AppLocalizations.of(context).t('gallery')),
              onTap: () async {
                Navigator.pop(context);
                final image = await picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 512,
                  maxHeight: 512,
                  imageQuality: 75,
                );
                if (image != null) {
                  setState(() {
                    _selectedImage = File(image.path);
                    _hasChanges = true;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadAvatar() async {
    if (_selectedImage == null) return _avatarUrl;

    setState(() => _isUploadingAvatar = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.supabaseUserId;
      if (userId == null) return null;

      final fileExt = _selectedImage!.path.split('.').last;
      final fileName = '$userId/avatar.$fileExt';

      // Upload to Supabase Storage
      await Supabase.instance.client.storage
          .from('avatars')
          .upload(
            fileName,
            _selectedImage!,
            fileOptions: const FileOptions(upsert: true),
          );

      // Get public URL
      final publicUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(fileName);

      // Add cache buster to force refresh
      final urlWithCacheBuster = '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';

      setState(() {
        _avatarUrl = urlWithCacheBuster;
        _isUploadingAvatar = false;
      });

      return urlWithCacheBuster;
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      setState(() => _isUploadingAvatar = false);
      return null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Upload avatar first if a new image was selected
    String? newAvatarUrl = _avatarUrl;
    if (_selectedImage != null) {
      newAvatarUrl = await _uploadAvatar();
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user!;

    // Use selected values if changed, otherwise preserve original values
    final cityToSave = _selectedCity ?? _originalCity;
    final occupationToSave = _selectedOccupation ?? _originalOccupation;
    final interestsToSave = _selectedInterests.isNotEmpty ? _selectedInterests : _originalInterests;

    final updatedUser = UserModel(
      id: currentUser.id,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      role: currentUser.role,
      active: currentUser.active,
      gender: _selectedGender,
      birthDate: _selectedBirthDate,
      city: cityToSave,
      interests: interestsToSave,
      occupation: occupationToSave,
      avatarUrl: newAvatarUrl,
    );

    final success = await authProvider.updateUserProfile(updatedUser);

    setState(() => _isLoading = false);

    if (mounted) {
      final loc = AppLocalizations.of(context);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.t('profile_updated')),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.t('error_saving_profile')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _selectBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(now.year - 25),
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 13),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
        _hasChanges = true;
      });
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
          loc.t('edit_profile'),
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
            fontSize: AppTextSizes.h2,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isLoading ? null : _saveProfile,
              child: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).primaryColor,
                      ),
                    )
                  : Text(
                      loc.t('save'),
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(w * 0.04),
          children: [
            // Profile Picture Section
            Center(
              child: GestureDetector(
                onTap: _isUploadingAvatar ? null : _pickImage,
                child: Stack(
                  children: [
                    // Avatar image or placeholder
                    _isUploadingAvatar
                        ? CircleAvatar(
                            radius: w * 0.15,
                            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                            child: const CircularProgressIndicator(),
                          )
                        : _selectedImage != null
                            ? CircleAvatar(
                                radius: w * 0.15,
                                backgroundImage: FileImage(_selectedImage!),
                              )
                            : _avatarUrl != null && _avatarUrl!.isNotEmpty
                                ? CircleAvatar(
                                    radius: w * 0.15,
                                    backgroundImage: NetworkImage(_avatarUrl!),
                                    onBackgroundImageError: (_, __) {},
                                  )
                                : CircleAvatar(
                                    radius: w * 0.15,
                                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                    child: Text(
                                      _nameController.text.isNotEmpty
                                          ? _nameController.text[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        fontSize: w * 0.12,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ),
                    // Camera icon overlay
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: w * 0.05,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: h * 0.03),

            // Name Field
            _buildSectionTitle(loc.t('full_name'), Icons.person_outline),
            SizedBox(height: h * 0.01),
            _buildTextField(
              controller: _nameController,
              hint: loc.t('enter_name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return loc.t('required_field');
                }
                if (value.length < 3) {
                  return loc.t('name_min_3');
                }
                return null;
              },
            ),
            SizedBox(height: h * 0.02),

            // Phone Field (Read-only)
            _buildSectionTitle(loc.t('phone_number'), Icons.phone_outlined),
            SizedBox(height: h * 0.01),
            _buildTextField(
              controller: _phoneController,
              hint: loc.t('phone_number'),
              enabled: false,
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: h * 0.02),

            // Gender Selection
            _buildSectionTitle(loc.t('gender'), Icons.wc_outlined),
            SizedBox(height: h * 0.01),
            Row(
              children: [
                Expanded(
                  child: _buildGenderOption(
                    title: loc.t('male'),
                    icon: Icons.male,
                    isSelected: _selectedGender == Gender.male,
                    onTap: () {
                      setState(() {
                        _selectedGender = Gender.male;
                        _hasChanges = true;
                      });
                    },
                  ),
                ),
                SizedBox(width: w * 0.03),
                Expanded(
                  child: _buildGenderOption(
                    title: loc.t('female'),
                    icon: Icons.female,
                    isSelected: _selectedGender == Gender.female,
                    onTap: () {
                      setState(() {
                        _selectedGender = Gender.female;
                        _hasChanges = true;
                      });
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: h * 0.02),

            // Birth Date
            _buildSectionTitle(loc.t('birth_date'), Icons.cake_outlined),
            SizedBox(height: h * 0.01),
            InkWell(
              onTap: _selectBirthDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.all(w * 0.04),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                    SizedBox(width: w * 0.03),
                    Text(
                      _selectedBirthDate != null
                          ? '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}'
                          : loc.t('select_birth_date'),
                      style: TextStyle(
                        color: _selectedBirthDate != null
                            ? Theme.of(context).textTheme.bodyLarge?.color
                            : (isDark ? Colors.grey.shade500 : Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: h * 0.02),

            // City Selection
            _buildSectionTitle(loc.t('city'), Icons.location_city_outlined),
            SizedBox(height: h * 0.01),
            _buildDropdown(
              value: _selectedCity,
              hint: loc.t('select_city'),
              items: _iraqiCities,
              onChanged: (value) {
                setState(() {
                  _selectedCity = value;
                  _hasChanges = true;
                });
              },
            ),
            SizedBox(height: h * 0.02),

            // Occupation Selection
            _buildSectionTitle(loc.t('occupation'), Icons.work_outline),
            SizedBox(height: h * 0.01),
            _buildDropdown(
              value: _selectedOccupation,
              hint: loc.t('select_occupation'),
              items: _occupations,
              onChanged: (value) {
                setState(() {
                  _selectedOccupation = value;
                  _hasChanges = true;
                });
              },
            ),
            SizedBox(height: h * 0.02),

            // Interests
            _buildSectionTitle(loc.t('interests'), Icons.interests_outlined),
            SizedBox(height: h * 0.01),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _interests.map((interest) {
                final isSelected = _selectedInterests.contains(interest);
                return FilterChip(
                  label: Text(loc.t(interest)), // Translate the key
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedInterests.add(interest);
                      } else {
                        _selectedInterests.remove(interest);
                      }
                      _hasChanges = true;
                    });
                  },
                  selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                  checkmarkColor: Theme.of(context).primaryColor,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: h * 0.04),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: h * 0.065,
              child: ElevatedButton(
                onPressed: _hasChanges && !_isLoading ? _saveProfile : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
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
                        loc.t('save_changes'),
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
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: AppTextSizes.bodyMedium,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
        ),
        filled: true,
        fillColor: enabled
            ? Theme.of(context).cardColor
            : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
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
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildGenderOption({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: TextStyle(
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
            ),
          ),
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(loc.t(item)), // Translate the key
            );
          }).toList(),
          onChanged: onChanged,
          // Show translated selected value
          selectedItemBuilder: (context) {
            return items.map((item) {
              return Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(loc.t(item)),
              );
            }).toList();
          },
        ),
      ),
    );
  }
}
