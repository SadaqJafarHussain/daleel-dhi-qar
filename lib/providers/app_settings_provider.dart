import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/realtime_service.dart';

/// Fetches admin-configurable app content from the `lookups` table
/// (type = 'home_content'). Falls back to localization strings if not loaded.
///
/// Required DB rows (run once in Supabase):
/// INSERT INTO lookups (type, key, label_ar, label_en, sort_order, active) VALUES
///   ('home_content', 'home_title',    'كل الأقسام',                           'All Categories',                              1, true),
///   ('home_content', 'home_subtitle', 'اكتشف أفضل الخدمات والأماكن', 'Discover the best services and places', 2, true);
class AppSettingsProvider extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService();
  final RealtimeService _realtime = RealtimeService();

  final Map<String, Map<String, String>> _settings = {};
  bool isLoading = false;
  bool _loaded = false;

  Future<void> fetchSettings() async {
    // Always ensure realtime subscription is active
    if (_supabase.isInitialized && !_realtime.isChannelActive('lookups_all')) {
      _realtime.subscribeToLookups(onAnyChange: _reloadFromServer);
    }

    if (_loaded || isLoading) return;
    isLoading = true;

    try {
      if (_supabase.isInitialized) {
        final data = await _supabase.client
            .from('lookups')
            .select('key, label_ar, label_en')
            .eq('type', 'home_content')
            .eq('active', true)
            .order('sort_order');

        _applyData(data);
        _loaded = true;
        debugPrint('AppSettingsProvider: loaded ${_settings.length} settings');
      }
    } catch (e) {
      debugPrint('AppSettingsProvider: fetch error: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  void _applyData(List<Map<String, dynamic>> data) {
    _settings.clear();
    for (final row in data) {
      final key = row['key'] as String? ?? '';
      if (key.isEmpty) continue;
      _settings[key] = {
        'ar': row['label_ar'] as String? ?? '',
        'en': row['label_en'] as String? ?? '',
      };
    }
  }

  Future<void> _reloadFromServer() async {
    try {
      if (_supabase.isInitialized) {
        final data = await _supabase.client
            .from('lookups')
            .select('key, label_ar, label_en')
            .eq('type', 'home_content')
            .eq('active', true)
            .order('sort_order');

        _applyData(data);
        debugPrint('AppSettingsProvider: realtime reload — ${_settings.length} settings');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('AppSettingsProvider: realtime reload error: $e');
    }
  }

  /// Returns the localized value for [key], or null if not yet loaded.
  String? getLabel(String key, {bool isAr = true}) {
    final entry = _settings[key];
    if (entry == null) return null;
    final val = isAr ? entry['ar'] : entry['en'];
    return (val != null && val.isNotEmpty) ? val : null;
  }

  @override
  void dispose() {
    _realtime.unsubscribeFromLookups();
    super.dispose();
  }
}
