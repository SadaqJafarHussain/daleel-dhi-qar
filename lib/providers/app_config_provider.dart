import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/realtime_service.dart';

/// Provides key/value config from the `app_config` table with realtime updates.
class AppConfigProvider extends ChangeNotifier {
  final RealtimeService _realtime = RealtimeService();

  Map<String, String> _config = {};
  bool _loaded = false;

  // ── Accessors ────────────────────────────────────────────────────────────
  String get(String key, {String fallback = ''}) => _config[key] ?? fallback;

  String get whatsapp     => get('whatsapp');
  String get phone        => get('phone');
  String get email        => get('email');
  String get instagram    => get('instagram');
  String get facebook     => get('facebook');
  String get twitter      => get('twitter');
  String get youtube      => get('youtube');
  String get website      => get('website');
  String get playStoreUrl => get('play_store_url');
  String get appStoreUrl  => get('app_store_url');

  // ── Branding ──────────────────────────────────────────────────────────────
  static const Color _defaultPrimary   = Color(0xFFB91C4C);
  static const Color _defaultSecondary = Color(0xFF1E3A2C);

  Color get primaryColor   => _parseColor(get('theme_primary_color'),   _defaultPrimary);
  Color get secondaryColor => _parseColor(get('theme_secondary_color'), _defaultSecondary);

  static Color _parseColor(String hex, Color fallback) {
    if (hex.isEmpty) return fallback;
    try {
      final cleaned = hex.replaceFirst('#', '');
      final full = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
      return Color(int.parse(full, radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  // ── Notification card style ───────────────────────────────────────────────
  double _dbl(String key, double fallback) {
    final v = double.tryParse(get(key));
    return (v != null && v > 0) ? v : fallback;
  }

  int _int(String key, int fallback) {
    final v = int.tryParse(get(key));
    return v ?? fallback;
  }

  double get notifTitleSize    => _dbl('notif_card_title_size', 14);
  double get notifBodySize     => _dbl('notif_card_body_size',  13);
  double get notifCardPadding  => _dbl('notif_card_padding',    14);
  double get notifIconSize     => _dbl('notif_card_icon_size',  40);
  Color  get notifUnreadColor  => _parseColor(get('notif_card_unread_color'), const Color(0xFFE0F2FE));
  Color  get notifAccentColor  => _parseColor(get('notif_card_accent_color'), const Color(0xFF3B82F6));
  String get notifLogoUrl      => get('notif_card_logo_url');

  // ── App strings (AR/EN) ───────────────────────────────────────────────────
  String _str(String keyAr, String keyEn, bool isAr, String fallback) {
    final v = isAr ? get(keyAr) : get(keyEn);
    return v.isNotEmpty ? v : fallback;
  }

  String appName(bool isAr) => _str(
        'app_name_ar', 'app_name_en', isAr,
        isAr ? 'دليل ذي قار' : 'Daleel Dhi Qar');

  String appTagline(bool isAr) => _str(
        'app_tagline_ar', 'app_tagline_en', isAr,
        isAr ? 'دليلك الشامل في ذي قار' : 'Your complete guide in Dhi Qar');

  String searchHint(bool isAr) => _str(
        'search_hint_ar', 'search_hint_en', isAr,
        isAr ? 'بحث عن خدمة - احتياج' : 'Search for hospital, restaurant…');

  String aboutDescription(bool isAr) => _str(
        'about_description_ar', 'about_description_en', isAr,
        isAr
            ? 'دليلك الشامل لاكتشاف أفضل الخدمات والأماكن في ذي قار.'
            : 'Your comprehensive guide to discover services and places in Dhi Qar.');

  // ── Search & Discovery config ─────────────────────────────────────────────
  double get nearbyRadiusKm          => _dbl('search_nearby_radius_km',    10.0);
  int    get searchMinLength         => _int('search_min_length',           2);
  int    get searchResultsLimit      => _int('search_results_limit',        0);
  String get searchDefaultSort       => get('search_default_sort',          fallback: 'rating');
  bool   get searchShowDistanceFilter => _flag('search_show_distance_filter');

  // ── Profile field config ─────────────────────────────────────────────────
  // Values: 'required' | 'visible' | 'hidden'  (default: 'required')
  String _fieldCfg(String field) => get('profile_field_$field', fallback: 'required');
  bool isFieldVisible(String field)  => _fieldCfg(field) != 'hidden';
  bool isFieldRequired(String field) => _fieldCfg(field) == 'required';

  // ── Typography ────────────────────────────────────────────────────────────
  /// Global text scale multiplier (0.7–1.5). Applied via MediaQuery.textScaler
  /// in MaterialApp.builder so it affects ALL text in the app automatically.
  double get fontScale        => (_dbl('font_scale', 1.0)).clamp(0.7, 1.5);
  double get fontSizeHeading  => _dbl('font_size_heading',  24.0);
  double get fontSizeTitle    => _dbl('font_size_title',    18.0);
  double get fontSizeSubtitle => _dbl('font_size_subtitle', 16.0);
  double get fontSizeBody     => _dbl('font_size_body',     14.0);
  double get fontSizeCaption  => _dbl('font_size_caption',  12.0);
  double get fontSizeButton   => _dbl('font_size_button',   15.0);

  // ── Feature flags ────────────────────────────────────────────────────────
  bool _flag(String key) => get(key, fallback: 'true') != 'false';

  bool get featureReviews      => _flag('feature_reviews');
  bool get featureFavorites    => _flag('feature_favorites');
  bool get featureNearby       => _flag('feature_nearby');
  bool get featureMapPicker    => _flag('feature_map_picker');
  bool get featureGuestBrowsing => _flag('feature_guest_browsing');
  bool get featureSharing      => _flag('feature_sharing');
  bool get featureAddService       => _flag('feature_add_service');
  bool get featureServiceApproval  => _flag('feature_service_approval');

  // ── Fetch ─────────────────────────────────────────────────────────────────
  Future<void> fetchConfig() async {
    if (!_realtime.isChannelActive('app_config_all')) {
      _realtime.subscribeToAppConfig(onAnyChange: _reload);
    }
    if (_loaded) return;
    await _reload();
  }

  Future<void> _reload() async {
    try {
      final data = await Supabase.instance.client
          .from('app_config')
          .select('key, value');
      final map = <String, String>{};
      for (final row in data) {
        map[row['key'] as String] = (row['value'] as String?) ?? '';
      }
      _config = map;
      _loaded = true;
      notifyListeners();
      debugPrint('AppConfigProvider: loaded ${map.length} keys');
    } catch (e) {
      debugPrint('AppConfigProvider: fetch error $e');
    }
  }
}
