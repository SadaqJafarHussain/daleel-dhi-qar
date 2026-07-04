import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tour_guid/utils/app_texts_style.dart';
import 'package:tour_guid/utils/app_localization.dart';
import '../../models/user_model.dart';

// ── Wave clip at the bottom of the cover band ──────────────────────────────
class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(0, size.height - 28)
      ..quadraticBezierTo(
          size.width * 0.5, size.height + 12, size.width, size.height - 28)
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(_) => false;
}

// ────────────────────────────────────────────────────────────────────────────

class ProfileAppBar extends StatefulWidget {
  final double width;
  final double height;
  final UserModel? user;
  final String? userId;

  const ProfileAppBar({
    super.key,
    required this.width,
    required this.height,
    required this.user,
    this.userId,
  });

  @override
  State<ProfileAppBar> createState() => _ProfileAppBarState();
}

class _ProfileAppBarState extends State<ProfileAppBar> {
  bool _isVerified = false;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    if (widget.userId != null) {
      _fetchVerified();
      _subscribeToProfile();
    }
  }

  Future<void> _fetchVerified() async {
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('is_verified')
          .eq('id', widget.userId!)
          .maybeSingle();
      if (mounted) setState(() => _isVerified = data?['is_verified'] == true);
    } catch (_) {}
  }

  void _subscribeToProfile() {
    _channel = Supabase.instance.client
        .channel('appbar_profile_${widget.userId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'profiles',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: widget.userId!,
          ),
          callback: (payload) {
            if (mounted) {
              setState(
                () => _isVerified = payload.newRecord['is_verified'] == true,
              );
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.width;
    final h = widget.height;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).primaryColor;
    final name =
        widget.user?.name ?? AppLocalizations.of(context).t('guest');

    const double avatarRadius = 52.0;
    const double ringGap = 3.0;      // white ring width
    const double gradientRing = 3.0; // coloured gradient ring
    const double totalRingWidth = ringGap + gradientRing;
    final double coverHeight =
        MediaQuery.of(context).padding.top + h * 0.18;

    // Darker shade for the gradient ring
    final Color primaryDark = HSLColor.fromColor(primary)
        .withLightness(
          (HSLColor.fromColor(primary).lightness - 0.15).clamp(0.0, 1.0),
        )
        .toColor();

    return SliverToBoxAdapter(
      child: Column(
        children: [
          // ── Cover band ────────────────────────────────────────────────────
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // Clipped colour band
              ClipPath(
                clipper: _WaveClipper(),
                child: Container(
                  width: double.infinity,
                  height: coverHeight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primaryDark,
                        primary,
                      ],
                    ),
                  ),
                  // Subtle decorative circle in the top-right corner
                  child: Stack(
                    children: [
                      Positioned(
                        top: -30,
                        right: -30,
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.06),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        left: -20,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Avatar overlapping the wave ──────────────────────────────
              Positioned(
                bottom: -(avatarRadius + totalRingWidth),
                child: _buildAvatar(
                  w, primary, primaryDark, avatarRadius,
                  ringGap, gradientRing, isDark, name,
                ),
              ),
            ],
          ),

          // ── Space for the avatar overlap ─────────────────────────────────
          SizedBox(height: avatarRadius + totalRingWidth + 16),

          // ── Name + verified ───────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                  letterSpacing: 0.2,
                ),
              ),
              if (_isVerified) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.verified_rounded,
                  color: Color(0xFF3B82F6),
                  size: 22,
                ),
              ],
            ],
          ),

          const SizedBox(height: 8),

          // ── Phone + city chips ────────────────────────────────────────────
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            children: [
              if (widget.user?.phone != null &&
                  widget.user!.phone!.isNotEmpty)
                _infoChip(
                  Icons.phone_outlined,
                  widget.user!.phone!,
                  isDark,
                ),
              if (widget.user?.city != null &&
                  widget.user!.city!.isNotEmpty)
                _infoChip(
                  Icons.location_on_outlined,
                  _translateCity(context, widget.user!.city!),
                  isDark,
                ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Divider ───────────────────────────────────────────────────────
          Divider(
            height: 1,
            thickness: 1,
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(
    double w,
    Color primary,
    Color primaryDark,
    double avatarRadius,
    double ringGap,
    double gradientRing,
    bool isDark,
    String name,
  ) {
    final Widget avatarChild =
        widget.user?.avatarUrl != null && widget.user!.avatarUrl!.isNotEmpty
            ? CircleAvatar(
                radius: avatarRadius,
                backgroundImage: NetworkImage(widget.user!.avatarUrl!),
                onBackgroundImageError: (_, __) {},
              )
            : CircleAvatar(
                radius: avatarRadius,
                backgroundColor: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF0F9FF),
                child: Text(
                  _getInitials(name),
                  style: TextStyle(
                    fontSize: avatarRadius * 0.65,
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
              );

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, primaryDark],
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(gradientRing),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        padding: EdgeInsets.all(ringGap),
        child: avatarChild,
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 13,
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: AppTextSizes.bodySmall,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    return parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name.substring(0, name.length > 2 ? 2 : name.length).toUpperCase();
  }

  String _translateCity(BuildContext context, String city) {
    final loc = AppLocalizations.of(context);
    final translated = loc.t(city);
    return translated != city ? translated : city;
  }
}
