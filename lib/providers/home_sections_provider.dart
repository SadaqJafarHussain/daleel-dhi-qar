import 'package:flutter/material.dart';
import '../models/home_section_model.dart';
import '../services/supabase_service.dart';
import '../services/realtime_service.dart';

class HomeSectionsProvider extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService();
  final RealtimeService _realtime = RealtimeService();

  List<HomeSection> _sections = [];
  bool isLoading = false;
  bool _loaded = false;

  List<HomeSection> get sections => _sections;

  Future<void> fetchSections() async {
    // Always ensure realtime subscription is active
    if (_supabase.isInitialized && !_realtime.isChannelActive('home_sections_all')) {
      _realtime.subscribeToHomeSections(onAnyChange: _reloadFromServer);
    }

    if (_loaded || isLoading) return;
    isLoading = true;

    try {
      if (_supabase.isInitialized) {
        final data = await _supabase.client
            .from('home_sections')
            .select()
            .eq('active', true)
            .order('sort_order');

        _sections = (data as List).map((j) => HomeSection.fromJson(j)).toList();
        _loaded = true;
        debugPrint('HomeSectionsProvider: loaded ${_sections.length} sections');
      }
    } catch (e) {
      debugPrint('HomeSectionsProvider: fetch error: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> _reloadFromServer() async {
    try {
      if (_supabase.isInitialized) {
        final data = await _supabase.client
            .from('home_sections')
            .select()
            .eq('active', true)
            .order('sort_order');

        _sections = (data as List).map((j) => HomeSection.fromJson(j)).toList();
        debugPrint('HomeSectionsProvider: realtime reload — ${_sections.length} sections');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('HomeSectionsProvider: realtime reload error: $e');
    }
  }

  @override
  void dispose() {
    _realtime.unsubscribeFromHomeSections();
    super.dispose();
  }
}
