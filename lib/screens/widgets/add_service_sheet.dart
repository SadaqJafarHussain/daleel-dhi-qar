import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:tour_guid/providers/subcategory_provider.dart';
import 'dart:io';
import '../../providers/service_peovider.dart';
import '../../utils/app_localization.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/service_model.dart';
import '../../models/subcategory_model.dart';
import '../../utils/safe_state.dart';
import '../../utils/debouncer.dart';

/// Open sheet for adding a new service
Future<Map<String, dynamic>?> openAddServiceSheet(BuildContext context) async {
  final size = MediaQuery.of(context).size;
  final w = size.width;
  final h = size.height;

  final result = await showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: false,
    enableDrag: false,
    builder: (context) => WillPopScope(
      onWillPop: () async {
        final provider = Provider.of<ServiceProvider>(context, listen: false);
        if (provider.isSaving) {
          return false;
        }
        return true;
      },
      child: AddEditServiceBottomSheet(w: w, h: h),
    ),
  );

  // ✅ Refresh if successful
  if (result != null && result['success'] == true) {
    final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);

    // Force refresh current view
    if (serviceProvider.currentCategoryId != null) {
      await serviceProvider.fetchServicesByCategory(
        serviceProvider.currentCategoryId!,
        forceRefresh: true,
      );
    } else if (serviceProvider.currentSubcategoryId != null) {
      await serviceProvider.fetchServicesBySubcategory(
        serviceProvider.currentSubcategoryId!,
        forceRefresh: true,
      );
    } else {
      await serviceProvider.fetchAllServices(forceRefresh: true);
    }
  }

  return result;
}

/// Open sheet for editing an existing service
Future<Map<String, dynamic>?> openEditServiceSheet(BuildContext context, Service service) async {
  final size = MediaQuery.of(context).size;
  final w = size.width;
  final h = size.height;

  final result = await showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: false,
    enableDrag: false,
    builder: (context) => WillPopScope(
      onWillPop: () async {
        final provider = Provider.of<ServiceProvider>(context, listen: false);
        if (provider.isSaving) {
          return false;
        }
        return true;
      },
      child: AddEditServiceBottomSheet(w: w, h: h, editService: service),
    ),
  );

  // ✅ Refresh if successful
  if (result != null && result['success'] == true) {
    final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);

    // Force refresh current view
    if (serviceProvider.currentCategoryId != null) {
      await serviceProvider.fetchServicesByCategory(
        serviceProvider.currentCategoryId!,
        forceRefresh: true,
      );
    } else if (serviceProvider.currentSubcategoryId != null) {
      await serviceProvider.fetchServicesBySubcategory(
        serviceProvider.currentSubcategoryId!,
        forceRefresh: true,
      );
    } else {
      await serviceProvider.fetchAllServices(forceRefresh: true);
    }
  }

  return result;
}

class AddEditServiceBottomSheet extends StatefulWidget {
  final double w;
  final double h;
  final Service? editService;

  const AddEditServiceBottomSheet({
    Key? key,
    required this.w,
    required this.h,
    this.editService,
  }) : super(key: key);

  bool get isEditMode => editService != null;

  @override
  State<AddEditServiceBottomSheet> createState() => _AddEditServiceBottomSheetState();
}

class _AddEditServiceBottomSheetState extends State<AddEditServiceBottomSheet> with SafeStateMixin {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  // Debouncer for submit button
  final _submitDebouncer = Debouncer(delay: const Duration(milliseconds: 1000));

  // Controllers
  final _serviceNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _telegramController = TextEditingController();

  // Selection state
  int? _selectedCategoryId;
  int? _selectedSubcategoryId;
  String? _selectedCategoryName;
  String? _selectedSubcategoryName;
  List<Subcategory> _availableSubcategories = [];

  double? _selectedLat;
  double? _selectedLng;

  // Validation errors
  String? _categoryError;
  String? _subcategoryError;
  String? _locationError;
  String? _filesError;

  // Attachments
  final List<String> _newAttachmentPaths = [];
  final List<String> _newAttachmentNames = [];
  List<ServiceFile> _existingFiles = [];
  bool _isPickingFiles = false;
  bool _isDeletingFile = false;

  // Working hours
  String _openTime = '09:00';
  String _closeTime = '22:00';
  List<int> _selectedWorkDays = [0, 1, 2, 3, 4, 5, 6]; // All days selected by default
  bool _isOpen24Hours = false;
  bool _isManualOverride = false;

