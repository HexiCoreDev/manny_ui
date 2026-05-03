/// manny_ui — frosted-glass UI library for Flutter.
///
/// Re-exports icon packages so consumers don't need direct imports.
library;

export 'package:iconly/iconly.dart';
export 'package:icons_plus/icons_plus.dart';

// Configuration
export 'config/app_theme.dart';
export 'config/manny_config.dart';
export 'config/ui_constants.dart';
export 'config/app_colors.dart';
export 'config/app_styles.dart';

// Utilities
export 'utils/responsive_layout.dart';
export 'utils/manny_scroll_behavior.dart';
export 'utils/neumorphic_painter.dart';
export 'utils/frosted_ink_splash.dart';
export 'utils/hide_on_scroll.dart';
export 'utils/nav_toast_controller.dart';

// Core Layout Components
export 'components/responsive_shell.dart';
export 'components/responsive_grid.dart';
export 'components/safe_area_wrapper.dart';
export 'components/multi_panel_layout.dart';
export 'components/blurred_app_bar.dart';
export 'components/frosted_app_bar.dart';
export 'components/frosted_scaffold.dart';

// Navigation Components
export 'components/mobile_nav_bar.dart';
export 'components/floating_nav_dock.dart';
export 'components/navigation_view.dart';
export 'components/item_navigation_view.dart';

// Input Components
export 'components/custom_dropdown.dart';
export 'components/secure_pin_keypad.dart';
export 'components/rating_input.dart';
export 'components/selection_sheet.dart';

// Display Components
export 'components/cached_image.dart';
export 'components/image_carousel.dart';
export 'components/rating_display.dart';
export 'components/action_tile.dart';
export 'components/options_menu.dart';
export 'components/progress_bar.dart';
export 'components/step_tracker.dart';

// Feedback Components
export 'components/app_alert_dialog.dart';
export 'components/notification_toast.dart';

// Glass & Modal Components
export 'components/frosted_glass.dart';
export 'components/frosted_modal.dart';

// Sheet primitives (replaces modal_bottom_sheet)
export 'src/sheets/frosted_bar_sheet.dart' show FrostedBarSheet, showFrostedBarSheet;
export 'src/sheets/frosted_compatible_page_route.dart' show FrostedCompatiblePageRoute;
export 'src/sheets/frosted_cupertino_sheet.dart' show FrostedCupertinoModalRoute, showFrostedCupertinoSheet;
export 'src/sheets/frosted_material_sheet.dart' show showFrostedMaterialSheet;
export 'src/sheets/frosted_modal_route.dart' show FrostedModalRoute, SheetContainerBuilder, showFrostedSheet;
export 'src/sheets/frosted_sheet_surface.dart' show FrostedSheetScope, FrostedSheetSurface;
export 'src/sheets/sheet_scroll_controller.dart' show SheetScrollController;

// Animation & Visualizer Components
export 'components/sound_wave.dart';
export 'components/voice_visualizer.dart';

// Audio Analysis (Rust FFI)
export 'src/rust/api/spectrum.dart';
export 'src/rust/frb_generated.dart' show RustLib;
export 'utils/audio_spectrum.dart';

// Utility Components
export 'components/app_fader_effect.dart';
export 'components/filter_sheet.dart';
export 'components/search_sheet.dart';
export 'components/share_menu.dart';
