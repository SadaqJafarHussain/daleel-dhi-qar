import 'package:flutter/material.dart';

class OnboardingSlide {
  final int id;
  final int sortOrder;
  final String titleAr;
  final String titleEn;
  final String subtitleAr;
  final String subtitleEn;
  final String? imageUrl;
  final String bgColor;
  final bool active;

  const OnboardingSlide({
    required this.id,
    required this.sortOrder,
    required this.titleAr,
    required this.titleEn,
    required this.subtitleAr,
    required this.subtitleEn,
    this.imageUrl,
    required this.bgColor,
    required this.active,
  });

  factory OnboardingSlide.fromJson(Map<String, dynamic> json) => OnboardingSlide(
    id:          json['id'] as int,
    sortOrder:   (json['sort_order'] as int?) ?? 0,
    titleAr:     (json['title_ar']    as String?) ?? '',
    titleEn:     (json['title_en']    as String?) ?? '',
    subtitleAr:  (json['subtitle_ar'] as String?) ?? '',
    subtitleEn:  (json['subtitle_en'] as String?) ?? '',
    imageUrl:    json['image_url'] as String?,
    bgColor:     (json['bg_color'] as String?) ?? '#B91C4C',
    active:      (json['active'] as bool?) ?? true,
  );

  String title(bool isAr)    => isAr ? titleAr    : titleEn;
  String subtitle(bool isAr) => isAr ? subtitleAr : subtitleEn;

  Color get color {
    try {
      final cleaned = bgColor.replaceFirst('#', '');
      final full = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
      return Color(int.parse(full, radix: 16));
    } catch (_) {
      return const Color(0xFFB91C4C);
    }
  }
}
