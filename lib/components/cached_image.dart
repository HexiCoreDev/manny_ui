import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:iconly/iconly.dart';

/// Custom FileServiceResponse that wraps HttpClientResponse.
class _HttpClientGetResponse implements FileServiceResponse {
  final HttpClientResponse _response;
  final DateTime _receivedTime = DateTime.now();

  _HttpClientGetResponse(this._response);

  @override
  Stream<List<int>> get content => _response;

  @override
  int? get contentLength =>
      _response.contentLength > 0 ? _response.contentLength : null;

  @override
  String? get eTag => _response.headers.value(HttpHeaders.etagHeader);

  @override
  String get fileExtension {
    final contentType = _response.headers.contentType;
    if (contentType == null) return '';
    switch (contentType.mimeType) {
      case 'image/jpeg':
        return '.jpg';
      case 'image/png':
        return '.png';
      case 'image/gif':
        return '.gif';
      case 'image/webp':
        return '.webp';
      case 'image/svg+xml':
        return '.svg';
      default:
        return '';
    }
  }

  @override
  int get statusCode => _response.statusCode;

  @override
  DateTime get validTill {
    var ageDuration = const Duration(days: 7);
    final cacheControl = _response.headers.value(
      HttpHeaders.cacheControlHeader,
    );
    if (cacheControl != null) {
      final settings = cacheControl.split(',');
      for (final setting in settings) {
        final sanitized = setting.trim().toLowerCase();
        if (sanitized == 'no-cache') {
          ageDuration = Duration.zero;
        }
        if (sanitized.startsWith('max-age=')) {
          final seconds = int.tryParse(sanitized.split('=')[1]) ?? 0;
          if (seconds > 0) {
            ageDuration = Duration(seconds: seconds);
          }
        }
      }
    }
    return _receivedTime.add(ageDuration);
  }
}

/// Custom HTTP file service that handles SSL certificates.
///
/// In debug mode on non-web platforms, bypasses certificate verification
/// to handle CDN certificate issues.
class _AppHttpFileService extends FileService {
  final HttpClient _httpClient;

  _AppHttpFileService() : _httpClient = HttpClient() {
    if (kDebugMode) {
      _httpClient.badCertificateCallback = (cert, host, port) => true;
    }
  }

  @override
  Future<FileServiceResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse(url);
    final request = await _httpClient.getUrl(uri);

    if (headers != null) {
      headers.forEach((key, value) {
        request.headers.add(key, value);
      });
    }

    final response = await request.close();

    return _HttpClientGetResponse(response);
  }
}

/// Custom cache manager with configurable stale period.
class AppCacheManager {
  static const key = 'nebulaCachedImageData';

  static CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(hours: 24),
      maxNrOfCacheObjects: 200,
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: kIsWeb ? HttpFileService() : _AppHttpFileService(),
    ),
  );
}

/// Reusable cached image widget with consistent styling.
///
/// Used throughout the app for all network images with automatic
/// caching, loading states, and error placeholders.
///
/// Example usage:
/// ```dart
/// CachedImage(
///   imageUrl: 'https://example.com/image.jpg',
///   width: 200,
///   height: 200,
///   borderRadius: BorderRadius.circular(12),
/// )
/// ```
class CachedImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData placeholderIcon;
  final double placeholderIconSize;
  final Color? placeholderIconColor;
  final bool showLoadingIndicator;

  const CachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderIcon = IconlyBroken.image,
    this.placeholderIconSize = 40,
    this.placeholderIconColor,
    this.showLoadingIndicator = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor =
        placeholderIconColor ??
        theme.colorScheme.primary.withValues(alpha: 0.4);

    Widget buildPlaceholder({bool isError = false}) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
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
          child: isError || !showLoadingIndicator
              ? Icon(
                  placeholderIcon,
                  size: placeholderIconSize,
                  color: iconColor,
                )
              : CupertinoActivityIndicator(
                  color: theme.colorScheme.primary,
                  radius: placeholderIconSize * 0.4,
                ),
        ),
      );
    }

    if (imageUrl == null || imageUrl!.isEmpty) {
      return buildPlaceholder(isError: true);
    }

    Widget image = CachedNetworkImage(
      imageUrl: imageUrl!,
      width: width,
      height: height,
      fit: fit,
      cacheManager: AppCacheManager.instance,
      placeholder: (context, url) => buildPlaceholder(),
      errorWidget: (context, url, error) => buildPlaceholder(isError: true),
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }
}

/// Cached avatar widget for use in CircleAvatar.
///
/// Uses the same cache manager as CachedImage.
///
/// Example usage:
/// ```dart
/// CachedAvatar(
///   imageUrl: 'https://example.com/avatar.jpg',
///   radius: 24,
///   fallbackText: 'John',
/// )
/// ```
class CachedAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final String? fallbackText;
  final Color? backgroundColor;
  final TextStyle? fallbackTextStyle;

  const CachedAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 20,
    this.fallbackText,
    this.backgroundColor,
    this.fallbackTextStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.colorScheme.surface;
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    if (!hasImage) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: fallbackText != null && fallbackText!.isNotEmpty
            ? Text(
                fallbackText![0].toUpperCase(),
                style:
                    fallbackTextStyle ??
                    TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                      fontSize: radius * 0.8,
                    ),
              )
            : Icon(
                IconlyBroken.profile,
                size: radius,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      cacheManager: AppCacheManager.instance,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        backgroundImage: imageProvider,
      ),
      placeholder: (context, url) => CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: CupertinoActivityIndicator(
          radius: radius * 0.4,
          color: theme.colorScheme.primary,
        ),
      ),
      errorWidget: (context, url, error) => CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: fallbackText != null && fallbackText!.isNotEmpty
            ? Text(
                fallbackText![0].toUpperCase(),
                style:
                    fallbackTextStyle ??
                    TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                      fontSize: radius * 0.8,
                    ),
              )
            : Icon(
                IconlyBroken.profile,
                size: radius,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
      ),
    );
  }
}
