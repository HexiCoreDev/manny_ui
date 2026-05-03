# manny_ui

A Flutter UI library built around frosted glass and neumorphic surfaces, with a Rust-backed audio spectrum visualizer thrown in.

> Status: pre-1.0. The API is stable enough that we ship it in production apps, but expect minor breaks before the first tagged release.

<!-- TODO: replace this block with the showcase video.
     Pick one:
     1. Convert ~/Videos/recording_2026-05-03_19.48.12.mp4 to a GIF
        (e.g. ffmpeg -i recording.mp4 -vf "fps=20,scale=480:-1" docs/showcase.gif)
        and commit it, then reference: ![showcase](docs/showcase.gif)
     2. Attach the .mp4 to a GitHub release and paste the rendered URL here.
        GitHub auto-renders an inline MP4 player.
     3. Upload to YouTube and embed a thumbnail link.
-->

![showcase placeholder — replace before public release](docs/showcase-placeholder.png)

## What's in the box

A set of components with a shared visual identity. Translucent surfaces, backdrop blur, soft neumorphic shadows. Colors adapt to dark and light themes without per-component overrides.

- **Frosted primitives** — `FrostedGlass`, `FrostedSheetSurface`, `FrostedAppBar`, `FrostedScaffold`, `BlurredAppBar`. Real backdrop blur, not a tinted overlay pretending to be one.
- **Frosted modal sheets** — `showFrostedCupertinoSheet`, `showFrostedMaterialSheet`, `showFrostedBarSheet`. A clean-room rewrite of the modal-sheet behavior contract from the `modal_bottom_sheet` package, with the frosted look as the default rather than an opt-in wrapper.
- **Sheet-based components** — filter sheet, search sheet, selection sheet, share menu, options menu, custom dropdown, alert dialog (confirm / danger / with input / info).
- **Layout** — responsive shell, responsive grid, multi-panel layout, mobile nav bar, floating nav dock, navigation view.
- **Display** — cached image, image carousel, action tile, rating display and input, progress bar, step tracker.
- **Inputs** — secure PIN keypad, custom dropdown.
- **Feedback** — notification toast, app fader effect.
- **Audio** — real-time FFT spectrum analyzer (`SoundWave`, `VoiceVisualizer`) backed by Rust + flutter_rust_bridge for tight latency.
- **Utilities** — neumorphic painter, frosted ink splash, hide-on-scroll behavior, responsive layout helpers.

## Install

`manny_ui` is not on pub.dev yet. Use a git or path dependency:

```yaml
dependencies:
  manny_ui:
    git:
      url: https://github.com/HexiCoreDev/manny_ui.git
      ref: main
```

Or, if you have it checked out locally:

```yaml
dependencies:
  manny_ui:
    path: ../manny_ui
```

The Rust audio components require a working Rust toolchain on your build machine. The library uses `flutter_rust_bridge` and `cargokit` to compile and link the native code as part of `flutter pub get` / `flutter build`. If you don't need the spectrum analyzer, you can ignore those exports — the rest of the library works without them.

## A taste

```dart
import 'package:flutter/material.dart';
import 'package:manny_ui/manny_ui.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return FrostedScaffold(
      title: 'Dashboard',
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _openCreateSheet(context),
        ),
      ],
      body: ListView(
        children: const [
          FrostedGlass(
            padding: EdgeInsets.all(16),
            child: Text('Frosted card content'),
          ),
        ],
      ),
    );
  }

  Future<void> _openCreateSheet(BuildContext context) {
    return showFrostedCupertinoSheet(
      context: context,
      expand: true,
      builder: (context) => FrostedScaffold(
        title: 'Create',
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        body: const Center(child: Text('Sheet body')),
      ),
    );
  }
}
```

Notes on the snippet:

- The `FrostedScaffold` inside the modal sheet automatically renders with a transparent background. It detects that it's inside a frosted sheet via `FrostedSheetScope` and switches off the opaque scaffold paint. No `backgroundColor: Colors.transparent` ceremony required.
- Every `IconButton` in either `FrostedScaffold` or directly inside any frosted sheet gets a circular highlight at a uniform overlay color, courtesy of an internal `IconButtonTheme`. You don't need to style the close X button.
- `showFrostedCupertinoSheet` with `expand: true` reproduces the iOS-13-style sheet behavior. The previous route scales down, its corners round, and a strip stays visible above the sheet so the underlying content shows through the blur.

## Theming

The library reads `Theme.of(context)` and `MediaQuery.of(context)` for pretty much everything: surface colors, brightness, status-bar height, safe areas. The defaults assume Material 3 (`useMaterial3: true`) but the components don't crash on Material 2 themes, they just look slightly less polished.

Constants live in `UIConstants` (`lib/config/ui_constants.dart`). Most callers won't touch these, but if you need to tune blur intensity, surface opacity, or the canonical sheet top-radius for a brand variant, override at the call site rather than mutating globals.

```dart
const UIConstants.glassBlurSigma          // 20.0  - default backdrop blur
const UIConstants.glassOpacity            // 0.12  - surface tint alpha
const UIConstants.glassSheetTopRadius     // 25.0  - default top corner radius
const UIConstants.glassBorderOpacityDark  // 0.08  - 1px border alpha (dark)
const UIConstants.glassBorderOpacityLight // 0.30  - 1px border alpha (light)
```

In dark mode the surface tint is automatically lifted toward white before the alpha is applied. Without that step, a 12% alpha on a near-black `colorScheme.surface` is invisible against a dark backdrop. The lift is small (about 18% white blend) and only kicks in for `Brightness.dark`, so light-mode appearance is unchanged.

## Running the example

The `example/` directory is a full Flutter app demonstrating every public component. It's the same showcase that ships in the video above.

```bash
cd manny_ui/example
flutter pub get
flutter run -d <device>
```

The example uses `device_preview` so you can switch between phone, tablet, and desktop layouts at runtime without rebuilding.

## Used by

<!-- TODO: add the portfolio admin screenshot/link here when ready -->

- HexiCore admin dashboard *(screenshot pending)*
- The Nebula distributed device cluster admin app

If you ship something with `manny_ui`, send a PR adding it here.

## Modal sheet attribution

The frosted modal sheet primitives in `lib/src/sheets/` are a clean-room rewrite informed by the behavior contract of the [`modal_bottom_sheet`](https://github.com/jamesblasco/modal_bottom_sheet) package by Jaime Blasco, MIT-licensed. The original package's drag physics, fling-to-close threshold, scroll-handoff model, and Cupertino transition math were the reference; the visual surface, theme integration, and API naming are ours. See `NOTICE.md` for the full attribution.

## Roadmap

A few things on the list. Order is rough.

- Tag a 0.1.0 and publish to pub.dev once a couple more apps are using it without local patches.
- Port the experimental `sheet` package (the inline, non-modal sheet) as a sibling to the modal stack. Different API, different use case.
- Add golden tests for the frosted primitives so visual regressions get caught in CI.
- Expand the example with a "kitchen sink" page covering every component, not just the most-used ones.

## License

MIT. See `LICENSE`.
