import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/review_model.dart';
import '../../../models/service_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/review_provider.dart';
import '../../../utils/app_localization.dart';
import 'add_review_sheet.dart';
import 'rating_breakdown.dart';
import 'review_card.dart';
import 'star_rating_display.dart';

/// Complete reviews section for service details page
class ReviewsSection extends StatefulWidget {
  final Service service;
  final int? currentUserId;
  final bool isLoggedIn;
  final VoidCallback? onLoginRequired;

  const ReviewsSection({
    super.key,
    required this.service,
    this.currentUserId,
    this.isLoggedIn = false,
    this.onLoginRequired,
  });

  @override
  State<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<ReviewsSection> {
  bool _showBreakdown = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  void _loadReviews() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReviewProvider>().fetchReviews(
            widget.service.id,
            userId: widget.currentUserId,
          );
    });
  }

  void _openAddReviewSheet({Review? existingReview}) {
    if (!widget.isLoggedIn) {
      widget.onLoginRequired?.call();
      return;
    }

    final provider = context.read<ReviewProvider>();
    final authProvider = context.read<AuthProvider>();
    final supabaseUserId = authProvider.supabaseUserId;

    // Check rate limiting
    if (existingReview == null && !provider.canSubmitNow()) {
      final timeLeft = provider.getTimeUntilCanSubmit();
      if (timeLeft != null) {
        _showRateLimitError(timeLeft);
        return;
      }
    }

    AddReviewSheet.show(
      context: context,
      serviceName: widget.service.title,
      existingReview: existingReview,
      onSubmit: ({required double rating, required String comment}) async {
        if (existingReview != null) {
          return provider.updateReview(
            reviewId: existingReview.id,
            serviceId: widget.service.id,
            userId: widget.currentUserId!,
            rating: rating,
            comment: comment,
            supabaseUserId: supabaseUserId,
          );
        } else {
          return provider.submitReview(
            serviceId: widget.service.id,
            userId: widget.currentUserId!,
            rating: rating,
            comment: comment,
            supabaseUserId: supabaseUserId,
          );
        }
      },
      onDelete: existingReview != null
          ? () {
              provider.deleteReview(
                reviewId: existingReview.id,
                serviceId: widget.service.id,
                userId: widget.currentUserId!,
                supabaseUserId: supabaseUserId,
              );
            }
          : null,
      canDelete: existingReview != null,
    );
  }

  void _showRateLimitError(Duration timeLeft) {
    final loc = AppLocalizations.of(context);
    final seconds = timeLeft.inSeconds;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          loc.t('rate_limit_wait').replaceAll('{seconds}', seconds.toString()),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);
    final primaryColor = Theme.of(context).primaryColor;

    return Consumer<ReviewProvider>(
      builder: (context, provider, child) {
        final reviews = provider.getReviews(widget.service.id);
        final stats = provider.getStats(widget.service.id);
        final userReview = provider.getUserReview(widget.service.id);
        final isLoading = provider.isLoading;
        final hasReviews = reviews.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            _buildSectionHeader(loc, isDark, primaryColor),
            const SizedBox(height: 16),

            // Loading state
            if (isLoading && !hasReviews) ...[
              const ReviewCardSkeleton(),
              const ReviewCardSkeleton(),
            ]
            // Empty state
            else if (!hasReviews)
              _buildEmptyState(loc, isDark, primaryColor)
            // Content
            else ...[
              // Rating breakdown (collapsible)
              if (stats != null) ...[
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showBreakdown = !_showBreakdown;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                StarRatingDisplay.standard(
                                  rating: stats.averageRating,
                                  reviewCount: stats.totalReviews,
                                ),
                              ],
                            ),
                            Icon(
                              _showBreakdown
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: isDark
                                  ? Colors.grey.shade500
                                  : Colors.grey.shade600,
                            ),
                          ],
                        ),
                        AnimatedCrossFade(
                          firstChild: const SizedBox.shrink(),
                          secondChild: Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: RatingBreakdown(
                              stats: stats,
                              animate: true,
                            ),
                          ),
                          crossFadeState: _showBreakdown
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 200),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Write/Edit review button
              _buildReviewButton(
                loc: loc,
                isDark: isDark,
                primaryColor: primaryColor,
                userReview: userReview,
              ),
              const SizedBox(height: 16),

              // Reviews list
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reviews.length,
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  final isOwn = review.userId == widget.currentUserId;

                  return ReviewCard(
                    review: review,
                    isOwn: isOwn,
                    onEdit: isOwn && review.isEditable
                        ? () => _openAddReviewSheet(existingReview: review)
                        : null,
                    onDelete: isOwn
                        ? () => _confirmDelete(review, provider, loc)
                        : null,
                    onHelpful: widget.isLoggedIn && !isOwn
                        ? () {
                            final authProvider = context.read<AuthProvider>();
                            provider.toggleHelpful(
                              reviewId: review.id,
                              serviceId: widget.service.id,
                              userId: widget.currentUserId!,
                              supabaseUserId: authProvider.supabaseUserId,
                            );
                          }
                        : null,
                    onReport: widget.isLoggedIn && !isOwn
                        ? () => _showReportDialog(loc)
                        : null,
                  );
                },
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(
      AppLocalizations loc, bool isDark, Color primaryColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, primaryColor.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.reviews_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          loc.t('reviews'),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.grey.shade900,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(
      AppLocalizations loc, bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.grey.shade900,
                  Colors.grey.shade900.withOpacity(0.8),
                ]
              : [
                  primaryColor.withOpacity(0.05),
                  Colors.white,
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.grey.shade800
              : primaryColor.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(isDark ? 0.05 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Animated stars decoration
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final delay = index * 0.1;
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 500 + (index * 100)),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.star_rounded,
                        size: 28 - (index == 2 ? 0 : (index - 2).abs() * 4),
                        color: index == 2
                            ? const Color(0xFFFBBF24)
                            : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
          const SizedBox(height: 20),

          // Main icon with gradient background
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor,
                  primaryColor.withOpacity(0.7),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.rate_review_rounded,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            loc.t('no_reviews_yet'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.grey.shade900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            loc.t('be_first_to_review'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // CTA Button with animation
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.95, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: child,
              );
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () => _openAddReviewSheet(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.star_rounded, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      loc.t('write_review'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewButton({
    required AppLocalizations loc,
    required bool isDark,
    required Color primaryColor,
    Review? userReview,
  }) {
    final hasReviewed = userReview != null;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _openAddReviewSheet(
          existingReview: hasReviewed ? userReview : null,
        ),
        icon: Icon(
          hasReviewed ? Icons.edit_rounded : Icons.rate_review_rounded,
          size: 18,
        ),
        label: Text(
          hasReviewed ? loc.t('edit_your_review') : loc.t('write_review'),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: primaryColor.withOpacity(0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(Review review, ReviewProvider provider, AppLocalizations loc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = context.read<AuthProvider>();

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
              provider.deleteReview(
                reviewId: review.id,
                serviceId: widget.service.id,
                userId: widget.currentUserId!,
                supabaseUserId: authProvider.supabaseUserId,
              );
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

  void _showReportDialog(AppLocalizations loc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(loc.t('report_review')),
        content: Text(loc.t('report_review_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.t('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(
                  content: Text(loc.t('review_reported')),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            child: Text(loc.t('report')),
          ),
        ],
      ),
    );
  }
}

/// Compact rating display for service cards
class ServiceRatingBadge extends StatelessWidget {
  final double? rating;
  final int? reviewCount;

  const ServiceRatingBadge({
    super.key,
    this.rating,
    this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    if (rating == null || rating == 0) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withOpacity(0.6)
            : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_rounded,
            size: 14,
            color: Color(0xFFFBBF24),
          ),
          const SizedBox(width: 4),
          Text(
            rating!.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.grey.shade900,
            ),
          ),
          if (reviewCount != null && reviewCount! > 0) ...[
            Text(
              ' (${_formatCount(reviewCount!)})',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
