import 'package:flutter/material.dart';
import '../../../models/review_model.dart';
import '../../../utils/app_localization.dart';
import 'star_rating_display.dart';

/// Review Card Widget with modern design
class ReviewCard extends StatefulWidget {
  final Review review;
  final bool isOwn;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onHelpful;
  final VoidCallback? onReport;

  const ReviewCard({
    super.key,
    required this.review,
    this.isOwn = false,
    this.onEdit,
    this.onDelete,
    this.onHelpful,
    this.onReport,
  });

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _helpfulController;
  late Animation<double> _helpfulAnimation;
  bool _isHelpfulAnimating = false;

  static const int _maxLinesCollapsed = 3;
  static const int _expandableThreshold = 150;

  @override
  void initState() {
    super.initState();
    _helpfulController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _helpfulAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _helpfulController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _helpfulController.dispose();
    super.dispose();
  }

  void _handleHelpful() {
    if (_isHelpfulAnimating) return;

    setState(() {
      _isHelpfulAnimating = true;
    });

    _helpfulController.forward().then((_) {
      _helpfulController.reverse().then((_) {
        setState(() {
          _isHelpfulAnimating = false;
        });
      });
    });

    widget.onHelpful?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);
    final primaryColor = Theme.of(context).primaryColor;

    final isExpandable = widget.review.comment.length > _expandableThreshold;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: widget.isOwn
            ? Border.all(color: primaryColor.withOpacity(0.3), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
            child: Row(
              children: [
                // Avatar
                _buildAvatar(isDark, primaryColor),
                const SizedBox(width: 12),

                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.review.userName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.grey.shade900,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.isOwn) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                loc.t('your_review'),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          StarRatingDisplay.compact(
                            rating: widget.review.rating,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '•',
                            style: TextStyle(
                              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTimeAgo(widget.review.timeAgo, loc),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Actions menu
                if (widget.isOwn || widget.onReport != null)
                  _buildActionsMenu(isDark, loc, primaryColor),
              ],
            ),
          ),

          // Comment
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AnimatedCrossFade(
              firstChild: Text(
                widget.review.comment,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  height: 1.5,
                ),
                maxLines: _maxLinesCollapsed,
                overflow: TextOverflow.ellipsis,
              ),
              secondChild: Text(
                widget.review.comment,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ),

          // Show more/less button
          if (isExpandable)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 4),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Text(
                  _isExpanded ? loc.t('show_less') : loc.t('show_more'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),

          // Footer with helpful button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                // Helpful button
                _buildHelpfulButton(isDark, loc),

                if (widget.review.updatedAt != null) ...[
                  const Spacer(),
                  Text(
                    loc.t('edited'),
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isDark, Color primaryColor) {
    final avatarUrl = widget.review.userAvatar;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    // Generate gradient based on user name for fallback
    final colors = _getAvatarGradient(widget.review.userName);

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: hasAvatar ? null : LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (hasAvatar ? primaryColor : colors[0]).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: hasAvatar
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                avatarUrl,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to initials if image fails to load
                  return _buildInitialsAvatar(colors);
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          : _buildInitialsAvatar(colors),
    );
  }

  Widget _buildInitialsAvatar(List<Color> colors) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          widget.review.userInitials,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  List<Color> _getAvatarGradient(String name) {
    final gradients = [
      [const Color(0xFFFF6B6B), const Color(0xFFFF8E8E)],
      [const Color(0xFF4ECDC4), const Color(0xFF6EE7DE)],
      [const Color(0xFFA855F7), const Color(0xFFC084FC)],
      [const Color(0xFFF59E0B), const Color(0xFFFBBF24)],
      [const Color(0xFF3B82F6), const Color(0xFF60A5FA)],
      [const Color(0xFFEC4899), const Color(0xFFF472B6)],
      [const Color(0xFF10B981), const Color(0xFF34D399)],
      [const Color(0xFF8B5CF6), const Color(0xFFA78BFA)],
    ];

    final index = name.hashCode.abs() % gradients.length;
    return gradients[index];
  }

  Widget _buildActionsMenu(bool isDark, AppLocalizations loc, Color primaryColor) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert_rounded,
        color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isDark ? Colors.grey.shade800 : Colors.white,
      onSelected: (value) {
        switch (value) {
          case 'edit':
            widget.onEdit?.call();
            break;
          case 'delete':
            widget.onDelete?.call();
            break;
          case 'report':
            widget.onReport?.call();
            break;
        }
      },
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[];

        if (widget.isOwn) {
          if (widget.review.isEditable) {
            items.add(
              PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_rounded,
                      size: 20,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Text(loc.t('edit')),
                  ],
                ),
              ),
            );
          }
          items.add(
            PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    loc.t('delete'),
                    style: TextStyle(color: Colors.red.shade400),
                  ),
                ],
              ),
            ),
          );
        } else if (widget.onReport != null) {
          items.add(
            PopupMenuItem<String>(
              value: 'report',
              child: Row(
                children: [
                  Icon(
                    Icons.flag_outlined,
                    size: 20,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 12),
                  Text(loc.t('report')),
                ],
              ),
            ),
          );
        }

        return items;
      },
    );
  }

  Widget _buildHelpfulButton(bool isDark, AppLocalizations loc) {
    final isHelpful = widget.review.isHelpfulByMe;
    final helpfulCount = widget.review.helpfulCount;
    final primaryColor = Theme.of(context).primaryColor;

    return InkWell(
      onTap: widget.onHelpful != null ? _handleHelpful : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isHelpful
              ? primaryColor.withOpacity(0.1)
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isHelpful
                ? primaryColor.withOpacity(0.3)
                : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _helpfulAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _helpfulAnimation.value,
                  child: Icon(
                    isHelpful
                        ? Icons.thumb_up_rounded
                        : Icons.thumb_up_outlined,
                    size: 16,
                    color: isHelpful
                        ? primaryColor
                        : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                  ),
                );
              },
            ),
            const SizedBox(width: 6),
            Text(
              helpfulCount > 0 ? '$helpfulCount' : loc.t('helpful'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isHelpful
                    ? primaryColor
                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(String timeAgo, AppLocalizations loc) {
    // Parse time ago format from model
    if (timeAgo.contains(':')) {
      final parts = timeAgo.split(':');
      final key = parts[0];
      final value = parts.length > 1 ? parts[1] : '';
      return loc.t(key).replaceAll('{n}', value);
    }
    return loc.t(timeAgo);
  }
}

/// Skeleton loader for ReviewCard
class ReviewCardSkeleton extends StatelessWidget {
  const ReviewCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shimmerColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    final baseColor = isDark ? Colors.grey.shade900 : Colors.white;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar skeleton
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 100,
                      height: 14,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 140,
                      height: 12,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 12,
            decoration: BoxDecoration(
              color: shimmerColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 12,
            decoration: BoxDecoration(
              color: shimmerColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 200,
            height: 12,
            decoration: BoxDecoration(
              color: shimmerColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
