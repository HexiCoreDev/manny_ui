# Third-party attributions

## Modal sheet primitives

The sheet primitives in `lib/src/sheets/` are a clean-room rewrite informed by
the behavior contract of the [`modal_bottom_sheet`](https://github.com/jamesblasco/modal_bottom_sheet)
package by Jaime Blasco, MIT-licensed.

> Copyright (c) 2020-present Jaime Blasco

The original package is MIT-licensed; the upstream `bottom_sheet.dart` file in
particular was itself derived by the upstream author from Flutter's framework
BSD-licensed bottom sheet implementation. Both lineages are acknowledged.

The rewrite changes (relative to the upstream behavior):

- Visual surface is always rendered through `FrostedSheetSurface` (frosted
  glass + neumorphic painter). The Material/Cupertino theme machinery from
  upstream (`Material` widget surfaces, `CupertinoUserInterfaceLevel`,
  `CupertinoDynamicColor`, `CupertinoScaffold`) is dropped — `manny_ui` owns
  the visual theme.
- `_bounceDragController.dispose()` added (upstream resource leak fixed).
- Unified `preventPopThreshold` parameter (upstream had two redundant
  variants).
- Naming convention rebrand: `Frosted*` prefix on all public types.
