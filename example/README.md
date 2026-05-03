# manny_ui example

A Flutter app that demonstrates every public component in `manny_ui`. This is the same showcase referenced from the top-level README.

## Run it

```bash
cd manny_ui/example
flutter pub get
flutter run -d <device>
```

`device_preview` is wired in, so you can switch between phone, tablet, and desktop layouts at runtime without rebuilding. The toggle sits at the bottom of the window once the app launches.

## What it covers

The showcase is organized into thematic sections. Each section demonstrates a small group of related components with realistic content, not Lorem Ipsum.

- Modals & sheets — Cupertino fullscreen, Cupertino partial-height, bar style, comments-style. Filter, search, and selection sheets too.
- Alert dialogs — confirm, danger (red destructive), with input, info-only.
- Menus & dropdowns — share menu, options menu, custom dropdown.
- Layout — responsive shell, multi-panel layout, mobile nav bar, floating nav dock, navigation view, frosted scaffold, blurred app bar.
- Display — cached image, image carousel, action tile, rating display, progress bar, step tracker.
- Inputs — secure PIN keypad, custom dropdown.
- Feedback — notification toast, app fader effect.
- Audio — sound wave, voice visualizer (real microphone input on supported platforms).

## Notes

- The first launch downloads `audioplayers` native bundles. Subsequent runs are faster.
- The audio visualizer runs Rust code via `flutter_rust_bridge`. If your Rust toolchain isn't set up, the app still launches but the audio sections will throw at runtime. See the top-level README for the toolchain prerequisites.
- The web build works for everything except the audio visualizer (no microphone permission flow on this build yet).

## Where to look

If you're trying to understand how a particular component is wired up:

- `lib/main.dart` — the entire app, including every demo section.
- Search for the component name (e.g. `showFrostedCupertinoSheet`) in `main.dart` to find the call site.
- Peek at `manny_ui/lib/components/<name>.dart` for the implementation.

The showcase intentionally keeps the demos terse — most are 10-30 lines each — so they read more like documentation than a real app. If you want production examples, look at the apps listed under "Used by" in the parent README.
