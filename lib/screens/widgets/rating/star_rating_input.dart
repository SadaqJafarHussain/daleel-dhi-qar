import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Interactive Star Rating Input with half-star support and animations
class StarRatingInput extends StatefulWidget {
  final double initialRating;
  final ValueChanged<double> onRatingChanged;
  final double starSize;
  final bool allowHalfStar;
  final bool showLabel;
  final bool enableHaptics;
  final Color? activeColor;
  final Color? inactiveColor;

  const StarRatingInput({
    super.key,
    this.initialRating = 0,
    required this.onRatingChanged,
    this.starSize = 44,
    this.allowHalfStar = true,
    this.showLabel = true,
    this.enableHaptics = true,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  State<StarRatingInput> createState() => _StarRatingInputState();
}

class _StarRatingInputState extends State<StarRatingInput>
    with TickerProviderStateMixin {
  late double _currentRating;
  late List<AnimationController> _scaleControllers;
  late List<Animation<double>> _scaleAnimations;
  late AnimationController _particleController;
  bool _showParticles = false;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;

    // Scale animations for each star
    _scaleControllers = List.generate(5, (index) {
      return AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      );
    });

    _scaleAnimations = _scaleControllers.map((controller) {
      return Tween<double>(begin: 1.0, end: 1.3).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
      );
    }).toList();

    // Particle animation for 5-star celebration
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  @override
  void dispose() {
    for (final controller in _scaleControllers) {
      controller.dispose();
    }
    _particleController.dispose();
    super.dispose();
  }

  void _updateRating(double rating) {
    if (rating != _currentRating) {
      setState(() {
        _currentRating = rating;
      });

      // Haptic feedback
      if (widget.enableHaptics) {
        HapticFeedback.lightImpact();
      }

      // Animate selected star
      final starIndex = (rating - 0.5).floor();
      if (starIndex >= 0 && starIndex < 5) {
        _scaleControllers[starIndex].forward().then((_) {
          _scaleControllers[starIndex].reverse();
        });
      }

      // Particle effect for 5 stars
      if (rating == 5.0) {
        setState(() {
          _showParticles = true;
        });
        _particleController.forward(from: 0).then((_) {
          if (mounted) {
            setState(() {
              _showParticles = false;
            });
          }
        });
        if (widget.enableHaptics) {
          HapticFeedback.mediumImpact();
        }
      }

      widget.onRatingChanged(rating);
    }
  }

