import 'package:flutter/material.dart';
import '../../services/report_service.dart';
import '../../utils/app_localization.dart';

/// Reasons available for both service and review reports.
const _serviceReasons = [
  ('wrong_info',    'معلومات خاطئة / Wrong info'),
  ('inappropriate', 'محتوى غير لائق / Inappropriate'),
  ('closed',        'المكان مغلق / Permanently closed'),
  ('spam',          'إعلان مزيف / Spam'),
  ('other',         'أخرى / Other'),
];

const _reviewReasons = [
  ('fake_review',   'تقييم مزيف / Fake review'),
  ('inappropriate', 'محتوى غير لائق / Inappropriate'),
  ('spam',          'إعلان مزيف / Spam'),
  ('other',         'أخرى / Other'),
];

/// Shows a bottom sheet for reporting a service or review.
/// [targetType]: 'service' or 'review'
/// [targetId]: ID of the reported item (as String)
/// [reporterId]: Supabase UUID of the current user
Future<void> showReportSheet(
  BuildContext context, {
  required String targetType,
  required String targetId,
  required String reporterId,
}) async {
  final loc = AppLocalizations.of(context);
  final reasons = targetType == 'review' ? _reviewReasons : _serviceReasons;
  String? selected;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => Padding(
        padding: EdgeInsets.fromLTRB(
          20, 20, 20,
          20 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              targetType == 'review'
                  ? loc.t('report_review')
                  : loc.t('report_service'),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              loc.t('report_select_reason'),
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ...reasons.map((r) => RadioListTile<String>(
              value: r.$1,
              groupValue: selected,
              title: Text(r.$2, style: const TextStyle(fontSize: 14)),
              onChanged: (v) => setState(() => selected = v),
              contentPadding: EdgeInsets.zero,
              dense: true,
              activeColor: Theme.of(ctx).primaryColor,
            )),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selected == null
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        final ok = await ReportService().submitReport(
                          reporterId: reporterId,
                          targetType: targetType,
                          targetId: targetId,
                          reason: selected!,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ok
                                  ? loc.t('report_sent')
                                  : loc.t('report_failed')),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                child: Text(loc.t('report')),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}
