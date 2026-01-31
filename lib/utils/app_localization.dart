import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  // Helper method to get the right translation
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  // Static map of translations
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // App Name
      'app_name': 'Daleel Dhi Qar',

      // Bottom Navigation
      'nav_profile': 'Profile',
      'nav_favorites': 'Favorites',
      'nav_home': 'Home',
      'nav_settings': 'Settings',

      // Home Screen
      'home_greeting': 'All Categories',
      'search_hint': 'Search for service - need',
      'categories_title': 'Categories',
      'view_all': 'View All',
      'nearby_services': 'Nearby Services',
      'nearby_services_subtitle': 'Services close to you',
      'additional_services': 'Additional Services',
      'hotels': 'Hotels',
      'restaurants': 'Restaurants',
      'airports': 'Airports',
      'pharmacies': 'Pharmacies',

      // Banner
      'banner_text': 'We hope this guide\nprovides ease, travel to places\nof comfort, or any situation',
      'banner_badge': 'Personal Awesome',

      // Services
      'car_services': 'Car Services',
      'car_services_desc': 'Car Center for Vehicle Maintenance',
      'carpentry_services': 'Carpentry Services',
      'carpentry_desc': 'Furniture carpentry for all home decoration works',
      'electrical_services': 'Home Electrical Services',
      'electrical_desc': 'For home electrical works and appliances maintenance',
      'distance_away': 'km away',

      // Profile Screen
      'profile_title': 'Profile',
      'favorites': 'Favorites',
      'orders': 'Orders',
      'rating': 'Rating',
      'my_account': 'My Account',
      'edit_profile': 'Edit Profile',
      'change_password': 'Change Password',
      'privacy_security': 'Privacy & Security',
      'logout': 'Logout',
      'logout_confirm': 'Are you sure you want to logout?',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'made_with_love': 'Made with ❤️ in Dhi Qar',

      // Visitor Screen
      'welcome': 'Welcome!',
      'login_message': 'Login to access your profile\nand all available features',
      'save_favorites': 'Save your favorite places',
      'track_orders': 'Track your order history',
      'get_notifications': 'Get personalized notifications',
      'rate_share': 'Rate and share your experience',
      'login': 'Login',
      'create_account': 'Create Account',
      'login_required': 'Login Required',
      'login_required_for_feature': 'Please login to {feature}',
      'add_favorites': 'add to favorites',
      'call_service': 'call the service owner',
      'view_contact': 'view contact information',
      'write_review': 'write a review',
      'add_service': 'add a service',
      'view_location': 'view location on map',

      // Settings Screen
      'settings': 'Settings',
      'notifications': 'Notifications',
      'language': 'Language',
      'arabic': 'Arabic',
      'english': 'English',
      'dark_mode': 'Dark Mode',
      'help_support': 'Help & Support',
      'contact_us': 'Contact Us',
      'terms_conditions': 'Terms & Conditions',
      'privacy_policy': 'Privacy Policy',
      'about_app': 'About App',
      'version': 'Version',
      'contact_us_desc': 'We\'re here to help! Choose your preferred contact method.',
      'email': 'Email',
      'phone': 'Phone',
      'app_description': 'Your comprehensive guide to discover the best services and places in Dhi Qar. Find restaurants, hotels, shops, and more.',
      'developed_by': 'Developed by',
      'all_rights_reserved': 'All rights reserved',
      'close': 'Close',
      'last_updated': 'Last updated',
      'terms_conditions_content': '''Terms of Use

1. Acceptance of Terms
By using Daleel Dhi Qar application, you agree to these terms and conditions.

2. Use of Service
- You must be at least 13 years old to use this app
- You are responsible for maintaining the confidentiality of your account
- You agree not to use the service for any illegal purposes

3. User Content
- You retain ownership of content you submit
- You grant us license to use, display, and distribute your content
- You are responsible for the accuracy of information you provide

4. Service Providers
- We do not guarantee the quality of services listed
- Verify information directly with service providers
- We are not responsible for transactions between users and providers

5. Modifications
We reserve the right to modify these terms at any time. Continued use constitutes acceptance of modified terms.

6. Limitation of Liability
The app is provided "as is" without warranties. We are not liable for any damages arising from use of the service.

7. Contact
For questions about these terms, contact us through the app.''',
      'privacy_policy_content': '''Privacy Policy

1. Information We Collect
- Account information (name, phone number, email)
- Location data (with your permission)
- Usage data and preferences
- Device information

2. How We Use Your Information
- To provide and improve our services
- To personalize your experience
- To send notifications (with your consent)
- To ensure security and prevent fraud

3. Information Sharing
- We do not sell your personal information
- We may share data with service providers who assist us
- We may disclose information when required by law

4. Data Security
- We use industry-standard security measures
- We encrypt sensitive data in transit and at rest
- We regularly review our security practices

5. Your Rights
- Access your personal data
- Request correction of inaccurate data
- Request deletion of your data
- Opt-out of marketing communications

6. Location Data
- We collect location only when you use location features
- You can disable location access in device settings

7. Updates to Policy
We may update this policy periodically. We will notify you of significant changes.

8. Contact Us
For privacy concerns, contact us through the app settings.''',

      // Add Service Sheet
      'add_service_title': 'Add Service or Workplace',
      'add_service_subtitle': 'Add new service information and make sure to save the data',
      'service_name': 'Service Name',
      'service_name_hint': 'Enter service name',
      'phone_number': 'Phone Number',
      'phone_hint': 'Enter phone number',
      'address': 'Address',
      'address_hint': 'Enter shop or service address',
      'description': 'Service Description',
      'description_hint': 'Write service description here',
      'select_location': 'Select Location on Map',
      'tap_to_select': 'Tap to select location',
      'add_attachments': 'Add Attachments',
      'attachments_subtitle': 'Add images for the service (max 10 images)',
      'upload_files': 'Click here to upload attachments',
      'attachments_added': 'Added Attachments',
      'next': 'Next',
      'save': 'Save',
      'required_field': 'This field is required',
      'files_selected': 'Files selected successfully',
      'images_selected': 'images selected',
      'max_images_reached': 'Maximum 10 images allowed',
      'added_images_limit': 'Added images (limit reached)',
      'service_saved': 'Service saved successfully',
      'show_on_map': "Show On Map",
      "edit_service_title": "Edit Service",
      "edit_service_subtitle": "Update your service information",

      "category": "Category",
      "subcategory": "Subcategory",
      "select_category": "Select Category",
      "select_subcategory": "Select Subcategory",
      "please_select_category": "Please select a category",
      "please_select_subcategory": "Please select a subcategory",
      "no_subcategories": "No subcategories available",

      "invalid_phone": "Phone number must be at least 10 digits",

      "please_select_location": "Please select a location",
      "location_selected": "Location selected successfully",
      "using_default_location": "Using default location",

      "manage_attachments": "Manage Attachments",
      "tap_to_browse": "Tap to browse files",
      "current_attachments": "Current Attachments",
      "uploaded_files": "Uploaded Files",
      "new_files": "New Files to Upload",
      "uploaded": "Uploaded",
      "no_attachments": "No attachments yet",
      "files": "files",
      "error_picking_files": "Error selecting files",

      "delete_file": "Delete File",
      "delete": "Delete",
      "delete_file_confirmation": "Are you sure you want to delete this file? This action cannot be undone.",
      "file_deleted_successfully": "File deleted successfully",
      "failed_to_delete_file": "Failed to delete file",
      "error_deleting_file": "An error occurred while deleting the file",

      "back": "Back",
      "dismiss": "Dismiss",

      "adding_service": "Adding Service...",
      "updating_service": "Updating Service...",
      "please_wait": "Please wait",

      "service_added_successfully": "Service added successfully",
      "service_updated_successfully": "Service updated successfully",
      "failed_to_add_service": "Failed to add service",
      "failed_to_update_service": "Failed to update service",

      "authentication_required": "Authentication required. Please login.",
      "authentication_failed": "Authentication failed",
      "please_login_again": "Please login again to continue",
      'search': 'Search',
      'search_radius': 'Search Radius',
      'km': 'km',
      'all': 'All',
      'reset_filters': 'Reset Filters',
      'no_results_found': 'No Results Found',
      'try_different_search': 'Try different search terms',
      'retry': 'Retry',
      'social_media': 'Social Media',
      'social_media_optional': 'Optional - Add your account links',

      // Working Hours
      'working_hours': 'Working Hours',
      'working_hours_desc': 'Set when your service is available',
      'open_time': 'Open Time',
      'close_time': 'Close Time',
      'work_days': 'Work Days',
      'open_24_hours': 'Open 24 Hours',
      'open_24_hours_desc': 'Service is always available',
      'manual_override': 'Manual Override',
      'manual_override_desc': 'Temporarily mark as open/closed',
      'open_now': 'Open',
      'closed': 'Closed',
      'sun': 'Sun',
      'mon': 'Mon',
      'tue': 'Tue',
      'wed': 'Wed',
      'thu': 'Thu',
      'fri': 'Fri',
      'sat': 'Sat',
      'days_selected': 'days',
      'tap_to_select_deselect': 'Tap to select or deselect days',

      // Location & Nearby Services
      'location_permission_required': 'Location Permission Required',
      'location_permission_settings_message': 'Location permission is required to show nearby services. Please enable it in app settings.',
      'grant_location_access_message': 'Grant location access to see services near you',
      'grant_permission': 'Grant Permission',
      'location_access_disabled': 'Location Access Disabled',
      'enable_location_settings_message': 'Enable location in settings to see nearby services',
      'location_service_disabled': 'Location Service Disabled',
      'enable_location_service_message': 'Enable location services to see nearby services',
      'enable_service': 'Enable Service',
      'using_approximate_location': 'Using Approximate Location',
      'services_default_location_message': 'Services shown based on default location',
      'try_again': 'Try Again',
      'could_not_load_services': 'Could Not Load Services',
      'showing_approximate_location': 'Showing services based on approximate location',
      'no_services_nearby': 'No Services Nearby',
      'no_services_within_distance': 'There are no services within 10km of your location',
      'open_settings': 'Open Settings',
      'no_services_from_api': 'No services available from server',
      'loading_services': 'Loading services...',
      'no_services_found': 'No services found',
      'try_another_filter': 'Try another category or subcategory',
      'services': 'Services',
      'network_error': 'Network Error',
      'network_error_desc': 'Please check your internet connection and try again',
      'server_error': 'Server Error',
      'server_error_desc': 'Server is temporarily unavailable. Please try again later',
      'not_found': 'Not Found',
      'not_found_desc': 'The requested resource could not be found',
      'something_went_wrong': 'Something Went Wrong',
      'no_services_available': 'No Services Available',
      'check_back_later': 'Check back later for new services',
      'timeout_error': 'Request Timeout',
      'timeout_error_desc': 'The request took too long. Please try again',
      'session_expired_desc': 'Your session has expired. Please login again to continue',
      'services_not_found_desc': 'The requested services could not be found',
      'unexpected_error_desc': 'An unexpected error occurred. Please try again',
      'go_back': 'Go Back',
      'show_all': 'Show All',
      'edit':'Edit',
      'no_services_yet':'No Services Yet',
      'my_services':'My Services',
      'add_service':'Add Service',
      "delete_service": "Delete Service",
      "are_you_sure_delete_service": "Are you sure you want to delete this service? This action cannot be undone.",
      "service_deleted_successfully": "Service deleted successfully",
      'details':'Details',
      'please_upload_at_least_one_file':'Please Upload At Lease One File',

      // Service Details Screen - NEW KEYS
      'edit_service': 'Edit Service',
      'contact_info': 'Contact Information',
      'connect_with_us': 'Connect With Us',
      'location': 'Location',
      'open_map': 'Open Map',
      'directions': 'Get Directions',
      'no_image': 'No Image',
      'no_image_available': 'No image available',
      'cannot_open_link': 'Cannot open link',
      'error_opening_link': 'An error occurred while opening the link',
      'cannot_open_whatsapp': 'Cannot open WhatsApp',
      'error_opening_whatsapp': 'An error occurred while opening WhatsApp',
      'cannot_make_call': 'Cannot make call',
      'error_making_call': 'An error occurred while making the call',
      'location_not_available': 'Location not available',
      'deleting_service': 'Deleting Service...',
      'failed_to_delete_service': 'Failed to delete service',
      'error_deleting_service': 'An error occurred while deleting the service',
      'service_owner': 'Service Owner',
      'image_counter': 'Image {current} of {total}',
      'posted_by': 'Posted by',
      'unknown_user': 'Unknown User',
      'verified': 'Verified',
      'unverified': 'Unverified',

      // Common
      'guest': 'Guest',
      'after': 'After',
      'exit_app': 'Exit App',
      'exit_app_confirm': 'Are you sure you want to exit the app?',
      'exit': 'Exit',
      'forgot_password': 'Forgot Password',
      'name': 'Name',
      'confirm_password': 'Confirm Password',
      'confirm_password_des': 'Re-enter Password',
      'already_have_account': 'Already Have Account ?',
      'range':'Range',
      'service':'Service',
      'discover_offer':'Discover the Offer',
      'read_more':' Show More',
      'read_less':' Show Less',
      "open_in_maps": "Open in Maps",

      // Complete Profile Screen
      'complete_profile': 'Complete Your Profile',
      'complete_profile_subtitle': 'Help us personalize your experience',
      'step_of': 'Step {current} of {total}',
      'what_is_your_gender': 'What is your gender?',
      'male': 'Male',
      'female': 'Female',
      'when_were_you_born': 'When were you born?',
      'select_birth_date': 'Select your birth date',
      'where_do_you_live': 'Where do you live?',
      'select_city': 'Select your city',
      'what_is_your_occupation': 'What is your occupation?',
      'select_occupation': 'Select your occupation',
      'what_are_your_interests': 'What are your interests?',
      'select_interests': 'Select your interests',
      'previous': 'Previous',
      'finish': 'Finish',
      'profile_completed': 'Profile Completed!',
      'thank_you_profile': 'Thank you for completing your profile',
      'error_saving_profile': 'Error saving profile data',
      'interests_selected': '{count} interests selected',
      'years_old': 'years old',

      // Occupations
      'occupation_student': 'Student',
      'occupation_employee': 'Employee',
      'occupation_freelancer': 'Freelancer',
      'occupation_business_owner': 'Business Owner',
      'occupation_doctor': 'Doctor',
      'occupation_engineer': 'Engineer',
      'occupation_teacher': 'Teacher',
      'occupation_retired': 'Retired',
      'occupation_housewife': 'Housewife',
      'occupation_unemployed': 'Unemployed',
      'occupation_other': 'Other',

      // Interests
      'interest_restaurants': 'Restaurants & Cafes',
      'interest_hotels': 'Hotels & Accommodation',
      'interest_shopping': 'Shopping & Malls',
      'interest_healthcare': 'Healthcare & Medical',
      'interest_education': 'Education & Training',
      'interest_car_services': 'Car Services',
      'interest_home_services': 'Home Services',
      'interest_tourism': 'Tourism & Travel',
      'interest_sports': 'Sports & Fitness',
      'interest_entertainment': 'Entertainment',

      // Ad Actions
      'view_service': 'View Service',
      'discover_more': 'Discover More',
      'try_now': 'Try Now',
      'sponsored': 'Sponsored',
      'featured_service': 'Featured Service',
      'cannot_open_url': 'Cannot open URL',
      'service_not_found': 'Service not found',

      // Onboarding Screen
      'onboarding_title_1': 'Daleel Dhi Qar',
      'onboarding_desc_1': 'Your comprehensive app for finding all the services you need in your area easily and quickly.',
      'onboarding_title_2': 'Discover Services',
      'onboarding_desc_2': 'Browse available services around you — from maintenance to beauty — with accurate details and locations.',
      'onboarding_title_3': 'Book and Track Easily',
      'onboarding_desc_3': 'Book your service with one tap, and track the order status until completion with full transparency and comfort.',
      'skip': 'Skip',
      'get_started': 'Get Started',

      // Validation Messages
      'invalid_phone_number': 'Invalid phone number',
      'password_too_short': 'Password is too short',
      'password_min_6': 'Password must be at least 6 characters',
      'name_min_3': 'Name must be at least 3 characters',
      'passwords_not_match': 'Passwords do not match',
      'login_failed': 'Login failed',
      'registration_failed': 'Registration failed',
      'password': 'Password',
      'enter_password': 'Enter password',

      // Debug Section
      'debug_local_db': 'Debug (Local DB)',
      'delete_test_users': 'Delete Test Users',
      'delete_test_users_desc': 'Remove all registered test users',
      'reset_database': 'Reset Database',
      'reset_database_desc': 'Reset all local data',
      'reset_database_title': 'Reset Database?',
      'reset_database_confirm': 'This will delete all local data and reset to default mock data. This cannot be undone.',
      'reset': 'Reset',
      'deleted_users': 'Deleted {count} test user(s)',
      'database_reset_success': 'Database reset successfully',

      // Favorites Screen
      'no_favorites': 'No Favorites Yet',
      'no_favorites_desc': 'Add services to your favorites to see them here',
      'browse_services': 'Browse Services',
      'remove_from_favorites': 'Remove from Favorites',
      'added_to_favorites': 'Added to Favorites',
      'removed_from_favorites': 'Removed from Favorites',

      // Additional keys for localization
      'press_again_to_exit': 'Press again to exit the app',
      'filters': 'Filters',
      'search_range': 'Search Range',
      'enabled': 'Enabled',
      'disabled': 'Disabled',
      'start_typing': 'Start typing to search',
      'loading_text': 'Loading...',
      'start_search': 'Start Search',
      'type_to_search': 'Type what you are looking for above\nto get instant results',
      'try_different_keywords': 'Try different search keywords\nor change filters',
      'error_occurred': 'Sorry, an error occurred!',
      'found_services': 'Found {count} service',
      'failed_to_load_services': 'Failed to load services',
      'failed_to_load_favorites': 'Failed to load favorites',
      'refresh': 'Refresh',
      'error_occurred_title': 'An error occurred',
      'not_logged_in': 'Not logged in',
      'please_login_to_view_favorites': 'Please login to view favorites',
      'no_favorites_yet': 'No favorites yet',
      'start_adding_favorites': 'Start adding your favorite services\nto browse them easily later',

      // Cities
      'city_baghdad': 'Baghdad',
      'city_basra': 'Basra',
      'city_mosul': 'Mosul',
      'city_erbil': 'Erbil',
      'city_najaf': 'Najaf',
      'city_karbala': 'Karbala',
      'city_nasiriyah': 'Nasiriyah',
      'city_sulaymaniyah': 'Sulaymaniyah',
      'city_kirkuk': 'Kirkuk',
      'city_hilla': 'Hilla',
      'city_diwaniyah': 'Diwaniyah',
      'city_kut': 'Kut',
      'city_samawah': 'Samawah',
      'city_amarah': 'Amarah',
      'city_ramadi': 'Ramadi',
      'city_baqubah': 'Baqubah',
      'city_tikrit': 'Tikrit',
      'city_duhok': 'Duhok',

      // Interests for profile completion
      'interest_restaurants': 'Restaurants & Cafes',
      'interest_hotels': 'Hotels & Accommodation',
      'interest_tourism': 'Tourism & Antiquities',
      'interest_shopping': 'Shopping',
      'interest_healthcare': 'Health & Medicine',
      'interest_education': 'Education',
      'interest_sports': 'Sports',
      'interest_entertainment': 'Entertainment',
      'interest_automotive': 'Automotive',
      'interest_real_estate': 'Real Estate',

      // Occupations
      'occupation_student': 'Student',
      'occupation_government': 'Government Employee',
      'occupation_private': 'Private Sector Employee',
      'occupation_freelance': 'Freelance',
      'occupation_doctor': 'Doctor',
      'occupation_engineer': 'Engineer',
      'occupation_teacher': 'Teacher',
      'occupation_merchant': 'Merchant',
      'occupation_retired': 'Retired',
      'occupation_housewife': 'Housewife',
      'occupation_other': 'Other',

      // No results
      'no_results_found': 'No results found',

      // Favorites
      'please_login_first': 'Please login first',
      'operation_failed': 'Operation failed. Try again',
      'add_to_favorites': 'Add to favorites',
      'favorite': 'Favorite',

      // Nearby services
      'searching_nearby_services': 'Searching for nearby services...',
      'searching_in_range': 'Searching in range',
      'no_services_in_range': 'No services found in range',
      'service': 'service',

      // Service card
      'call_to': 'Call',
      'call_now': 'Call Now',

      // Location permissions
      'location_permission_required': 'Location Permission Required',
      'location_permission_settings_message': 'Please enable location permission from settings to find services near you',
      'grant_location_access_message': 'Grant location access to find services near you',
      'grant_permission': 'Grant Permission',
      'location_access_disabled': 'Location Access Disabled',
      'enable_location_settings_message': 'Please enable location from settings',
      'open_settings': 'Open Settings',
      'location_service_disabled': 'Location Service Disabled',
      'enable_location_service_message': 'Please enable location service',
      'enable_service': 'Enable Service',
      'please_login_again': 'Please login again',
      'could_not_load_services': 'Could not load services',

      // Additional services section
      'no_services_available': 'No services available',
      'check_back_later': 'Check back later',
      'not_found_desc': 'The requested item could not be found',

      // Search hint
      'search_hint': 'Search for hospital, restaurant, hotel...',

      // Age groups
      'age_under_18': 'Under 18',
      'age_18_24': '18-24',
      'age_25_34': '25-34',
      'age_35_44': '35-44',
      'age_45_54': '45-54',
      'age_55_plus': '55+',
      'age_not_specified': 'Not specified',

      // Status badges
      'available': 'Available',
      'unavailable': 'Unavailable',
      'sponsored': 'Sponsored',
      'featured': 'Featured',

      // Search section
      'discover_services': 'Discover the best services and places',

      // Nearby services
      'no_nearby_services': 'No nearby services',

      // Reviews & Ratings
      'reviews': 'Reviews',
      'write_review': 'Write a Review',
      'edit_review': 'Edit Review',
      'edit_your_review': 'Edit Your Review',
      'your_review': 'Your Review',
      'no_reviews_yet': 'No Reviews Yet',
      'be_first_to_review': 'Be the first to share your experience!',
      'how_would_you_rate': 'How would you rate this service?',
      'write_your_review': 'Share your experience with others...',
      'submit_review': 'Submit Review',
      'update_review': 'Update Review',
      'delete_review': 'Delete Review',
      'delete_review_confirm': 'Are you sure you want to delete this review?',
      'review_submitted': 'Review submitted successfully',
      'review_updated': 'Review updated successfully',
      'review_deleted': 'Review deleted successfully',
      'review_submit_failed': 'Failed to submit review',
      'please_select_rating': 'Please select a rating',
      'comment_too_short': 'Comment must be at least 10 characters',
      'comment_too_long': 'Comment cannot exceed 1000 characters',
      'min_characters': 'Minimum characters',
      'rate_limit_exceeded': 'Please wait before submitting another review',
      'rate_limit_wait': 'Please wait {seconds} seconds before submitting',
      'login_required_for_review': 'Please login to write a review',
      'already_reviewed': 'You have already reviewed this service',
      'review_not_found': 'Review not found',
      'review_not_editable': 'Review can only be edited within 7 days',
      'invalid_rating': 'Please select a valid rating',
      'helpful': 'Helpful',
      'report': 'Report',
      'report_review': 'Report Review',
      'report_review_confirm': 'Are you sure you want to report this review?',
      'review_reported': 'Review reported. Thank you!',
      'show_more': 'Show more',
      'show_less': 'Show less',
      'edited': 'Edited',
      'based_on_reviews': 'Based on {count} reviews',

      // Rating labels
      'rating_excellent': 'Excellent',
      'rating_very_good': 'Very Good',
      'rating_good': 'Good',
      'rating_fair': 'Fair',
      'rating_poor': 'Poor',

      // Time ago
      'just_now': 'Just now',
      'minute_ago': '1 minute ago',
      'minutes_ago': '{n} minutes ago',
      'hour_ago': '1 hour ago',
      'hours_ago': '{n} hours ago',
      'day_ago': '1 day ago',
      'days_ago': '{n} days ago',
      'week_ago': '1 week ago',
      'weeks_ago': '{n} weeks ago',
      'month_ago': '1 month ago',
      'months_ago': '{n} months ago',
      'year_ago': '1 year ago',
      'years_ago': '{n} years ago',

      // Service Details - Owner Actions
      'manage_service': 'Manage Service',
      'mark_closed': 'Mark as Closed',
      'mark_open': 'Mark as Open',
      'service_marked_open': 'Service marked as open',
      'service_marked_closed': 'Service marked as closed',
      'tap_to_call': 'Tap to call',
      'tap_for_directions': 'Tap for directions',
      'tap_to_chat': 'Tap to chat on WhatsApp',
      'quick_actions': 'Quick Actions',
      'about': 'About',
      'view_on_map': 'View on Map',
      'call': 'Call',

      // Featured Services Sections
      'top_rated': 'Top Rated',
      'top_rated_subtitle': 'Highest rated by users',
      'no_top_rated': 'No Top Rated Services',
      'no_top_rated_subtitle': 'Check back later for highly rated services',

      'recently_added': 'Recently Added',
      'recently_added_subtitle': 'New services this month',
      'no_recently_added': 'No New Services',
      'no_recently_added_subtitle': 'No services added recently',

      'open_now_services': 'Open Now',
      'open_now_subtitle': 'Services available right now',
      'no_open_now': 'No Services Open',
      'no_open_now_subtitle': 'Check back during business hours',

      'verified_services': 'Verified Services',
      'verified_services_subtitle': 'Trusted by our team',
      'no_verified_services': 'No Verified Services',
      'no_verified_services_subtitle': 'Check back later for verified services',
      'verified_owner': 'Verified Owner',

      // Notifications
      'no_notifications': 'No Notifications',
      'no_notifications_subtitle': 'You\'re all caught up! New notifications will appear here.',
      'mark_all_read': 'Mark All as Read',
      'delete_all': 'Delete All',
      'delete_all_notifications': 'Delete All Notifications',
      'delete_all_notifications_confirm': 'Are you sure you want to delete all notifications? This cannot be undone.',
      'today': 'Today',
      'yesterday': 'Yesterday',
      'this_week': 'This Week',
      'older': 'Older',
      'notification_review': 'New Review',
      'notification_favorite': 'Added to Favorites',
      'notification_message': 'New Message',
      'notification_service_update': 'Service Update',
      'notification_promotion': 'Special Offer',
      'notification_system': 'System Notification',

      // Edit Profile Screen
      'full_name': 'Full Name',
      'enter_name': 'Enter your name',
      'name_min_3': 'Name must be at least 3 characters',
      'gender': 'Gender',
      'male': 'Male',
      'female': 'Female',
      'birth_date': 'Birth Date',
      'select_birth_date': 'Select birth date',
      'city': 'City',
      'select_city': 'Select city',
      'occupation': 'Occupation',
      'select_occupation': 'Select occupation',
      'interests': 'Interests',
      'save': 'Save',
      'save_changes': 'Save Changes',
      'profile_updated': 'Profile updated successfully',
      'profile_info': 'Profile Info',
      'years': 'years',
      'complete_profile_hint': 'Complete your profile to help us personalize your experience',
      'camera': 'Camera',
      'gallery': 'Gallery',

      // Change Password Screen
      'current_password': 'Current Password',
      'enter_current_password': 'Enter current password',
      'new_password': 'New Password',
      'enter_new_password': 'Enter new password',
      'confirm_password': 'Confirm Password',
      'confirm_new_password': 'Confirm new password',
      'password_min_6': 'Password must be at least 6 characters',
      'password_must_be_different': 'New password must be different from current',
      'passwords_not_match': 'Passwords do not match',
      'password_changed': 'Password changed successfully',
      'password_change_failed': 'Failed to change password',
      'password_requirements': 'Use a strong password with at least 6 characters including numbers and symbols',
      'weak': 'Weak',
      'medium': 'Medium',
      'strong': 'Strong',

      // Notification Settings Screen
      'notification_settings': 'Notification Settings',
      'manage_notifications': 'Manage your notification preferences',
      'push_notifications': 'Push Notifications',
      'notifications_enabled': 'Notifications are enabled',
      'notifications_disabled': 'Notifications are disabled',
      'notifications_turned_on': 'Notifications turned on',
      'notifications_turned_off': 'Notifications turned off',
      'notification_toggle_failed': 'Failed to update notifications',
      'enable_all_notifications': 'Enable or disable all notifications',
      'notification_types': 'Notification Types',
      'review_notifications': 'Review Notifications',
      'review_notifications_desc': 'Get notified when someone reviews your service',
      'favorite_notifications': 'Favorite Notifications',
      'favorite_notifications_desc': 'Get notified when someone favorites your service',
      'service_update_notifications': 'Service Updates',
      'service_update_notifications_desc': 'Get notified about service updates',
      'promotion_notifications': 'Promotions',
      'promotion_notifications_desc': 'Get notified about special offers',
      'ads_notifications': 'Special Offers',
      'ads_notifications_desc': 'Get notified about new advertisements',
      'system_notifications': 'System Notifications',
      'system_notifications_desc': 'Important system announcements',
      'verification_notifications': 'Verification Notifications',
      'verification_notifications_desc': 'Get notified when your account verification status changes',
      'notification_settings_info': 'Changes are saved automatically. You can enable or disable individual notification types.',
      'push_enabled_success': 'Push notifications enabled successfully',
      'push_disabled_success': 'Push notifications disabled successfully',
      'push_toggle_failed': 'Failed to update push notification settings',
    },
    'ar': {
      // App Name
      'app_name': 'دليل ذي قار',
      'no_services_yet':'لم تقم باضافة اي خدمة',
      'discover_offer':'اكتشف العرض',
      'read_more':'عرض المزيد',
      'read_less':'عرض اقل',
      // Bottom Navigation
      'nav_profile': 'الحساب',
      'nav_favorites': 'المفضلة',
      'nav_home': 'الرئيسية',
      'nav_settings': 'الإعدادات',
      'social_media': 'وسائل التواصل الاجتماعي',
      'social_media_optional': 'اختياري - أضف روابط حساباتك',

      // Working Hours
      'working_hours': 'ساعات العمل',
      'working_hours_desc': 'حدد أوقات توفر خدمتك',
      'open_time': 'وقت الفتح',
      'close_time': 'وقت الإغلاق',
      'work_days': 'أيام العمل',
      'open_24_hours': 'مفتوح 24 ساعة',
      'open_24_hours_desc': 'الخدمة متاحة دائماً',
      'manual_override': 'تحكم يدوي',
      'manual_override_desc': 'تحديد مؤقت كمفتوح/مغلق',
      'open_now': 'مفتوح',
      'closed': 'مغلق',
      'sun': 'أحد',
      'mon': 'إثن',
      'tue': 'ثلا',
      'wed': 'أرب',
      'thu': 'خمي',
      'fri': 'جمع',
      'sat': 'سبت',
      'days_selected': 'أيام',
      'tap_to_select_deselect': 'اضغط لتحديد أو إلغاء تحديد الأيام',

      // Home Screen
      'home_greeting': 'كل الأقسام',
      'search_hint': 'بحث عن خدمة - احتياج',
      'categories_title': 'الأقسام',
      'view_all': 'عرض الكل',
      'nearby_services': 'خدمات قريبة',
      'nearby_services_subtitle': 'خدمات قريبة منك',
      'additional_services': 'خدمات اضافية',
      'hotels': 'فنادق',
      'restaurants': 'مطاعم',
      'airports': 'مطارات',
      'pharmacies': 'صيدليات',

      'search': 'بحث',
      'search_radius': 'نطاق البحث',
      'km': 'كم',
      'category': 'الفئة',
      'subcategory': 'الفئة الفرعية',
      'all': 'الكل',
      'reset_filters': 'إعادة تعيين الفلاتر',
      'no_results_found': 'لم يتم العثور على نتائج',
      'try_different_search': 'جرب مصطلحات بحث مختلفة',
      'retry': 'إعادة المحاولة',
      // Banner
      'banner_text': 'نأمل أن يوفّر هذا\nدليلنا سهولة، سفر عن أماكن\nالراحة، أو أي وضع',
      'banner_badge': 'رائع شخصي',

      // Services
      'car_services': 'خدمات السيارات',
      'my_services':'خدماتي',
      'car_services_desc': 'مركز كار لصيانة السيارات',
      'carpentry_services': 'خدمات النجارة',
      'carpentry_desc': 'نجارة الأثاث لكافة اعمال الديكور المنزلي',
      'electrical_services': 'خدمات كهربائيات المنازل',
      'electrical_desc': 'لاعمال الكهربائيات المنزلية وصيانة الاجهزة الكهربائية',
      'distance_away': 'بعد',
      'please_upload_at_least_one_file':'قم برفع صورة واحده على الاقل',
      // Profile Screen
      'profile_title': 'الملف الشخصي',
      'favorites': 'المفضلة',
      'orders': 'الطلبات',
      'rating': 'التقييم',
      'my_account': 'حسابي',
      'edit_profile': 'تعديل الملف الشخصي',
      'change_password': 'تغيير كلمة المرور',
      'privacy_security': 'الخصوصية والأمان',
      'logout': 'تسجيل الخروج',
      'logout_confirm': 'هل أنت متأكد من تسجيل الخروج من حسابك؟',
      'cancel': 'إلغاء',
      'confirm': 'تاكيد',
      'made_with_love': 'صُنع بـ ❤️ في ذي قار',

      // Visitor Screen
      'welcome': 'مرحباً بك!',
      'login_message': 'سجّل الدخول للوصول إلى ملفك الشخصي\nوجميع الميزات المتاحة',
      'save_favorites': 'احفظ أماكنك المفضلة',
      'track_orders': 'تتبع سجل طلباتك',
      'get_notifications': 'احصل على إشعارات مخصصة',
      'rate_share': 'قيّم وشارك تجربتك',
      'login': 'تسجيل الدخول',
      'create_account': 'إنشاء حساب',
      'login_required': 'تسجيل الدخول مطلوب',
      'login_required_for_feature': 'يرجى تسجيل الدخول لـ {feature}',
      'add_favorites': 'الإضافة إلى المفضلة',
      'call_service': 'الاتصال بصاحب الخدمة',
      'view_contact': 'عرض معلومات الاتصال',
      'write_review': 'كتابة تقييم',
      'add_service': 'إضافة خدمة',
      'view_location': 'عرض الموقع على الخريطة',
      "delete_service": "حذف الخدمة",
      "are_you_sure_delete_service": "هل أنت متأكد أنك تريد حذف هذه الخدمة؟ لا يمكن التراجع عن هذا الإجراء.",
      "delete": "حذف",
      "service_deleted_successfully": "تم حذف الخدمة بنجاح",
      'details':'التفاصيل',

      // Settings Screen
      'settings': 'الإعدادات',
      'notifications': 'الإشعارات',
      'language': 'اللغة',
      'arabic': 'العربية',
      'english': 'English',
      'dark_mode': 'الوضع الليلي',
      'help_support': 'المساعدة والدعم',
      'contact_us': 'تواصل معنا',
      'terms_conditions': 'الشروط والأحكام',
      'privacy_policy': 'سياسة الخصوصية',
      'about_app': 'حول التطبيق',
      'version': 'الإصدار',
      'contact_us_desc': 'نحن هنا للمساعدة! اختر طريقة التواصل المفضلة لديك.',
      'email': 'البريد الإلكتروني',
      'phone': 'الهاتف',
      'app_description': 'دليلك الشامل لاكتشاف أفضل الخدمات والأماكن في ذي قار. ابحث عن المطاعم والفنادق والمتاجر والمزيد.',
      'developed_by': 'تم التطوير بواسطة',
      'all_rights_reserved': 'جميع الحقوق محفوظة',
      'close': 'إغلاق',
      'last_updated': 'آخر تحديث',
      'terms_conditions_content': '''شروط الاستخدام

1. قبول الشروط
باستخدام تطبيق دليل ذي قار، فإنك توافق على هذه الشروط والأحكام.

2. استخدام الخدمة
- يجب أن يكون عمرك 13 عامًا على الأقل لاستخدام هذا التطبيق
- أنت مسؤول عن الحفاظ على سرية حسابك
- توافق على عدم استخدام الخدمة لأي أغراض غير قانونية

3. محتوى المستخدم
- تحتفظ بملكية المحتوى الذي تقدمه
- تمنحنا ترخيصًا لاستخدام وعرض وتوزيع محتواك
- أنت مسؤول عن دقة المعلومات التي تقدمها

4. مقدمو الخدمات
- لا نضمن جودة الخدمات المدرجة
- تحقق من المعلومات مباشرة مع مقدمي الخدمات
- لسنا مسؤولين عن المعاملات بين المستخدمين ومقدمي الخدمات

5. التعديلات
نحتفظ بالحق في تعديل هذه الشروط في أي وقت. يعتبر الاستمرار في الاستخدام قبولًا للشروط المعدلة.

6. حدود المسؤولية
يتم توفير التطبيق "كما هو" بدون ضمانات. لسنا مسؤولين عن أي أضرار ناجمة عن استخدام الخدمة.

7. التواصل
لأي استفسارات حول هذه الشروط، تواصل معنا عبر التطبيق.''',
      'privacy_policy_content': '''سياسة الخصوصية

1. المعلومات التي نجمعها
- معلومات الحساب (الاسم، رقم الهاتف، البريد الإلكتروني)
- بيانات الموقع (بإذنك)
- بيانات الاستخدام والتفضيلات
- معلومات الجهاز

2. كيف نستخدم معلوماتك
- لتقديم وتحسين خدماتنا
- لتخصيص تجربتك
- لإرسال الإشعارات (بموافقتك)
- لضمان الأمان ومنع الاحتيال

3. مشاركة المعلومات
- لا نبيع معلوماتك الشخصية
- قد نشارك البيانات مع مقدمي الخدمات الذين يساعدوننا
- قد نكشف عن المعلومات عند الطلب قانونيًا

4. أمان البيانات
- نستخدم إجراءات أمان معيارية في الصناعة
- نقوم بتشفير البيانات الحساسة أثناء النقل والتخزين
- نراجع ممارساتنا الأمنية بانتظام

5. حقوقك
- الوصول إلى بياناتك الشخصية
- طلب تصحيح البيانات غير الدقيقة
- طلب حذف بياناتك
- إلغاء الاشتراك في الرسائل التسويقية

6. بيانات الموقع
- نجمع الموقع فقط عند استخدام ميزات الموقع
- يمكنك تعطيل الوصول إلى الموقع في إعدادات الجهاز

7. تحديثات السياسة
قد نحدث هذه السياسة بشكل دوري. سنخطرك بالتغييرات المهمة.

8. تواصل معنا
لأي مخاوف تتعلق بالخصوصية، تواصل معنا عبر إعدادات التطبيق.''',

      // Add Service Sheet
      'add_service_title': 'إضافة خدمة أو مكان عمل',
      'add_service_subtitle': 'أضف معلومات الخدمة الجديدة وتأكد من حفظ البيانات',
      'service_name': 'إسم الخدمة',
      'edit_service_title':'تعديل الخدمة او مكان العمل',
      'edit_service_subtitle':'قم بتعديل معلومات الخدمة وتأكد من حفظ البيانات',
      'service_name_hint': 'أكتب إسم الخدمة',
      'phone_number': 'رقم الهاتف',
      'phone_hint': 'أكتب رقم الهاتف',
      'address': 'العنوان',
      'address_hint': 'أكتب عنوان المحل أو الخدمة',
      'description': 'وصف الخدمة',
      'description_hint': 'أكتب هنا وصف الخدمة التي تقدمها',
      'select_location': 'تحديد الموقع على الخريطة',
      'tap_to_select': 'إضغط لتحديد الموقع',
      'add_attachments': 'إضافة مرفقات',
      'attachments_subtitle': 'أضف صور للخدمة (الحد الأقصى 10 صور)',
      'upload_files': 'إضغط هنا لرفع المرفقات',
      'attachments_added': 'المرفقات المضافة',
      'next': 'التالي',
      'save': 'حفظ',
      'required_field': 'هذا الحقل مطلوب',
      'files_selected': 'تم اختيار الملفات بنجاح',
      'images_selected': 'صور مختارة',
      'max_images_reached': 'الحد الأقصى 10 صور مسموح',
      'added_images_limit': 'تمت إضافة الصور (الحد الأقصى)',
      'service_saved': 'تم حفظ الخدمة بنجاح',
      'show_on_map': "عرض على الخارطة",
      'edit':'تعديل',
      "select_category": "اختر الفئة",
      "select_subcategory": "اختر الفئة الفرعية",
      "please_select_category": "الرجاء اختيار فئة",
      "please_select_subcategory": "الرجاء اختيار فئة فرعية",
      "no_subcategories": "لا توجد فئات فرعية متاحة",
      "invalid_phone": "يجب أن يكون رقم الهاتف 10 أرقام على الأقل",
      "please_select_location": "الرجاء تحديد موقع",
      "location_selected": "تم تحديد الموقع بنجاح",
      "using_default_location": "استخدام الموقع الافتراضي",
      "manage_attachments": "إدارة المرفقات",
      "tap_to_browse": "انقر لتصفح الملفات",
      "current_attachments": "المرفقات الحالية",
      "uploaded_files": "الملفات المرفوعة",
      "new_files": "ملفات جديدة للرفع",
      "uploaded": "تم الرفع",
      "no_attachments": "لا توجد مرفقات بعد",
      "files": "ملفات",
      "error_picking_files": "خطأ في اختيار الملفات",
      "delete_file": "حذف الملف",
      "delete_file_confirmation": "هل أنت متأكد من حذف هذا الملف؟ لا يمكن التراجع عن هذا الإجراء.",
      "file_deleted_successfully": "تم حذف الملف بنجاح",
      "failed_to_delete_file": "فشل حذف الملف",
      "error_deleting_file": "حدث خطأ أثناء حذف الملف",
      "back": "رجوع",
      "dismiss": "تجاهل",
      "adding_service": "جاري إضافة الخدمة...",
      "updating_service": "جاري تحديث الخدمة...",
      "please_wait": "يرجى الانتظار",
      "service_added_successfully": "تمت إضافة الخدمة بنجاح",
      "service_updated_successfully": "تم تحديث الخدمة بنجاح",
      "failed_to_add_service": "فشل في إضافة الخدمة",
      "failed_to_update_service": "فشل في تحديث الخدمة",
      "authentication_required": "المصادقة مطلوبة. الرجاء تسجيل الدخول.",
      "authentication_failed": "فشلت المصادقة",
      "please_login_again": "يرجى تسجيل الدخول مرة أخرى للمتابعة",

      // Location & Nearby Services
      'location_permission_required': 'إذن الموقع مطلوب',
      'location_permission_settings_message': 'إذن الموقع مطلوب لعرض الخدمات القريبة. يرجى تفعيله من إعدادات التطبيق.',
      'grant_location_access_message': 'امنح إذن الموقع لرؤية الخدمات القريبة منك',
      'grant_permission': 'منح الإذن',
      'location_access_disabled': 'الوصول للموقع معطل',
      'enable_location_settings_message': 'فعّل الموقع في الإعدادات لرؤية الخدمات القريبة',
      'location_service_disabled': 'خدمة الموقع معطلة',
      'enable_location_service_message': 'فعّل خدمات الموقع لرؤية الخدمات القريبة',
      'enable_service': 'تفعيل الخدمة',
      'using_approximate_location': 'استخدام موقع تقريبي',
      'services_default_location_message': 'الخدمات معروضة بناءً على الموقع الافتراضي',
      'try_again': 'حاول مرة أخرى',
      'could_not_load_services': 'تعذر تحميل الخدمات',
      'showing_approximate_location': 'عرض الخدمات بناءً على موقع تقريبي',
      'no_services_nearby': 'لا توجد خدمات قريبة',
      'no_services_within_distance': 'لا توجد خدمات ضمن مسافة 10 كم من موقعك',
      'open_settings': 'فتح الإعدادات',
      'no_services_from_api': 'لا توجد خدمات متاحة من الخادم',
      'loading_services': 'جاري تحميل الخدمات...',
      'no_services_found': 'لم يتم العثور على خدمات',
      'try_another_filter': 'جرب قسم أو تصنيف آخر',
      'services': 'خدمات',
      'network_error': 'خطأ في الشبكة',
      'network_error_desc': 'يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى',
      'server_error': 'خطأ في الخادم',
      'server_error_desc': 'الخادم غير متاح مؤقتًا. يرجى المحاولة لاحقًا',
      'not_found': 'غير موجود',
      'not_found_desc': 'تعذر العثور على المورد المطلوب',
      'something_went_wrong': 'حدث خطأ ما',
      'no_services_available': 'لا توجد خدمات متاحة',
      'check_back_later': 'تحقق لاحقًا من الخدمات الجديدة',
      'timeout_error': 'انتهت مهلة الطلب',
      'timeout_error_desc': 'استغرق الطلب وقتًا طويلاً. يرجى المحاولة مرة أخرى',
      'session_expired_desc': 'انتهت جلستك. يرجى تسجيل الدخول مرة أخرى للمتابعة',
      'services_not_found_desc': 'تعذر العثور على الخدمات المطلوبة',
      'unexpected_error_desc': 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى',
      'go_back': 'العودة',
      'show_all': 'عرض الكل',
      'add_service':'اضافة خدمة',

      // Service Details Screen - NEW KEYS
      'edit_service': 'تعديل الخدمة',
      'contact_info': 'معلومات الاتصال',
      'connect_with_us': 'تواصل معنا',
      'location': 'الموقع',
      'open_map': 'افتح الخريطة',
      'directions': 'الاتجاهات',
      'no_image': 'لا توجد صورة',
      'no_image_available': 'لا توجد صورة متاحة',
      'cannot_open_link': 'لا يمكن فتح الرابط',
      'error_opening_link': 'حدث خطأ أثناء فتح الرابط',
      'cannot_open_whatsapp': 'لا يمكن فتح واتساب',
      'error_opening_whatsapp': 'حدث خطأ أثناء فتح واتساب',
      'cannot_make_call': 'لا يمكن إجراء المكالمة',
      'error_making_call': 'حدث خطأ أثناء إجراء المكالمة',
      'location_not_available': 'الموقع غير متوفر',
      'deleting_service': 'جاري حذف الخدمة...',
      'failed_to_delete_service': 'فشل في حذف الخدمة',
      'error_deleting_service': 'حدث خطأ أثناء حذف الخدمة',
      'service_owner': 'مالك الخدمة',
      'image_counter': 'صورة {current} من {total}',
      'posted_by': 'نُشر بواسطة',
      'unknown_user': 'مستخدم غير معروف',
      'verified': 'موثق',
      'unverified': 'غير موثق',

      // Common
      'guest': 'زائر',
      'after': 'بعد',
      'exit_app': 'الخروج من التطبيق',
      'exit_app_confirm': 'هل أنت متأكد أنك تريد الخروج من التطبيق؟',
      'exit': 'خروج',
      'forgot_password': 'نسيت كلمة السر',
      'name': 'الاسم',
      'confirm_password': 'تاكيد كلمة السر',
      'confirm_password_des': 'اعد كتابة كلمة المرور',
      'already_have_account': 'لديك حساب بالفعل ؟ ',
      'range':'نطاق',
      'service':'خدمة',
      "open_in_maps": "فتح في الخرائط",

      // Complete Profile Screen
      'complete_profile': 'أكمل ملفك الشخصي',
      'complete_profile_subtitle': 'ساعدنا في تخصيص تجربتك',
      'step_of': 'الخطوة {current} من {total}',
      'what_is_your_gender': 'ما هو جنسك؟',
      'male': 'ذكر',
      'female': 'أنثى',
      'when_were_you_born': 'متى ولدت؟',
      'select_birth_date': 'اختر تاريخ ميلادك',
      'where_do_you_live': 'أين تسكن؟',
      'select_city': 'اختر مدينتك',
      'what_is_your_occupation': 'ما هي مهنتك؟',
      'select_occupation': 'اختر مهنتك',
      'what_are_your_interests': 'ما هي اهتماماتك؟',
      'select_interests': 'اختر اهتماماتك',
      'previous': 'السابق',
      'finish': 'إنهاء',
      'profile_completed': 'تم إكمال الملف الشخصي!',
      'thank_you_profile': 'شكراً لإكمال ملفك الشخصي',
      'error_saving_profile': 'حدث خطأ في حفظ البيانات',
      'interests_selected': 'تم اختيار {count} اهتمامات',
      'years_old': 'سنة',

      // Occupations
      'occupation_student': 'طالب',
      'occupation_employee': 'موظف',
      'occupation_freelancer': 'عمل حر',
      'occupation_business_owner': 'صاحب عمل',
      'occupation_doctor': 'طبيب',
      'occupation_engineer': 'مهندس',
      'occupation_teacher': 'معلم',
      'occupation_retired': 'متقاعد',
      'occupation_housewife': 'ربة منزل',
      'occupation_unemployed': 'باحث عن عمل',
      'occupation_other': 'أخرى',

      // Interests
      'interest_restaurants': 'المطاعم والكافيهات',
      'interest_hotels': 'الفنادق والسكن',
      'interest_shopping': 'التسوق والمولات',
      'interest_healthcare': 'الصحة والطب',
      'interest_education': 'التعليم والتدريب',
      'interest_car_services': 'خدمات السيارات',
      'interest_home_services': 'الخدمات المنزلية',
      'interest_tourism': 'السياحة والسفر',
      'interest_sports': 'الرياضة واللياقة',
      'interest_entertainment': 'الترفيه',

      // Ad Actions
      'view_service': 'عرض الخدمة',
      'discover_more': 'اكتشف المزيد',
      'try_now': 'جرب الآن',
      'sponsored': 'إعلان',
      'featured_service': 'خدمة مميزة',
      'cannot_open_url': 'لا يمكن فتح الرابط',
      'service_not_found': 'لم يتم العثور على الخدمة',

      // Onboarding Screen
      'onboarding_title_1': 'دليل ذي قار',
      'onboarding_desc_1': 'تطبيقك الشامل للعثور على جميع الخدمات التي تحتاجها في منطقتك بسهولة وسرعة.',
      'onboarding_title_2': 'اكتشف الخدمات',
      'onboarding_desc_2': 'تصفح الخدمات المتوفرة من حولك — من الصيانة إلى التجميل — مع تفاصيل ومواقع دقيقة.',
      'onboarding_title_3': 'احجز وتابع بسهولة',
      'onboarding_desc_3': 'احجز خدمتك بنقرة واحدة، وتتبع حالة الطلب حتى الاكتمال بكل شفافية وراحة.',
      'skip': 'تخطي',
      'get_started': 'البدء',

      // Validation Messages
      'invalid_phone_number': 'رقم الهاتف غير صحيح',
      'password_too_short': 'كلمة المرور قصيرة جداً',
      'password_min_6': 'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
      'name_min_3': 'يجب أن يكون الاسم 3 أحرف على الأقل',
      'passwords_not_match': 'كلمة المرور غير متطابقة',
      'login_failed': 'فشل تسجيل الدخول',
      'registration_failed': 'فشل التسجيل',
      'password': 'كلمة المرور',
      'enter_password': 'أدخل كلمة المرور',

      // Debug Section
      'debug_local_db': 'تصحيح (قاعدة بيانات محلية)',
      'delete_test_users': 'حذف المستخدمين التجريبيين',
      'delete_test_users_desc': 'إزالة جميع المستخدمين التجريبيين المسجلين',
      'reset_database': 'إعادة تعيين قاعدة البيانات',
      'reset_database_desc': 'إعادة تعيين جميع البيانات المحلية',
      'reset_database_title': 'إعادة تعيين قاعدة البيانات؟',
      'reset_database_confirm': 'سيتم حذف جميع البيانات المحلية وإعادة تعيينها إلى البيانات الافتراضية. لا يمكن التراجع عن هذا الإجراء.',
      'reset': 'إعادة تعيين',
      'deleted_users': 'تم حذف {count} مستخدم(ين) تجريبي',
      'database_reset_success': 'تم إعادة تعيين قاعدة البيانات بنجاح',

      // Favorites Screen
      'no_favorites': 'لا توجد مفضلات',
      'no_favorites_desc': 'أضف الخدمات إلى مفضلتك لتظهر هنا',
      'browse_services': 'تصفح الخدمات',
      'remove_from_favorites': 'إزالة من المفضلة',
      'added_to_favorites': 'تمت الإضافة إلى المفضلة',
      'removed_from_favorites': 'تمت الإزالة من المفضلة',

      // Additional keys for localization
      'press_again_to_exit': 'اضغط مرة أخرى للخروج من التطبيق',
      'filters': 'الفلاتر',
      'search_range': 'نطاق البحث',
      'enabled': 'مفعّل',
      'disabled': 'متوقف',
      'start_typing': 'ابدأ بالكتابة للبحث',
      'loading_text': 'جاري التحميل...',
      'start_search': 'ابدأ البحث',
      'type_to_search': 'اكتب ما تبحث عنه في الأعلى\nللحصول على نتائج فورية',
      'try_different_keywords': 'جرب كلمات بحث مختلفة\nأو قم بتغيير الفلاتر',
      'error_occurred': 'عذراً، حدث خطأ!',
      'found_services': 'وجدنا {count} خدمة',
      'failed_to_load_services': 'فشل تحميل الخدمات',
      'failed_to_load_favorites': 'فشل تحميل المفضلة',
      'refresh': 'تحديث',
      'error_occurred_title': 'حدث خطأ',
      'not_logged_in': 'غير مسجل',
      'please_login_to_view_favorites': 'الرجاء تسجيل الدخول لعرض المفضلة',
      'no_favorites_yet': 'لا توجد مفضلة بعد',
      'start_adding_favorites': 'ابدأ بإضافة الخدمات المفضلة لديك\nلتصفحها بسهولة لاحقاً',

      // Cities
      'city_baghdad': 'بغداد',
      'city_basra': 'البصرة',
      'city_mosul': 'الموصل',
      'city_erbil': 'أربيل',
      'city_najaf': 'النجف',
      'city_karbala': 'كربلاء',
      'city_nasiriyah': 'الناصرية',
      'city_sulaymaniyah': 'السليمانية',
      'city_kirkuk': 'كركوك',
      'city_hilla': 'الحلة',
      'city_diwaniyah': 'الديوانية',
      'city_kut': 'الكوت',
      'city_samawah': 'السماوة',
      'city_amarah': 'العمارة',
      'city_ramadi': 'الرمادي',
      'city_baqubah': 'بعقوبة',
      'city_tikrit': 'تكريت',
      'city_duhok': 'دهوك',

      // Interests for profile completion
      'interest_restaurants': 'المطاعم والمقاهي',
      'interest_hotels': 'الفنادق والسكن',
      'interest_tourism': 'السياحة والآثار',
      'interest_shopping': 'التسوق',
      'interest_healthcare': 'الصحة والطب',
      'interest_education': 'التعليم',
      'interest_sports': 'الرياضة',
      'interest_entertainment': 'الترفيه',
      'interest_automotive': 'السيارات',
      'interest_real_estate': 'العقارات',

      // Occupations
      'occupation_student': 'طالب',
      'occupation_government': 'موظف حكومي',
      'occupation_private': 'موظف قطاع خاص',
      'occupation_freelance': 'أعمال حرة',
      'occupation_doctor': 'طبيب',
      'occupation_engineer': 'مهندس',
      'occupation_teacher': 'معلم / مدرس',
      'occupation_merchant': 'تاجر',
      'occupation_retired': 'متقاعد',
      'occupation_housewife': 'ربة منزل',
      'occupation_other': 'أخرى',

      // No results
      'no_results_found': 'لا توجد نتائج',

      // Favorites
      'please_login_first': 'الرجاء تسجيل الدخول أولاً',
      'operation_failed': 'فشلت العملية. حاول مرة أخرى',
      'add_to_favorites': 'إضافة إلى المفضلة',
      'favorite': 'مفضل',

      // Nearby services
      'searching_nearby_services': 'جاري البحث عن خدمات قريبة...',
      'searching_in_range': 'البحث في نطاق',
      'no_services_in_range': 'لم يتم العثور على خدمات في نطاق',
      'service': 'خدمة',

      // Service card
      'call_to': 'اتصال بـ',
      'call_now': 'اتصال الآن',

      // Location permissions
      'location_permission_required': 'صلاحية الموقع مطلوبة',
      'location_permission_settings_message': 'يرجى تفعيل صلاحية الموقع من الإعدادات للعثور على الخدمات القريبة',
      'grant_location_access_message': 'امنح صلاحية الموقع للعثور على الخدمات القريبة منك',
      'grant_permission': 'منح الصلاحية',
      'location_access_disabled': 'صلاحية الموقع معطلة',
      'enable_location_settings_message': 'يرجى تفعيل الموقع من الإعدادات',
      'open_settings': 'فتح الإعدادات',
      'location_service_disabled': 'خدمة الموقع معطلة',
      'enable_location_service_message': 'يرجى تفعيل خدمة الموقع',
      'enable_service': 'تفعيل الخدمة',
      'please_login_again': 'يرجى تسجيل الدخول مرة أخرى',
      'could_not_load_services': 'تعذر تحميل الخدمات',

      // Age groups
      'age_under_18': 'أقل من 18',
      'age_18_24': '18-24',
      'age_25_34': '25-34',
      'age_35_44': '35-44',
      'age_45_54': '45-54',
      'age_55_plus': '55+',
      'age_not_specified': 'غير محدد',

      // Status badges
      'available': 'متاح',
      'unavailable': 'غير متاح',
      'sponsored': 'إعلان',
      'featured': 'مميز',

      // Search section
      'discover_services': 'اكتشف أفضل الخدمات والأماكن',

      // Nearby services
      'no_nearby_services': 'لا توجد خدمات قريبة',

      // Reviews & Ratings
      'reviews': 'التقييمات',
      'write_review': 'اكتب تقييم',
      'edit_review': 'تعديل التقييم',
      'edit_your_review': 'تعديل تقييمك',
      'your_review': 'تقييمك',
      'no_reviews_yet': 'لا توجد تقييمات بعد',
      'be_first_to_review': 'كن أول من يشارك تجربته!',
      'how_would_you_rate': 'كيف تقيم هذه الخدمة؟',
      'write_your_review': 'شارك تجربتك مع الآخرين...',
      'submit_review': 'إرسال التقييم',
      'update_review': 'تحديث التقييم',
      'delete_review': 'حذف التقييم',
      'delete_review_confirm': 'هل أنت متأكد من حذف هذا التقييم؟',
      'review_submitted': 'تم إرسال التقييم بنجاح',
      'review_updated': 'تم تحديث التقييم بنجاح',
      'review_deleted': 'تم حذف التقييم بنجاح',
      'review_submit_failed': 'فشل إرسال التقييم',
      'please_select_rating': 'الرجاء اختيار تقييم',
      'comment_too_short': 'يجب أن يكون التعليق 10 أحرف على الأقل',
      'comment_too_long': 'لا يمكن أن يتجاوز التعليق 1000 حرف',
      'min_characters': 'الحد الأدنى للأحرف',
      'rate_limit_exceeded': 'يرجى الانتظار قبل إرسال تقييم آخر',
      'rate_limit_wait': 'يرجى الانتظار {seconds} ثانية قبل الإرسال',
      'login_required_for_review': 'يرجى تسجيل الدخول لكتابة تقييم',
      'already_reviewed': 'لقد قمت بتقييم هذه الخدمة مسبقاً',
      'review_not_found': 'التقييم غير موجود',
      'review_not_editable': 'يمكن تعديل التقييم خلال 7 أيام فقط',
      'invalid_rating': 'يرجى اختيار تقييم صحيح',
      'helpful': 'مفيد',
      'report': 'إبلاغ',
      'report_review': 'الإبلاغ عن التقييم',
      'report_review_confirm': 'هل أنت متأكد من الإبلاغ عن هذا التقييم؟',
      'review_reported': 'تم الإبلاغ عن التقييم. شكراً لك!',
      'show_more': 'عرض المزيد',
      'show_less': 'عرض أقل',
      'edited': 'معدّل',
      'based_on_reviews': 'بناءً على {count} تقييم',

      // Rating labels
      'rating_excellent': 'ممتاز',
      'rating_very_good': 'جيد جداً',
      'rating_good': 'جيد',
      'rating_fair': 'مقبول',
      'rating_poor': 'ضعيف',

      // Time ago
      'just_now': 'الآن',
      'minute_ago': 'منذ دقيقة',
      'minutes_ago': 'منذ {n} دقائق',
      'hour_ago': 'منذ ساعة',
      'hours_ago': 'منذ {n} ساعات',
      'day_ago': 'منذ يوم',
      'days_ago': 'منذ {n} أيام',
      'week_ago': 'منذ أسبوع',
      'weeks_ago': 'منذ {n} أسابيع',
      'month_ago': 'منذ شهر',
      'months_ago': 'منذ {n} أشهر',
      'year_ago': 'منذ سنة',
      'years_ago': 'منذ {n} سنوات',

      // Service Details - Owner Actions
      'manage_service': 'إدارة الخدمة',
      'mark_closed': 'تحديد كمغلق',
      'mark_open': 'تحديد كمفتوح',
      'service_marked_open': 'تم تحديد الخدمة كمفتوحة',
      'service_marked_closed': 'تم تحديد الخدمة كمغلقة',
      'tap_to_call': 'اضغط للاتصال',
      'tap_for_directions': 'اضغط للاتجاهات',
      'tap_to_chat': 'اضغط للمحادثة على واتساب',
      'quick_actions': 'إجراءات سريعة',
      'about': 'حول',
      'view_on_map': 'عرض على الخريطة',
      'call': 'اتصال',

      // Featured Services Sections
      'top_rated': 'الأعلى تقييماً',
      'top_rated_subtitle': 'خدمات حازت على أعلى التقييمات',
      'no_top_rated': 'لا توجد خدمات مميزة',
      'no_top_rated_subtitle': 'تحقق لاحقاً من الخدمات ذات التقييم العالي',
      'recently_added': 'أضيفت مؤخراً',
      'recently_added_subtitle': 'خدمات جديدة هذا الشهر',
      'no_recently_added': 'لا توجد خدمات جديدة',
      'no_recently_added_subtitle': 'لم تتم إضافة خدمات مؤخراً',
      'open_now_services': 'مفتوح الآن',
      'open_now_subtitle': 'خدمات متاحة حالياً',
      'no_open_now': 'لا توجد خدمات مفتوحة',
      'no_open_now_subtitle': 'تحقق خلال ساعات العمل',

      'verified_services': 'خدمات موثقة',
      'verified_services_subtitle': 'موثوق من فريقنا',
      'no_verified_services': 'لا توجد خدمات موثقة',
      'no_verified_services_subtitle': 'تحقق لاحقاً من الخدمات الموثقة',
      'verified_owner': 'مالك موثق',

      // Notifications
      'no_notifications': 'لا توجد إشعارات',
      'no_notifications_subtitle': 'أنت على اطلاع! ستظهر الإشعارات الجديدة هنا.',
      'mark_all_read': 'تحديد الكل كمقروء',
      'delete_all': 'حذف الكل',
      'delete_all_notifications': 'حذف جميع الإشعارات',
      'delete_all_notifications_confirm': 'هل أنت متأكد من حذف جميع الإشعارات؟ لا يمكن التراجع عن هذا.',
      'today': 'اليوم',
      'yesterday': 'أمس',
      'this_week': 'هذا الأسبوع',
      'older': 'أقدم',
      'notification_review': 'تقييم جديد',
      'notification_favorite': 'إضافة للمفضلة',
      'notification_message': 'رسالة جديدة',
      'notification_service_update': 'تحديث الخدمة',
      'notification_promotion': 'عرض خاص',
      'notification_system': 'إشعار النظام',

      // Edit Profile Screen
      'full_name': 'الاسم الكامل',
      'enter_name': 'أدخل اسمك',
      'name_min_3': 'الاسم يجب أن يكون 3 أحرف على الأقل',
      'gender': 'الجنس',
      'male': 'ذكر',
      'female': 'أنثى',
      'birth_date': 'تاريخ الميلاد',
      'select_birth_date': 'اختر تاريخ الميلاد',
      'city': 'المدينة',
      'select_city': 'اختر المدينة',
      'occupation': 'المهنة',
      'select_occupation': 'اختر المهنة',
      'interests': 'الاهتمامات',
      'save': 'حفظ',
      'save_changes': 'حفظ التغييرات',
      'profile_updated': 'تم تحديث الملف الشخصي بنجاح',
      'profile_info': 'معلومات الملف الشخصي',
      'years': 'سنة',
      'complete_profile_hint': 'أكمل ملفك الشخصي لنتمكن من تخصيص تجربتك',
      'camera': 'الكاميرا',
      'gallery': 'المعرض',

      // Change Password Screen
      'current_password': 'كلمة المرور الحالية',
      'enter_current_password': 'أدخل كلمة المرور الحالية',
      'new_password': 'كلمة المرور الجديدة',
      'enter_new_password': 'أدخل كلمة المرور الجديدة',
      'confirm_password': 'تأكيد كلمة المرور',
      'confirm_new_password': 'تأكيد كلمة المرور الجديدة',
      'password_min_6': 'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
      'password_must_be_different': 'كلمة المرور الجديدة يجب أن تكون مختلفة',
      'passwords_not_match': 'كلمات المرور غير متطابقة',
      'password_changed': 'تم تغيير كلمة المرور بنجاح',
      'password_change_failed': 'فشل في تغيير كلمة المرور',
      'password_requirements': 'استخدم كلمة مرور قوية تتكون من 6 أحرف على الأقل مع أرقام ورموز',
      'weak': 'ضعيفة',
      'medium': 'متوسطة',
      'strong': 'قوية',

      // Notification Settings Screen
      'notification_settings': 'إعدادات الإشعارات',
      'manage_notifications': 'إدارة تفضيلات الإشعارات',
      'push_notifications': 'الإشعارات',
      'notifications_enabled': 'الإشعارات مفعّلة',
      'notifications_disabled': 'الإشعارات معطّلة',
      'notifications_turned_on': 'تم تفعيل الإشعارات',
      'notifications_turned_off': 'تم إيقاف الإشعارات',
      'notification_toggle_failed': 'فشل في تحديث الإشعارات',
      'enable_all_notifications': 'تفعيل أو تعطيل جميع الإشعارات',
      'notification_types': 'أنواع الإشعارات',
      'review_notifications': 'إشعارات التقييمات',
      'review_notifications_desc': 'إشعار عندما يقيم شخص خدمتك',
      'favorite_notifications': 'إشعارات المفضلة',
      'favorite_notifications_desc': 'إشعار عندما يضيف شخص خدمتك للمفضلة',
      'service_update_notifications': 'تحديثات الخدمة',
      'service_update_notifications_desc': 'إشعار عن تحديثات الخدمة',
      'promotion_notifications': 'العروض',
      'promotion_notifications_desc': 'إشعار عن العروض الخاصة',
      'ads_notifications': 'العروض الخاصة',
      'ads_notifications_desc': 'إشعار عن الإعلانات الجديدة',
      'system_notifications': 'إشعارات النظام',
      'system_notifications_desc': 'إعلانات النظام المهمة',
      'verification_notifications': 'إشعارات التوثيق',
      'verification_notifications_desc': 'إشعار عند تغيير حالة توثيق حسابك',
      'notification_settings_info': 'يتم حفظ التغييرات تلقائياً. يمكنك تفعيل أو تعطيل أنواع الإشعارات المختلفة.',
      'push_enabled_success': 'تم تفعيل الإشعارات بنجاح',
      'push_disabled_success': 'تم إيقاف الإشعارات بنجاح',
      'push_toggle_failed': 'فشل في تحديث إعدادات الإشعارات',
    },
  };

  // Get translation by key
  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  // Short method for easy access
  String t(String key) => translate(key);
}

// Localization Delegate
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}