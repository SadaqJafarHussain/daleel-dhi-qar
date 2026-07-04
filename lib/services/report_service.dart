import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportService {
  final _client = Supabase.instance.client;

  Future<bool> submitReport({
    required String reporterId,
    required String targetType, // 'service' or 'review'
    required String targetId,
    required String reason,
  }) async {
    try {
      await _client.from('reports').insert({
        'reporter_id': reporterId,
        'target_type': targetType,
        'target_id': targetId,
        'reason': reason,
      });
      return true;
    } catch (e) {
      debugPrint('ReportService error: $e');
      return false;
    }
  }
}
