import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Reusable image widget with grey logo placeholder
/// Shows grey logo during loading and on error
class ServiceImageWidget extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool showLoadingIndicator;

  const ServiceImageWidget({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.showLoadingIndicator = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _buildPlaceholder(context);
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => _buildPlaceholder(
        context,
        showLoading: showLoadingIndicator,
      ),
      errorWidget: (context, url, error) => _buildPlaceholder(context),
    );
  }

  Widget _buildPlaceholder(BuildContext context, {bool showLoading = false}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade300,
            Colors.grey.shade400,
          ],
        ),
        borderRadius: borderRadius,
      ),
      child: Stack(
        children: [
          // Grey logo
          Center(
            child: ColorFiltered(
              colorFilter: const ColorFilter.matrix([
                0.2126, 0.7152, 0.0722, 0, 0, // Red channel
                0.2126, 0.7152, 0.0722, 0, 0, // Green channel
                0.2126, 0.7152, 0.0722, 0, 0, // Blue channel
                0, 0, 0, 1, 0, // Alpha channel
              ]),
              child: Opacity(
                opacity: 0.3,
                child: Image.asset(
                  'assets/images/splash_logo.png',
                  width: width != null ? width! * 0.4 : 80,
                  height: height != null ? height! * 0.4 : 80,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback if logo asset is missing
                    return Icon(
                      Icons.image_outlined,
                      size: width != null ? width! * 0.3 : 60,
                      color: Colors.grey.shade500,
                    );
                  },
                ),
              ),
            ),
          ),
          // Loading indicator (optional)
          if (showLoading)
            Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Simple placeholder builder function (for non-CachedNetworkImage cases)
Widget buildImagePlaceholder({
  required BuildContext context,
  double? width,
  double? height,
  bool showLoading = false,
}) {
  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.grey.shade300,
          Colors.grey.shade400,
        ],
      ),
    ),
    child: Stack(
      children: [
        // Grey logo
        Center(
          child: ColorFiltered(
            colorFilter: const ColorFilter.matrix([
              0.2126, 0.7152, 0.0722, 0, 0, // Red channel
              0.2126, 0.7152, 0.0722, 0, 0, // Green channel
              0.2126, 0.7152, 0.0722, 0, 0, // Blue channel
              0, 0, 0, 1, 0, // Alpha channel
            ]),
            child: Opacity(
              opacity: 0.3,
              child: Image.asset(
                'assets/images/splash_logo.png',
                width: width != null ? width * 0.4 : 80,
                height: height != null ? height * 0.4 : 80,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.image_outlined,
                    size: width != null ? width * 0.3 : 60,
                    color: Colors.grey.shade500,
                  );
                },
              ),
            ),
          ),
        ),
        // Loading indicator (optional)
        if (showLoading)
          Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ),
      ],
    ),
  );
}