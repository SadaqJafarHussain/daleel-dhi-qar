import '../models/user_model.dart';

/// Ad types supported by the app
enum AdType {
  /// Service promotion - clicking opens service details
  servicePromotion,
  /// External link - clicking opens external URL
  externalLink,
  /// App feature promotion - clicking navigates within app
  appPromotion,
  /// General announcement - no action on click
  announcement,
}

/// Ad targeting criteria
class AdTargeting {
  final List<String>? targetGenders;      // e.g., ['male', 'female']
  final int? minAge;                       // Minimum age
  final int? maxAge;                       // Maximum age
  final List<String>? targetCities;        // e.g., ['الناصرية', 'البصرة']
  final List<String>? targetInterests;     // e.g., ['restaurants', 'hotels']
  final List<String>? targetOccupations;   // e.g., ['طالب', 'موظف']

  AdTargeting({
    this.targetGenders,
    this.minAge,
    this.maxAge,
    this.targetCities,
    this.targetInterests,
    this.targetOccupations,
  });

  factory AdTargeting.fromJson(Map<String, dynamic>? json) {
    if (json == null) return AdTargeting();

    return AdTargeting(
      targetGenders: json['target_genders'] != null
          ? List<String>.from(json['target_genders'])
          : null,
      minAge: json['min_age'],
      maxAge: json['max_age'],
      targetCities: json['target_cities'] != null
          ? List<String>.from(json['target_cities'])
          : null,
      targetInterests: json['target_interests'] != null
          ? List<String>.from(json['target_interests'])
          : null,
      targetOccupations: json['target_occupations'] != null
          ? List<String>.from(json['target_occupations'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'target_genders': targetGenders,
      'min_age': minAge,
      'max_age': maxAge,
      'target_cities': targetCities,
      'target_interests': targetInterests,
      'target_occupations': targetOccupations,
    };
  }

  /// Check if this ad should be shown to a specific user
  bool matchesUser(UserModel? user) {
    // If no user or no targeting, show to everyone
    if (user == null) return true;
    if (!hasTargeting) return true;

    // Check gender targeting
    if (targetGenders != null && targetGenders!.isNotEmpty) {
      if (user.gender == null) return false;
      if (!targetGenders!.contains(user.gender!.name)) return false;
    }

    // Check age targeting
    if (minAge != null || maxAge != null) {
      final userAge = user.age;
      if (userAge == null) return false;
      if (minAge != null && userAge < minAge!) return false;
      if (maxAge != null && userAge > maxAge!) return false;
    }

    // Check city targeting
    if (targetCities != null && targetCities!.isNotEmpty) {
      if (user.city == null) return false;
      if (!targetCities!.contains(user.city)) return false;
    }

    // Check interests targeting (at least one match)
    if (targetInterests != null && targetInterests!.isNotEmpty) {
      if (user.interests == null || user.interests!.isEmpty) return false;
      final hasMatchingInterest = targetInterests!.any(
        (interest) => user.interests!.contains(interest),
      );
      if (!hasMatchingInterest) return false;
    }

    // Check occupation targeting
    if (targetOccupations != null && targetOccupations!.isNotEmpty) {
      if (user.occupation == null) return false;
      if (!targetOccupations!.contains(user.occupation)) return false;
    }

    return true;
  }

  /// Check if any targeting is set
  bool get hasTargeting =>
      (targetGenders != null && targetGenders!.isNotEmpty) ||
      minAge != null ||
      maxAge != null ||
      (targetCities != null && targetCities!.isNotEmpty) ||
      (targetInterests != null && targetInterests!.isNotEmpty) ||
      (targetOccupations != null && targetOccupations!.isNotEmpty);
}

class AdvModel {
  final int id;
  final String title;
  final String content;
  final String image;
  final String link;
  final int? serviceId; // For service promotion ads
  final AdType adType;
  final String? buttonText; // Custom button text
  final String? gradientStart; // Custom gradient color
  final String? gradientEnd;
  final bool isSponsored; // Show "Sponsored" badge
  final AdTargeting targeting; // Targeting criteria

  AdvModel({
    required this.id,
    required this.title,
    required this.content,
    required this.image,
    required this.link,
    this.serviceId,
    this.adType = AdType.externalLink,
    this.buttonText,
    this.gradientStart,
    this.gradientEnd,
    this.isSponsored = false,
    AdTargeting? targeting,
  }) : targeting = targeting ?? AdTargeting();

  factory AdvModel.fromJson(Map<String, dynamic> json) {
    // Determine ad type based on available data
    AdType type = AdType.externalLink;
    if (json['service_id'] != null) {
      type = AdType.servicePromotion;
    } else if (json['type'] != null) {
      switch (json['type']) {
        case 'service':
          type = AdType.servicePromotion;
          break;
        case 'external':
          type = AdType.externalLink;
          break;
        case 'app':
          type = AdType.appPromotion;
          break;
        case 'announcement':
          type = AdType.announcement;
          break;
      }
    }

    return AdvModel(
      id: json['id'],
      title: json['title'] ?? "",
      content: json['content'] ?? "",
      image: json['image'] ?? "",
      link: json['link'] ?? "",
      serviceId: json['service_id'],
      adType: type,
      buttonText: json['button_text'],
      gradientStart: json['gradient_start'],
      gradientEnd: json['gradient_end'],
      isSponsored: json['is_sponsored'] == true || json['is_sponsored'] == 1,
      targeting: AdTargeting.fromJson(json['targeting']),
    );
  }

  /// Check if this ad should be shown to a specific user
  bool shouldShowToUser(UserModel? user) {
    return targeting.matchesUser(user);
  }

  /// Check if this ad has a valid action
  bool get hasAction =>
      adType != AdType.announcement &&
      (link.isNotEmpty || serviceId != null);

  /// Get the appropriate button text based on ad type
  /// Pass localized strings for each type, or use the defaultText as fallback
  String getButtonText(String defaultText, {
    String? serviceText,
    String? externalText,
    String? appText,
  }) {
    if (buttonText != null && buttonText!.isNotEmpty) {
      return buttonText!;
    }
    switch (adType) {
      case AdType.servicePromotion:
        return serviceText ?? defaultText;
      case AdType.externalLink:
        return externalText ?? defaultText;
      case AdType.appPromotion:
        return appText ?? defaultText;
      case AdType.announcement:
        return '';
    }
  }
}
