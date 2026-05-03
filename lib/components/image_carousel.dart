import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

/// Image Carousel Component.
///
/// Displays images with smooth page transitions, navigation arrows,
/// and animated dot indicators. Supports error retry on failed images.
///
/// Example usage:
/// ```dart
/// ImageCarousel(
///   images: ['https://example.com/1.jpg', 'https://example.com/2.jpg'],
///   height: 300,
///   borderRadius: BorderRadius.circular(16),
/// )
/// ```
class ImageCarousel extends StatefulWidget {
  final List<String> images;
  final double height;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final bool showIndicators;
  final bool autoPlay;
  final Duration autoPlayDuration;

  const ImageCarousel({
    super.key,
    required this.images,
    this.height = 350,
    this.borderRadius,
    this.placeholder,
    this.showIndicators = true,
    this.autoPlay = false,
    this.autoPlayDuration = const Duration(seconds: 3),
  });

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  final Map<String, int> _imageReloadKeys = {};
  final Map<String, bool> _imageErrorStates = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // If no images, show placeholder.
    if (widget.images.isEmpty) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: widget.borderRadius,
        ),
        child:
            widget.placeholder ??
            Center(
              child: Icon(
                IconlyBroken.image,
                size: 80,
                color: theme.colorScheme.primary.withValues(alpha: 0.4),
              ),
            ),
      );
    }

    return Container(
      height: widget.height,
      decoration: BoxDecoration(borderRadius: widget.borderRadius),
      child: Stack(
        children: [
          // Image PageView with no bounce.
          PageView.builder(
            controller: _pageController,
            physics: const ClampingScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return _buildImageItem(context, widget.images[index]);
            },
          ),

          // Page Indicators.
          if (widget.showIndicators && widget.images.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: _buildPageIndicators(theme),
            ),

          // Navigation Arrows.
          if (widget.images.length > 1) ...[
            if (_currentPage > 0)
              Positioned(
                left: 16,
                top: widget.height / 2 - 20,
                child: _buildNavigationButton(
                  icon: IconlyBroken.arrow_left_2,
                  onTap: _previousPage,
                  theme: theme,
                ),
              ),
            if (_currentPage < widget.images.length - 1)
              Positioned(
                right: 16,
                top: widget.height / 2 - 20,
                child: _buildNavigationButton(
                  icon: IconlyBroken.arrow_right_2,
                  onTap: _nextPage,
                  theme: theme,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageItem(BuildContext context, String imageUrl) {
    final theme = Theme.of(context);
    final reloadKey = _imageReloadKeys[imageUrl] ?? 0;
    final hasError = _imageErrorStates[imageUrl] ?? false;

    final effectiveUrl = reloadKey > 0 ? '$imageUrl?v=$reloadKey' : imageUrl;

    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: effectiveUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            cacheKey: effectiveUrl,
            placeholder: (context, url) => Container(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
              child: Center(
                child: CupertinoActivityIndicator(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            errorWidget: (context, url, error) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && !(_imageErrorStates[imageUrl] ?? false)) {
                  setState(() {
                    _imageErrorStates[imageUrl] = true;
                  });
                }
              });
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                      theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    IconlyBroken.image,
                    size: 80,
                    color: theme.colorScheme.primary.withValues(alpha: 0.4),
                  ),
                ),
              );
            },
          ),
          // Retry button overlay on error.
          if (hasError)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  CachedNetworkImage.evictFromCache(effectiveUrl);
                  CachedNetworkImage.evictFromCache(imageUrl);
                  setState(() {
                    _imageErrorStates[imageUrl] = false;
                    _imageReloadKeys[imageUrl] = reloadKey + 1;
                  });
                },
                child: Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CupertinoIcons.refresh,
                        size: 32,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPageIndicators(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.images.length, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: _currentPage == index ? 24 : 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? Colors.white
                : Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildNavigationButton({
    required IconData icon,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: theme.colorScheme.primary, size: 24),
      ),
    );
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextPage() {
    if (_currentPage < widget.images.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
}