  double _calculateRating(Offset localPosition, double starWidth, bool isRTL) {
    final totalWidth = starWidth * 5;

    // In RTL, we need to flip the position calculation
    double effectiveX = isRTL ? (totalWidth - localPosition.dx) : localPosition.dx;

    final starIndex = (effectiveX / starWidth).floor();
    final positionInStar = effectiveX - (starIndex * starWidth);

    // In RTL, the half-star logic is also reversed within each star
    final isHalfStar = isRTL
        ? positionInStar > starWidth / 2  // In RTL, right side of star is the "first half"
        : positionInStar < starWidth / 2;

    double rating;
    if (widget.allowHalfStar && isHalfStar) {
      rating = starIndex + 0.5;
    } else {
      rating = (starIndex + 1).toDouble();
    }

    return rating.clamp(0.5, 5.0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    final activeColor = widget.activeColor ?? const Color(0xFFFBBF24);
    final inactiveColor = widget.inactiveColor ??
        (isDark ? Colors.grey.shade700 : Colors.grey.shade300);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Stars with gesture detection
        Stack(
          alignment: Alignment.center,
          children: [
            // Particle effects
            if (_showParticles)
              AnimatedBuilder(
                animation: _particleController,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(widget.starSize * 5 + 40, widget.starSize + 40),
                    painter: _ParticlePainter(
                      progress: _particleController.value,
                      color: activeColor,
                    ),
                  );
                },
              ),

            // Stars row
            GestureDetector(
              onTapDown: (details) {
                final rating = _calculateRating(
                  details.localPosition,
                  widget.starSize + 8,
                  isRTL,
                );
                _updateRating(rating);
              },
              onHorizontalDragUpdate: (details) {
                final rating = _calculateRating(
                  details.localPosition,
                  widget.starSize + 8,
                  isRTL,
                );
                _updateRating(rating);
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  return AnimatedBuilder(
                    animation: _scaleAnimations[index],
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimations[index].value,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _buildStar(
                            index: index,
                            activeColor: activeColor,
                            inactiveColor: inactiveColor,
                            isRTL: isRTL,
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ),
          ],
        ),

        // Rating label
        if (widget.showLabel) ...[
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Text(
              _getRatingLabel(_currentRating),
              key: ValueKey(_getRatingLabel(_currentRating)),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _currentRating > 0
                    ? _getRatingLabelColor(_currentRating, isDark)
                    : (isDark ? Colors.grey.shade500 : Colors.grey.shade400),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStar({
    required int index,
    required Color activeColor,
    required Color inactiveColor,
    required bool isRTL,
  }) {
    final fillAmount = (_currentRating - index).clamp(0.0, 1.0);

    return SizedBox(
      width: widget.starSize,
      height: widget.starSize,
      child: Stack(
        children: [
          // Background star (outline)
          Icon(
            Icons.star_rounded,
            size: widget.starSize,
            color: inactiveColor,
          ),
          // Filled portion
          if (fillAmount > 0)
            ClipRect(
              clipper: _StarClipper(fillAmount, isRTL: isRTL),
              child: ShaderMask(
                shaderCallback: (bounds) {
                  return LinearGradient(
                    colors: [
                      activeColor,
                      activeColor.withOpacity(0.9),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ).createShader(bounds);
                },
                child: Icon(
                  Icons.star_rounded,
                  size: widget.starSize,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getRatingLabel(double rating) {
    if (rating <= 0) return 'Tap to rate';
    if (rating <= 1) return 'Poor';
    if (rating <= 2) return 'Fair';
    if (rating <= 3) return 'Good';
    if (rating <= 4) return 'Very Good';
    return 'Excellent!';
  }

  Color _getRatingLabelColor(double rating, bool isDark) {
    if (rating <= 1) return Colors.red.shade400;
    if (rating <= 2) return Colors.orange.shade400;
    if (rating <= 3) return Colors.amber.shade600;
    if (rating <= 4) return Colors.lime.shade600;
    return Colors.green.shade500;
  }
}

/// Clipper for partial star fill
class _StarClipper extends CustomClipper<Rect> {
  final double fillAmount;
  final bool isRTL;

  _StarClipper(this.fillAmount, {this.isRTL = false});

  @override
  Rect getClip(Size size) {
    if (isRTL) {
      // In RTL, clip from the right side
      final clipWidth = size.width * fillAmount;
      return Rect.fromLTWH(size.width - clipWidth, 0, clipWidth, size.height);
    }
    // LTR: clip from the left side
    return Rect.fromLTWH(0, 0, size.width * fillAmount, size.height);
  }

  @override
  bool shouldReclip(_StarClipper oldClipper) =>
      fillAmount != oldClipper.fillAmount || isRTL != oldClipper.isRTL;
}

/// Custom painter for celebration particles
class _ParticlePainter extends CustomPainter {
  final double progress;
  final Color color;
  final int particleCount = 20;
  final math.Random _random = math.Random(42);

  _ParticlePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * 2 * math.pi + _random.nextDouble() * 0.5;
      final distance = 20 + progress * (60 + _random.nextDouble() * 40);
      final particleSize = (1 - progress) * (3 + _random.nextDouble() * 4);

      final offset = Offset(
        center.dx + math.cos(angle) * distance,
        center.dy + math.sin(angle) * distance - progress * 20,
      );

      paint.color = color.withOpacity((1 - progress) * 0.8);
      canvas.drawCircle(offset, particleSize, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => progress != oldDelegate.progress;
}

/// Compact inline rating input for quick selection
class CompactRatingInput extends StatefulWidget {
  final double initialRating;
  final ValueChanged<double> onRatingChanged;
  final double size;

  const CompactRatingInput({
    super.key,
    this.initialRating = 0,
    required this.onRatingChanged,
    this.size = 28,
  });

  @override
  State<CompactRatingInput> createState() => _CompactRatingInputState();
}

class _CompactRatingInputState extends State<CompactRatingInput> {
  late double _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    const activeColor = Color(0xFFFBBF24);
    final inactiveColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        // In RTL, star index 0 is visually on the right, so we need to reverse the fill logic
        // The visual order is automatically handled by Flutter's Row in RTL
        // But we keep the logical order the same (star 0 = 1 rating, star 4 = 5 rating)
        final isFilled = index < _rating;
        return GestureDetector(
          onTap: () {
            setState(() {
              _rating = (index + 1).toDouble();
            });
            widget.onRatingChanged(_rating);
            HapticFeedback.selectionClick();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: AnimatedScale(
              scale: isFilled ? 1.0 : 0.9,
              duration: const Duration(milliseconds: 150),
              child: Icon(
                isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                size: widget.size,
                color: isFilled ? activeColor : inactiveColor,
              ),
            ),
          ),
        );
      }),
    );
  }
}