  @override
  void initState() {
    super.initState();

    // Pre-fill data if editing
    if (widget.isEditMode) {
      _serviceNameController.text = widget.editService!.title;
      _phoneController.text = widget.editService!.phone;
      _addressController.text = widget.editService!.address;
      _descriptionController.text = widget.editService!.description;
      _selectedLat = widget.editService!.lat;
      _selectedLng = widget.editService!.lng;
      _selectedCategoryId = widget.editService!.catId;
      _selectedSubcategoryId = widget.editService!.subcatId;
      // ✅ Pre-fill social media
      _facebookController.text = widget.editService!.facebook ?? '';
      _instagramController.text = widget.editService!.instagram ?? '';
      _whatsappController.text = widget.editService!.whatsapp ?? '';
      _telegramController.text = widget.editService!.telegram ?? '';

      // ✅ Pre-fill working hours
      _openTime = widget.editService!.openTime ?? '09:00';
      _closeTime = widget.editService!.closeTime ?? '22:00';
      _selectedWorkDays = widget.editService!.workDaysList.isNotEmpty
          ? widget.editService!.workDaysList
          : [0, 1, 2, 3, 4, 5, 6];
      _isOpen24Hours = widget.editService!.isOpen24Hours ?? false;
      _isManualOverride = widget.editService!.isManualOverride ?? false;

      // Load existing files
      _existingFiles = widget.editService!.files ?? [];
    }

    // Load categories and subcategories
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (categoryProvider.categories.isEmpty && authProvider.token != null) {
        categoryProvider.fetchCategories(context).then((_) {
          if (widget.isEditMode) {
            _preselectCategoryAndSubcategory();
          }
        });
      } else if (widget.isEditMode && categoryProvider.categories.isNotEmpty) {
        _preselectCategoryAndSubcategory();
      }
    });
  }

  @override
  void dispose() {
    _submitDebouncer.dispose();
    _serviceNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _whatsappController.dispose();
    _telegramController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final serviceProvider = Provider.of<ServiceProvider>(context);

    return DraggableScrollableSheet(
      expand: false,
      maxChildSize: 0.95,
      initialChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 60,
              height: 5,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),

            // Header
               Padding(
                padding: EdgeInsets.symmetric(horizontal: widget.w * 0.05),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.isEditMode
                          ? loc.t('edit_service_title')
                          : loc.t('add_service_title'),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontSize: widget.w * 0.048,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!serviceProvider.isSaving)
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.cancel_outlined, color: Theme.of(context).iconTheme.color),
                      )
                    else
                      const SizedBox(width: 48),
                  ],
                ),
              ),

            // Subtitle
               Padding(
                padding: EdgeInsets.symmetric(horizontal: widget.w * 0.02),
                child: Text(
                  widget.isEditMode
                      ? loc.t('edit_service_subtitle')
                      : loc.t('add_service_subtitle'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: widget.w * 0.035,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // Step indicator (for both add and edit mode now)
            SizedBox(height: widget.h * 0.01),
            _buildStepIndicator(isDarkMode),

            // Content
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: EdgeInsets.symmetric(horizontal: widget.w * 0.05),
                child: _currentStep == 0 ? _buildStep1(loc) : _buildStep2(loc),
              ),
            ),

            // Loading indicator or action buttons
            if (serviceProvider.isSaving)
              _buildLoadingSection(loc)
            else
              _buildActionButtons(loc, isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepCircle(1, _currentStep >= 0, isDarkMode),
        Container(
          width: 40,
          height: 2,
          color: _currentStep >= 1
              ? Theme.of(context).primaryColor
              : Theme.of(context).dividerColor,
        ),
        _buildStepCircle(2, _currentStep >= 1, isDarkMode),
      ],
    );
  }

  Widget _buildStepCircle(int step, bool isActive, bool isDarkMode) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive
            ? Theme.of(context).primaryColor
            : isDarkMode
            ? const Color(0xFF1E293B)
            : const Color(0xFFF8FAFC),
        border: Border.all(
          color: isActive
              ? Theme.of(context).primaryColor
              : Theme.of(context).dividerColor,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          '$step',
          style: TextStyle(
            color: isActive ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStep1(AppLocalizations loc) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Category Selection
          _buildCategorySelector(loc),
          SizedBox(height: widget.h * 0.02),

          // Subcategory Selection (only if category is selected)
          if (_selectedCategoryId != null) ...[
            _buildSubcategorySelector(loc),
            SizedBox(height: widget.h * 0.02),
          ],

          // Service Name
          _buildTextField(
            label: loc.t('service_name'),
            hint: loc.t('service_name_hint'),
            controller: _serviceNameController,
            validator: (val) => val == null || val.isEmpty ? loc.t('required_field') : null,
          ),
          SizedBox(height: widget.h * 0.02),

          // Phone Number
          _buildTextField(
            label: loc.t('phone_number'),
            hint: loc.t('phone_hint'),
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            validator: (val) {
              if (val == null || val.isEmpty) return loc.t('required_field');
              if (val.length < 10) return loc.t('invalid_phone');
              return null;
            },
          ),
          SizedBox(height: widget.h * 0.02),

          // Address
          _buildTextField(
            label: loc.t('address'),
            hint: loc.t('address_hint'),
            controller: _addressController,
            validator: (val) => val == null || val.isEmpty ? loc.t('required_field') : null,
          ),
          SizedBox(height: widget.h * 0.02),

          // Description
          _buildTextField(
            label: loc.t('description'),
            hint: loc.t('description_hint'),
            controller: _descriptionController,
            maxLines: 4,
            validator: (val) => val == null || val.isEmpty ? loc.t('required_field') : null,
          ),
          SizedBox(height: widget.h * 0.025),
          // ✅ Social Media Section
          _buildSocialMediaSection(loc),
          SizedBox(height: widget.h * 0.025),
          // ✅ Working Hours Section
          _buildWorkingHoursSection(loc),
          SizedBox(height: widget.h * 0.025),
          // Location Picker
          _buildLocationPicker(loc),
          SizedBox(height: widget.h * 0.02),
        ],
      ),
    );
  }

  // ✅ New Method: Social Media Section
  Widget _buildSocialMediaSection(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.share,
              size: widget.w * 0.05,
              color: Theme.of(context).primaryColor,
            ),
            SizedBox(width: widget.w * 0.02),
            Text(
              loc.t('social_media'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: widget.w * 0.042,
              ),
            ),
          ],
        ),
        SizedBox(height: widget.h * 0.005),
        Text(
          loc.t('social_media_optional'),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: widget.w * 0.032,
            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
          ),
        ),
        SizedBox(height: widget.h * 0.015),

        // Facebook
        _buildSocialTextField(
          label: 'Facebook',
          hint: 'facebook.com/yourpage',
          controller: _facebookController,
          icon: Icons.facebook,
          color: const Color(0xFF1877F2),
        ),
        SizedBox(height: widget.h * 0.015),

        // Instagram
        _buildSocialTextField(
          label: 'Instagram',
          hint: 'instagram.com/yourpage',
          controller: _instagramController,
          icon: Icons.camera_alt,
          color: const Color(0xFFE4405F),
        ),
        SizedBox(height: widget.h * 0.015),

        // WhatsApp
        _buildSocialTextField(
          label: 'WhatsApp',
          hint: '+964xxxxxxxxxx',
          controller: _whatsappController,
          icon: Icons.phone,
          color: const Color(0xFF25D366),
          keyboardType: TextInputType.phone,
        ),
        SizedBox(height: widget.h * 0.015),

        // Telegram
        _buildSocialTextField(
          label: 'Telegram',
          hint: 't.me/yourusername',
          controller: _telegramController,
          icon: Icons.send,
          color: const Color(0xFF0088CC),
        ),
      ],
    );
  }

  // ✅ New Method: Social Media TextField
  Widget _buildSocialTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    required Color color,
    TextInputType? keyboardType,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            SizedBox(width: widget.w * 0.02),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: widget.w * 0.036,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType ?? TextInputType.url,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontSize: widget.w * 0.036,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: widget.w * 0.032,
              color: Colors.grey.shade400,
            ),
            filled: true,
            fillColor: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: widget.w * 0.04,
              vertical: widget.h * 0.012,
            ),
            isDense: true,
          ),
        ),
      ],
    );
  }

  // ✅ Working Hours Section
  Widget _buildWorkingHoursSection(AppLocalizations loc) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Day names for chips
    final dayNames = [
      loc.t('sun'),
      loc.t('mon'),
      loc.t('tue'),
      loc.t('wed'),
      loc.t('thu'),
      loc.t('fri'),
      loc.t('sat'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Icon(
              Icons.schedule,
              size: widget.w * 0.05,
              color: Theme.of(context).primaryColor,
            ),
            SizedBox(width: widget.w * 0.02),
            Text(
              loc.t('working_hours'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: widget.w * 0.042,
              ),
            ),
          ],
        ),
        SizedBox(height: widget.h * 0.005),
        Text(
          loc.t('working_hours_desc'),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: widget.w * 0.032,
            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
          ),
        ),
        SizedBox(height: widget.h * 0.015),

        // Open 24 Hours Toggle
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: widget.w * 0.04,
            vertical: widget.h * 0.012,
          ),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isOpen24Hours
                  ? const Color(0xFF22C55E)
                  : Theme.of(context).dividerColor,
              width: _isOpen24Hours ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.all_inclusive,
                  size: 20,
                  color: const Color(0xFF22C55E),
                ),
              ),
              SizedBox(width: widget.w * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.t('open_24_hours'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: widget.w * 0.036,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      loc.t('open_24_hours_desc'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: widget.w * 0.028,
                        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isOpen24Hours,
                onChanged: (value) {
                  setState(() {
                    _isOpen24Hours = value;
                  });
                },
                activeColor: const Color(0xFF22C55E),
              ),
            ],
          ),
        ),
        SizedBox(height: widget.h * 0.015),

        // Time Pickers (disabled if 24 hours)
        if (!_isOpen24Hours) ...[
          Row(
            children: [
              // Open Time
              Expanded(
                child: _buildTimePicker(
                  label: loc.t('open_time'),
                  time: _openTime,
                  icon: Icons.wb_sunny_outlined,
                  color: const Color(0xFFFBBF24),
                  onTap: () => _selectTime(true),
                ),
              ),
              SizedBox(width: widget.w * 0.03),
              // Close Time
              Expanded(
                child: _buildTimePicker(
                  label: loc.t('close_time'),
                  time: _closeTime,
                  icon: Icons.nights_stay_outlined,
                  color: const Color(0xFF6366F1),
                  onTap: () => _selectTime(false),
                ),
              ),
            ],
          ),
          SizedBox(height: widget.h * 0.015),

          // Work Days Selection
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.t('work_days'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: widget.w * 0.036,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.w * 0.025,
                  vertical: widget.h * 0.005,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_selectedWorkDays.length}/7 ${loc.t('days_selected')}',
                  style: TextStyle(
                    fontSize: widget.w * 0.03,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: widget.h * 0.005),
          Text(
            loc.t('tap_to_select_deselect'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: widget.w * 0.028,
              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
            ),
          ),
          SizedBox(height: widget.h * 0.01),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(7, (index) {
              final isSelected = _selectedWorkDays.contains(index);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedWorkDays.remove(index);
                    } else {
                      _selectedWorkDays.add(index);
                      _selectedWorkDays.sort();
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.w * 0.035,
                    vertical: widget.h * 0.01,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : isDarkMode
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).dividerColor,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    dayNames[index],
                    style: TextStyle(
                      fontSize: widget.w * 0.032,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: widget.h * 0.015),
        ],

        // Manual Override Toggle
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: widget.w * 0.04,
            vertical: widget.h * 0.012,
          ),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isManualOverride
                  ? const Color(0xFFF59E0B)
                  : Theme.of(context).dividerColor,
              width: _isManualOverride ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.toggle_on_outlined,
                  size: 20,
                  color: const Color(0xFFF59E0B),
                ),
              ),
              SizedBox(width: widget.w * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.t('manual_override'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: widget.w * 0.036,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      loc.t('manual_override_desc'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: widget.w * 0.028,
                        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isManualOverride,
                onChanged: (value) {
                  setState(() {
                    _isManualOverride = value;
                  });
                },
                activeColor: const Color(0xFFF59E0B),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Time Picker Widget
  Widget _buildTimePicker({
    required String label,
    required String time,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              SizedBox(width: widget.w * 0.015),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: widget.w * 0.032,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.w * 0.04,
              vertical: widget.h * 0.015,
            ),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.access_time, size: 18, color: color),
                SizedBox(width: widget.w * 0.02),
                Text(
                  time,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: widget.w * 0.04,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Select Time Method
  Future<void> _selectTime(bool isOpenTime) async {
    final initialTime = TimeOfDay(
      hour: int.tryParse((isOpenTime ? _openTime : _closeTime).split(':')[0]) ?? 9,
      minute: int.tryParse((isOpenTime ? _openTime : _closeTime).split(':')[1]) ?? 0,
    );

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Theme.of(context).cardColor,
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              dayPeriodShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isOpenTime) {
          _openTime = formattedTime;
        } else {
          _closeTime = formattedTime;
        }
      });
    }
  }

  Widget _buildCategorySelector(AppLocalizations loc) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final hasError = _categoryError != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.t('category'),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontSize: widget.w * 0.038,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: categoryProvider.isLoading ? null : () => _showCategoryPicker(loc),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.w * 0.04,
              vertical: widget.h * 0.015,
            ),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasError
                    ? const Color(0xFFEF4444)
                    : _selectedCategoryId == null
                    ? Theme.of(context).dividerColor
                    : Theme.of(context).primaryColor,
                width: hasError || _selectedCategoryId != null ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedCategoryName ?? loc.t('select_category'),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: widget.w * 0.038,
                      color: hasError
                          ? const Color(0xFFEF4444)
                          : _selectedCategoryId == null
                          ? Theme.of(context).textTheme.bodyMedium?.color
                          : null,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: hasError
                      ? const Color(0xFFEF4444)
                      : Theme.of(context).iconTheme.color,
                ),
              ],
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Padding(
            padding: EdgeInsets.only(left: widget.w * 0.04),
            child: Text(
              _categoryError!,
              style: TextStyle(
                color: const Color(0xFFEF4444),
                fontSize: widget.w * 0.032,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSubcategorySelector(AppLocalizations loc) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final hasError = _subcategoryError != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.t('subcategory'),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontSize: widget.w * 0.038,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _availableSubcategories.isEmpty && !categoryProvider.isLoading
              ? null
              : () => _showSubcategoryPicker(loc),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.w * 0.04,
              vertical: widget.h * 0.015,
            ),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasError
                    ? const Color(0xFFEF4444)
                    : _selectedSubcategoryId == null
                    ? Theme.of(context).dividerColor
                    : Theme.of(context).primaryColor,
                width: hasError || _selectedSubcategoryId != null ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedSubcategoryName ?? loc.t('select_subcategory'),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: widget.w * 0.038,
                      color: hasError
                          ? const Color(0xFFEF4444)
                          : _selectedSubcategoryId == null
                          ? Theme.of(context).textTheme.bodyMedium?.color
                          : null,
                    ),
                  ),
                ),
                if (categoryProvider.isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.arrow_drop_down,
                    color: hasError
                        ? const Color(0xFFEF4444)
                        : Theme.of(context).iconTheme.color,
                  ),
              ],
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Padding(
            padding: EdgeInsets.only(left: widget.w * 0.04),
            child: Text(
              _subcategoryError!,
              style: TextStyle(
                color: const Color(0xFFEF4444),
                fontSize: widget.w * 0.032,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLocationPicker(AppLocalizations loc) {
    final hasError = _locationError != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _pickLocation,
          child: Container(
            padding: EdgeInsets.all(widget.w * 0.04),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasError
                    ? const Color(0xFFEF4444)
                    : _selectedLat != null && _selectedLng != null
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).primaryColor.withOpacity(0.2),
                width: hasError || (_selectedLat != null && _selectedLng != null) ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: hasError
                        ? const Color(0xFFEF4444).withOpacity(0.1)
                        : Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.location_on_outlined,
                    color: hasError
                        ? const Color(0xFFEF4444)
                        : Theme.of(context).primaryColor,
                    size: widget.w * 0.06,
                  ),
                ),
                SizedBox(width: widget.w * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.t('select_location'),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: widget.w * 0.038,
                          fontWeight: FontWeight.w600,
                          color: hasError ? const Color(0xFFEF4444) : null,
                        ),
                      ),
                      SizedBox(height: widget.h * 0.005),
                      Text(
                        _selectedLat != null && _selectedLng != null
                            ? '${_selectedLat!.toStringAsFixed(4)}, ${_selectedLng!.toStringAsFixed(4)}'
                            : loc.t('tap_to_select'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: widget.w * 0.032,
                          color: hasError
                              ? const Color(0xFFEF4444)
                              : _selectedLat != null && _selectedLng != null
                              ? Theme.of(context).primaryColor
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: widget.w * 0.04,
                  color: hasError
                      ? const Color(0xFFEF4444)
                      : Theme.of(context).iconTheme.color,
                ),
              ],
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Padding(
            padding: EdgeInsets.only(left: widget.w * 0.04),
            child: Text(
              _locationError!,
              style: TextStyle(
                color: const Color(0xFFEF4444),
                fontSize: widget.w * 0.032,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStep2(AppLocalizations loc) {
    final totalFiles = _existingFiles.length + _newAttachmentPaths.length;
  final loc=AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.isEditMode ? loc.t('manage_attachments') : loc.t('add_attachments'),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontSize: widget.w * 0.045,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: widget.h * 0.01),
        Text(
          loc.t('attachments_subtitle'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: widget.w * 0.035,
          ),
        ),
        SizedBox(height: widget.h * 0.025),

        // Upload area
        InkWell(
          onTap: _isPickingFiles ? null : _pickFiles,
          child: Container(
            width: double.infinity,
            height: widget.h * 0.15,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _filesError!=null?Colors.red:Theme.of(context).dividerColor,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isPickingFiles)
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  )
                else ...[
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: widget.w * 0.12,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  SizedBox(height: widget.h * 0.01),
                  Text(
                    loc.t('upload_files'),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: widget.w * 0.038,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: widget.h * 0.003),
                  Text(
                    loc.t('tap_to_browse'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: widget.w * 0.03,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        SizedBox(height: widget.h * 0.03),
        if (_filesError != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: EdgeInsets.only(left: widget.w * 0.04),
            child: Text(
              _filesError!,
              style: TextStyle(
                color: const Color(0xFFEF4444),
                fontSize: widget.w * 0.032,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        SizedBox(height: widget.h * 0.03),

        // Files list
        if (totalFiles > 0) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.isEditMode ? loc.t('current_attachments') : loc.t('attachments_added'),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: widget.w * 0.038,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$totalFiles ${loc.t('files')}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: widget.w * 0.032,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: widget.h * 0.015),

          // Existing files (from server)
          if (_existingFiles.isNotEmpty) ...[
            Text(
              loc.t('uploaded_files'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: widget.w * 0.032,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
            SizedBox(height: widget.h * 0.01),
            ..._buildExistingFilesList(),
            SizedBox(height: widget.h * 0.02),
          ],

          // New files (not yet uploaded)
          if (_newAttachmentPaths.isNotEmpty) ...[
            Text(
              loc.t('new_files'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: widget.w * 0.032,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
            SizedBox(height: widget.h * 0.01),
            ..._buildNewFilesList(),
          ],
        ] else ...[
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.folder_outlined,
                  size: widget.w * 0.12,
                  color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                ),
                SizedBox(height: widget.h * 0.01),
                Text(
                  loc.t('no_attachments'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: widget.w * 0.035,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],

        SizedBox(height: widget.h * 0.02),
      ],
    );
  }

  List<Widget> _buildExistingFilesList() {
    return List.generate(
      _existingFiles.length,
          (i) => _buildExistingFileItem(_existingFiles[i], i),
    );
  }

  List<Widget> _buildNewFilesList() {
    return List.generate(
      _newAttachmentPaths.length,
          (i) => _buildNewFileItem(_newAttachmentNames[i], i),
    );
  }

  Widget _buildExistingFileItem(ServiceFile file, int index) {
    final fileName = file.url.split('/').last;
    final loc=AppLocalizations.of(context);


    return Container(
      margin: EdgeInsets.only(bottom: widget.h * 0.015),
      padding: EdgeInsets.symmetric(
        horizontal: widget.w * 0.04,
        vertical: widget.h * 0.015,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF3B82F6),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cloud_done,
              color: const Color(0xFF3B82F6),
              size: widget.w * 0.05,
            ),
          ),
          SizedBox(width: widget.w * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: widget.w * 0.036,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  loc.t('uploaded'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: widget.w * 0.03,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
              ],
            ),
          ),
          if (_isDeletingFile)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  const Color(0xFFEF4444),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
              onPressed: () => _deleteExistingFile(file.id),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildNewFileItem(String name, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: widget.h * 0.015),
      padding: EdgeInsets.symmetric(
        horizontal: widget.w * 0.04,
        vertical: widget.h * 0.015,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF22C55E),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              color: const Color(0xFF22C55E),
              size: widget.w * 0.05,
            ),
          ),
          SizedBox(width: widget.w * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: widget.w * 0.036,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _getFileSize(_newAttachmentPaths[index]),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: widget.w * 0.03,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFFEF4444)),
            onPressed: () => _removeNewAttachment(index),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSection(AppLocalizations loc) {
    return Container(
      padding: EdgeInsets.all(widget.w * 0.05),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
          SizedBox(height: widget.h * 0.02),
          Text(
            widget.isEditMode ? loc.t('updating_service') : loc.t('adding_service'),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: widget.w * 0.04,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: widget.h * 0.005),
          Text(
            loc.t('please_wait'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: widget.w * 0.032,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AppLocalizations loc, bool isDarkMode) {
    final showBackButton = _currentStep == 1;

    return Container(
      padding: EdgeInsets.all(widget.w * 0.05),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (showBackButton)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep = 0),
                style: OutlinedButton.styleFrom(
                  backgroundColor: isDarkMode
                      ? const Color(0xFF475569)
                      : const Color(0xFFE2E8F0),
                  padding: EdgeInsets.symmetric(vertical: widget.h * 0.018),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide.none,
                ),
                child: Text(
                  loc.t('back'),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontSize: widget.w * 0.04,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (showBackButton) SizedBox(width: widget.w * 0.03),
          Expanded(
            flex: _currentStep == 0 ? 2 : 1,
            child: ElevatedButton(
              onPressed: _currentStep == 0 ? _nextStep : _submitDebouncer.wrap(_submit),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: EdgeInsets.symmetric(vertical: widget.h * 0.018),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                _currentStep == 0 ? loc.t('next') : loc.t('save'),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: widget.w * 0.04,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(width: widget.w * 0.03),
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                backgroundColor: isDarkMode
                    ? const Color(0xFF475569)
                    : const Color(0xFFB6B6B6),
                padding: EdgeInsets.symmetric(vertical: widget.h * 0.018),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide.none,
              ),
              child: Text(
                loc.t('cancel'),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: widget.w * 0.04,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontSize: widget.w * 0.038,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontSize: widget.w * 0.038,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: widget.w * 0.035,
            ),
            filled: true,
            fillColor: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
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
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: widget.w * 0.04,
              vertical: maxLines > 1 ? widget.h * 0.015 : widget.h * 0.012,
            ),
            errorStyle: TextStyle(
              color: const Color(0xFFEF4444),
              fontSize: widget.w * 0.032,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // Actions


  void _showSubcategoryPicker(AppLocalizations loc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                loc.t('select_subcategory'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: _availableSubcategories.isEmpty
                  ? Center(
                child: Text(
                  loc.t('no_subcategories'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
                  : ListView.builder(
                itemCount: _availableSubcategories.length,
                itemBuilder: (context, index) {
                  final subcategory = _availableSubcategories[index];
                  return ListTile(
                    title: Text(subcategory.name),
                    trailing: _selectedSubcategoryId == subcategory.id
                        ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedSubcategoryId = subcategory.id;
                        _selectedSubcategoryName = subcategory.name;
                        _subcategoryError = null; // Clear error
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickLocation() async {
    final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
    final currentLocation = serviceProvider.userLocation;
    final loc = AppLocalizations.of(context);

    if (currentLocation != null) {
      setState(() {
        _selectedLat = currentLocation.latitude;
        _selectedLng = currentLocation.longitude;
        _locationError = null; // Clear error
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.t('location_selected')),
          backgroundColor: const Color(0xFF22C55E),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() {
        _selectedLat = _selectedLat ?? 33.315241;
        _selectedLng = _selectedLng ?? 44.366085;
        _locationError = null; // Clear error
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.t('using_default_location')),
          backgroundColor: Theme.of(context).primaryColor,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickFiles() async {
    setState(() => _isPickingFiles = true);
    setState(() {
      _filesError=null;
    });

    try {
      if(_newAttachmentPaths.isNotEmpty){
        setState(() {
          _filesError=null;
        });
      }

      final loc = AppLocalizations.of(context);

      // Check current total images (existing + new)
      final existingCount = widget.isEditMode ? (widget.editService?.files.length ?? 0) : 0;
      final currentTotal = existingCount + _newAttachmentPaths.length;
      const maxImages = 10;

      if (currentTotal >= maxImages) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.t('max_images_reached')),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp'], // Images only
      );

      if (result != null && result.files.isNotEmpty) {
        // Calculate how many images can be added
        final remainingSlots = maxImages - currentTotal;
        final filesToAdd = result.files.take(remainingSlots).toList();

        setState(() {
          for (var file in filesToAdd) {
            if (file.path != null) {
              _newAttachmentPaths.add(file.path!);
              _newAttachmentNames.add(file.name);
            }
          }
        });

        // Show message
        if (result.files.length > remainingSlots) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${loc.t('added_images_limit')}: $remainingSlots/${result.files.length}'),
              backgroundColor: const Color(0xFFF59E0B),
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${filesToAdd.length} ${loc.t('images_selected')}'),
              backgroundColor: const Color(0xFF22C55E),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error picking files: $e');
      }
      final loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.t('error_picking_files')),
          backgroundColor: const Color(0xFFEF4444),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingFiles = false);
      }
    }
  }

  Future<void> _deleteExistingFile(int fileId) async {
    final loc = AppLocalizations.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.token == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.t('delete_file')),
        content: Text(loc.t('delete_file_confirmation')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
            child: Text(loc.t('delete')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeletingFile = true);

    try {
      final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
      final result = await serviceProvider.deleteServiceFile(
        fileId: fileId,
      );

      if (mounted) {
        setState(() {
          _isDeletingFile = false;
          if (result['success'] == true) {
            _existingFiles.removeWhere((file) => file.id == fileId);
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['success'] == true
                  ? loc.t('file_deleted_successfully')
                  : result['message'] ?? loc.t('failed_to_delete_file'),
            ),
            backgroundColor:
            result['success'] == true ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeletingFile = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.t('error_deleting_file')),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _removeNewAttachment(int index) {
    setState(() {
      _newAttachmentPaths.removeAt(index);
      _newAttachmentNames.removeAt(index);
    });
  }

  String _getFileSize(String path) {
    try {
      final file = File(path);
      final bytes = file.lengthSync();
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } catch (e) {
      return 'Unknown size';
    }
  }

  void _nextStep() {
    final loc = AppLocalizations.of(context);

    // Clear previous errors
    setState(() {
      _categoryError = null;
      _subcategoryError = null;
      _locationError = null;
    });

    // Validate form fields
    bool hasFormErrors = !(_formKey.currentState?.validate() ?? false);

    // Validate dropdowns and location
    bool hasDropdownErrors = false;

    if (_selectedCategoryId == null) {
      setState(() => _categoryError = loc.t('please_select_category'));
      hasDropdownErrors = true;
    }

    if (_selectedSubcategoryId == null) {
      setState(() => _subcategoryError = loc.t('please_select_subcategory'));
      hasDropdownErrors = true;
    }

    if (_selectedLat == null || _selectedLng == null) {
      setState(() => _locationError = loc.t('please_select_location'));
      hasDropdownErrors = true;
    }

    // Don't proceed if there are any errors
    if (hasFormErrors || hasDropdownErrors) {
      return;
    }

    setState(() => _currentStep = 1);
  }

  Future<void> _submit() async {
    final loc = AppLocalizations.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);

    if (authProvider.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.t('authentication_required')),
          backgroundColor: const Color(0xFFEF4444),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_existingFiles.isEmpty && _newAttachmentPaths.isEmpty) {
      setState(() => _filesError = loc.t('please_upload_at_least_one_file'));
      return;
    }

    // Prepare work days string
    final workDaysString = _selectedWorkDays.join(',');

    // Call appropriate API method
    final result = widget.isEditMode
        ? await serviceProvider.updateService(
      serviceId: widget.editService!.id,
      catId: _selectedCategoryId!,
      subcatId: _selectedSubcategoryId!,
      name: _serviceNameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      description: _descriptionController.text.trim(),
      lat: _selectedLat!,
      lng: _selectedLng!,
      facebook: _facebookController.text.trim().isEmpty ? null : _facebookController.text.trim(),
      instagram: _instagramController.text.trim().isEmpty ? null : _instagramController.text.trim(),
      whatsapp: _whatsappController.text.trim().isEmpty ? null : _whatsappController.text.trim(),
      telegram: _telegramController.text.trim().isEmpty ? null : _telegramController.text.trim(),
      attachmentPaths: _newAttachmentPaths.isNotEmpty ? _newAttachmentPaths : null,
      // Working hours fields
      openTime: _isOpen24Hours ? null : _openTime,
      closeTime: _isOpen24Hours ? null : _closeTime,
      workDays: _isOpen24Hours ? null : workDaysString,
      isOpen24Hours: _isOpen24Hours,
      isManualOverride: _isManualOverride,
    )
        : await serviceProvider.addService(
      catId: _selectedCategoryId!,
      subcatId: _selectedSubcategoryId!,
      name: _serviceNameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      description: _descriptionController.text.trim(),
      lat: _selectedLat!,
      lng: _selectedLng!,
      facebook: _facebookController.text.trim().isEmpty ? null : _facebookController.text.trim(),
      instagram: _instagramController.text.trim().isEmpty ? null : _instagramController.text.trim(),
      whatsapp: _whatsappController.text.trim().isEmpty ? null : _whatsappController.text.trim(),
      telegram: _telegramController.text.trim().isEmpty ? null : _telegramController.text.trim(),
      attachmentPaths: _newAttachmentPaths.isNotEmpty ? _newAttachmentPaths : null,
      // Working hours fields
      openTime: _isOpen24Hours ? null : _openTime,
      closeTime: _isOpen24Hours ? null : _closeTime,
      workDays: _isOpen24Hours ? null : workDaysString,
      isOpen24Hours: _isOpen24Hours,
      isManualOverride: _isManualOverride,
    );

    if (!mounted) return;

    // ✅ Pop with result BEFORE showing snackbar
    Navigator.pop(context, result);

    // Show success/error message (always use localized strings)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.isEditMode
              ? (result['success'] == true
                  ? loc.t('service_updated_successfully')
                  : loc.t('failed_to_update_service'))
              : (result['success'] == true
                  ? loc.t('service_added_successfully')
                  : loc.t('failed_to_add_service')),
        ),
        backgroundColor:
        result['success'] == true ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        action: result['success'] != true
            ? SnackBarAction(
          label: loc.t('dismiss'),
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        )
            : null,
      ),
    );
  }

  // ============================================
// CRITICAL FIX 1: Add import at the top
// ============================================


// ============================================
// CRITICAL FIX 2: Update _preselectCategoryAndSubcategory()
// Find this method around line 210-245
// ============================================
  void _preselectCategoryAndSubcategory() {
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    final subCat = Provider.of<SubcategoryProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (_selectedCategoryId == null) return;

    try {
      final category = categoryProvider.categories.firstWhere(
            (cat) => cat.id == _selectedCategoryId,
      );
      _selectedCategoryName = category.name;

      if (authProvider.token != null) {
        subCat.fetchSubcategories(authProvider.token!).then((_) {
          safeSetState(() {
            // ✅ THIS IS THE CRITICAL CHANGE - Filter by category ID
            _availableSubcategories = subCat.subcategories
                .where((sub) => sub.catId == _selectedCategoryId)
                .toList();

            if (_selectedSubcategoryId != null && _availableSubcategories.isNotEmpty) {
              try {
                final subcategory = _availableSubcategories.firstWhere(
                      (subcat) => subcat.id == _selectedSubcategoryId,
                );
                _selectedSubcategoryName = subcategory.name;
              } catch (e) {
                if (kDebugMode) {
                  print('Subcategory not found: $e');
                }
              }
            }
          });
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error preselecting category: $e');
      }
    }
  }


// ============================================
// CRITICAL FIX 3: Update _showCategoryPicker()
// Find the onTap callback around line 1030-1080
// ============================================
  void _showCategoryPicker(AppLocalizations loc) {
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                loc.t('select_category'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: categoryProvider.categories.length,
                itemBuilder: (context, index) {
                  final category = categoryProvider.categories[index];
                  return ListTile(
                    title: Text(category.name),
                    trailing: _selectedCategoryId == category.id
                        ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                        : null,
                    onTap: () async {
                      setState(() {
                        _selectedCategoryId = category.id;
                        _selectedCategoryName = category.name;
                        _selectedSubcategoryId = null;
                        _selectedSubcategoryName = null;
                        _availableSubcategories = [];
                        _categoryError = null;
                      });

                      Navigator.pop(context);

                      // ✅ THIS IS THE CRITICAL CHANGE - Filter subcategories
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      final subCat = Provider.of<SubcategoryProvider>(context, listen: false);

                      if (authProvider.token != null) {
                        await subCat.fetchSubcategories(authProvider.token!);
                        safeSetState(() {
                          // ✅ Filter by category ID
                          _availableSubcategories = subCat.subcategories
                              .where((sub) => sub.catId == _selectedCategoryId)
                              .toList();
                        });
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}