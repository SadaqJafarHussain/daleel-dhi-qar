import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/review_model.dart';
import '../../../utils/app_localization.dart';
import 'star_rating_input.dart';

/// Bottom sheet for adding or editing reviews
class AddReviewSheet extends StatefulWidget {
  final String serviceName;
  final Review? existingReview;
  final Future<bool> Function({
    required double rating,
    required String comment,
  }) onSubmit;
  final VoidCallback? onDelete;
  final bool canDelete;

  const AddReviewSheet({
    super.key,
    required this.serviceName,
    this.existingReview,
    required this.onSubmit,
    this.onDelete,
    this.canDelete = false,
  });

  /// Show the bottom sheet
  static Future<bool?> show({
    required BuildContext context,
    required String serviceName,
    Review? existingReview,
    required Future<bool> Function({
      required double rating,
      required String comment,
    }) onSubmit,
    VoidCallback? onDelete,
    bool canDelete = false,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddReviewSheet(
        serviceName: serviceName,
        existingReview: existingReview,
        onSubmit: onSubmit,
        onDelete: onDelete,
        canDelete: canDelete,
      ),
    );
  }

  @override
  State<AddReviewSheet> createState() => _AddReviewSheetState();
}

class _AddReviewSheetState extends State<AddReviewSheet> {
  late TextEditingController _commentController;
  late double _rating;
  bool _isSubmitting = false;
  String? _errorMessage;

  static const int _minLength = 10;
  static const int _maxLength = 1000;

  bool get _isEditing => widget.existingReview != null;

  @override
  void initState() {
    super.initState();
    _rating = widget.existingReview?.rating ?? 0;
    _commentController = TextEditingController(
      text: widget.existingReview?.comment ?? '',
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  bool get _isValid {
    final comment = _commentController.text.trim();
    return _rating > 0 &&
        comment.length >= _minLength &&
        comment.length <= _maxLength;
  }

  String? _getValidationError(AppLocalizations loc) {
    if (_rating <= 0) {
      return loc.t('please_select_rating');
    }
    final comment = _commentController.text.trim();
    if (comment.length < _minLength) {
      return loc.t('comment_too_short');
    }
    if (comment.length > _maxLength) {
      return loc.t('comment_too_long');
    }
    return null;
  }

  Future<void> _handleSubmit() async {
    final loc = AppLocalizations.of(context);
    final error = _getValidationError(loc);

    if (error != null) {
      setState(() {
        _errorMessage = error;
      });
      HapticFeedback.lightImpact();
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final success = await widget.onSubmit(
        rating: _rating,
        comment: _commentController.text.trim(),
      );

      if (success && mounted) {
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop(true);
      } else if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = loc.t('review_submit_failed');
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = loc.t('review_submit_failed');
        });
      }
    }
  }

  void _handleDelete() {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(loc.t('delete_review')),
        content: Text(loc.t('delete_review_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.t('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete?.call();
              Navigator.pop(this.context, true);
            },
            child: Text(
              loc.t('delete'),
              style: TextStyle(color: Colors.red.shade400),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);
    final primaryColor = Theme.of(context).primaryColor;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                // Icon with gradient background
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, primaryColor.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.rate_review_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEditing ? loc.t('edit_review') : loc.t('write_review'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey.shade900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.serviceName,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Close button
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),

          // Content
          Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 20 + bottomPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Rating section
                Text(
                  loc.t('how_would_you_rate'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                StarRatingInput(
                  initialRating: _rating,
                  onRatingChanged: (rating) {
                    setState(() {
                      _rating = rating;
                      _errorMessage = null;
                    });
                  },
                  starSize: 48,
                  allowHalfStar: true,
                  showLabel: true,
                  enableHaptics: true,
                ),
                const SizedBox(height: 28),

                // Comment section
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _errorMessage != null
                          ? Colors.red.shade300
                          : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _commentController,
                        maxLines: 4,
                        maxLength: _maxLength,
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark ? Colors.white : Colors.grey.shade900,
                        ),
                        decoration: InputDecoration(
                          hintText: loc.t('write_your_review'),
                          hintStyle: TextStyle(
                            color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                          counterText: '',
                        ),
                        onChanged: (_) {
                          setState(() {
                            _errorMessage = null;
                          });
                        },
                      ),
                      // Character counter
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${loc.t('min_characters')}: $_minLength',
                              style: TextStyle(
                                fontSize: 11,
                                color: _commentController.text.trim().length < _minLength
                                    ? Colors.orange.shade400
                                    : (isDark ? Colors.grey.shade500 : Colors.grey.shade500),
                              ),
                            ),
                            Text(
                              '${_commentController.text.length}/$_maxLength',
                              style: TextStyle(
                                fontSize: 11,
                                color: _commentController.text.length > _maxLength
                                    ? Colors.red.shade400
                                    : (isDark ? Colors.grey.shade500 : Colors.grey.shade500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Error message
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 18,
                          color: Colors.red.shade400,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Action buttons
                Row(
                  children: [
                    // Delete button (if editing and can delete)
                    if (_isEditing && widget.canDelete)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isSubmitting ? null : _handleDelete,
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.red.shade400,
                          ),
                          label: Text(
                            loc.t('delete'),
                            style: TextStyle(color: Colors.red.shade400),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.red.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    if (_isEditing && widget.canDelete)
                      const SizedBox(width: 12),

                    // Submit button
                    Expanded(
                      flex: _isEditing && widget.canDelete ? 2 : 1,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isEditing
                                    ? loc.t('update_review')
                                    : loc.t('submit_review'),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
