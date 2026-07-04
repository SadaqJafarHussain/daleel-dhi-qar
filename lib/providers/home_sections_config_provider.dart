import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/home_section_config_model.dart';
import '../services/realtime_service.dart';

/// Provides the admin-controlled home screen layout config from `home_sections_config`.
/// Each row controls visibility, order, and title of a built-in home section.
class HomeSectionsConfigProvider extends ChangeNotifier {
  final RealtimeService _realtime = RealtimeService();

  List<HomeSectionConfig> _configs = [];
  bool _loaded = false;

  /// Sorted by sort_order, all entries (visible + hidden).
  List<HomeSectionConfig> get configs => _configs;

  /// Only visible entries, sorted by sort_order.
  List<HomeSectionConfig> get visibleConfigs =>
      _configs.where((c) => c.visible).toList();

  /// Look up a single config by key, or null if not yet loaded.
  HomeSectionConfig? configFor(String key) {
    try {
      return _configs.firstWhere((c) => c.key == key);
    } catch (_) {
      return null;
    }
  }

  /// Returns true if the section should be shown (visible and exists in config).
  /// Defaults to true if config not yet loaded, so nothing disappears on first load.
  bool isVisible(String key) => configFor(key)?.visible ?? true;

  Future<void> fetchConfigs() async {
    if (!_realtime.isChannelActive('home_sections_config_all')) {
      _realtime.subscribeToHomeSectionsConfig(onAnyChange: _reload);
    }
    if (_loaded) return;
    await _reload();
  }

  /// Force reload from DB (e.g. on pull-to-refresh).
  Future<void> forceReload() => _reload();

  Future<void> _reload() async {
    try {
      final data = await Supabase.instance.client
          .from('home_sections_config')
          .select()
          .order('sort_order', ascending: true);

      _configs = (data as List)
          .map((j) => HomeSectionConfig.fromJson(j))
          .toList();
      _loaded = true;
      notifyListeners();
      debugPrint('HomeSectionsConfigProvider: loaded ${_configs.length} configs');
    } catch (e) {
      debugPrint('HomeSectionsConfigProvider: fetch error: $e');
    }
  }

  @override
  void dispose() {
    _realtime.unsubscribeFromHomeSectionsConfig();
    super.dispose();
  }
}
