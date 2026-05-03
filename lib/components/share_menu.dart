import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:manny_ui/config/ui_constants.dart';
import 'package:manny_ui/src/sheets/frosted_material_sheet.dart';

/// Configuration for a single share platform option.
class SharePlatform {
  /// The widget to display as the logo (typically a [Brand] or [Icon]).
  final Widget logo;

  /// Background color for the circular button.
  final Color bgColor;

  /// Logo/icon color applied via [IconTheme].
  final Color logoColor;

  /// Callback when this platform is tapped.
  final VoidCallback onTap;

  const SharePlatform({
    required this.logo,
    required this.bgColor,
    required this.logoColor,
    required this.onTap,
  });
}

/// A configurable social share modal bottom sheet.
///
/// Displays share options in a grid layout. Platforms are fully configurable.
/// Uses `icons_plus` for brand icons and `iconly` for utility icons.
///
/// Example usage:
/// ```dart
/// ShareMenu.show(
///   context: context,
///   platforms: [
///     SharePlatform(
///       logo: Brand(Brands.facebook),
///       bgColor: Color(0xFFEBF5FF),
///       logoColor: Color(0xFF1877F2),
///       onTap: () => shareTo('facebook'),
///     ),
///     SharePlatform(
///       logo: Brand(Brands.whatsapp),
///       bgColor: Color(0xFFE7F7EF),
///       logoColor: Color(0xFF25D366),
///       onTap: () => shareTo('whatsapp'),
///     ),
///   ],
/// );
/// ```
class ShareMenu {
  /// Show the share menu as a modal bottom sheet.
  static Future<void> show({
    required BuildContext context,
    required List<SharePlatform> platforms,
    String title = 'Share',
    String cancelText = 'Cancel',
    int crossAxisCount = 4,
  }) {
    return showFrostedMaterialSheet(
      context: context,
      useRootNavigator: true,
      builder: (BuildContext context) {
        final theme = Theme.of(context);

        return Container(
            padding: const EdgeInsets.all(24),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag handle
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.2,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Share options grid
                    GridView.count(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: platforms
                          .map(
                            (platform) => _buildShareOption(
                              context,
                              logo: platform.logo,
                              bgColor: platform.bgColor,
                              logoColor: platform.logoColor,
                              onTap: platform.onTap,
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 24),

                    // Cancel button
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(25),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withValues(
                            alpha: UIConstants.glassElementOpacity,
                          ),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Center(
                          child: Text(
                            cancelText,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
        );
      },
    );
  }

  /// Helper to build a single share option button.
  static Widget _buildShareOption(
    BuildContext context, {
    required Widget logo,
    required VoidCallback onTap,
    required Color bgColor,
    required Color logoColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
        child: Center(
          child: IconTheme(
            data: IconThemeData(color: logoColor, size: 24),
            child: logo,
          ),
        ),
      ),
    );
  }

  /// Convenience method providing common social platform defaults.
  ///
  /// Returns a list of [SharePlatform] with standard brand colors.
  /// Pass callbacks for each platform. Null callbacks will exclude that platform.
  static List<SharePlatform> defaultPlatforms({
    VoidCallback? onFacebook,
    VoidCallback? onWhatsApp,
    VoidCallback? onEmail,
    VoidCallback? onTelegram,
    VoidCallback? onInstagram,
    VoidCallback? onSms,
    VoidCallback? onCopyLink,
    VoidCallback? onMore,
  }) {
    final platforms = <SharePlatform>[];

    if (onFacebook != null) {
      platforms.add(
        SharePlatform(
          logo: Brand(Brands.facebook),
          bgColor: const Color(0xFFEBF5FF),
          logoColor: const Color(0xFF1877F2),
          onTap: onFacebook,
        ),
      );
    }

    if (onWhatsApp != null) {
      platforms.add(
        SharePlatform(
          logo: Brand(Brands.whatsapp),
          bgColor: const Color(0xFFE7F7EF),
          logoColor: const Color(0xFF25D366),
          onTap: onWhatsApp,
        ),
      );
    }

    if (onEmail != null) {
      platforms.add(
        SharePlatform(
          logo: Brand(Brands.mail),
          bgColor: const Color(0xFFFEF2F2),
          logoColor: const Color(0xFFEA4335),
          onTap: onEmail,
        ),
      );
    }

    if (onTelegram != null) {
      platforms.add(
        SharePlatform(
          logo: Brand(Brands.telegram_app),
          bgColor: const Color(0xFFE3F2FD),
          logoColor: const Color(0xFF0088CC),
          onTap: onTelegram,
        ),
      );
    }

    if (onInstagram != null) {
      platforms.add(
        SharePlatform(
          logo: Brand(Brands.instagram),
          bgColor: const Color(0xFFFCF4F6),
          logoColor: const Color(0xFFE4405F),
          onTap: onInstagram,
        ),
      );
    }

    if (onSms != null) {
      platforms.add(
        SharePlatform(
          logo: const Icon(IconlyBroken.message, size: 28),
          bgColor: const Color(0xFFECF8EC),
          logoColor: Colors.green,
          onTap: onSms,
        ),
      );
    }

    if (onCopyLink != null) {
      platforms.add(
        SharePlatform(
          logo: const Icon(Icons.link_rounded, size: 28),
          bgColor: const Color(0xFFF5F0FF),
          logoColor: Colors.deepPurple,
          onTap: onCopyLink,
        ),
      );
    }

    if (onMore != null) {
      platforms.add(
        SharePlatform(
          logo: const Icon(Icons.more_horiz_rounded, size: 28),
          bgColor: const Color(0xFFF5F5F5),
          logoColor: Colors.grey,
          onTap: onMore,
        ),
      );
    }

    return platforms;
  }
}
