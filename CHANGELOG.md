# Changelog

All notable changes to this project will be documented in this file.

The format is loosely based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- First public release of `manny_ui`.
- `FrostedSheetSurface`, `FrostedBottomSheet`, `FrostedModalRoute`, and the three
  variants (`showFrostedCupertinoSheet`, `showFrostedMaterialSheet`,
  `showFrostedBarSheet`) — a clean-room rewrite of the modal sheet stack so the
  frosted-glass look is the default, not a wrapper.
- `FrostedSheetScope` inherited widget. `FrostedScaffold` reads it and switches
  to a transparent background when nested inside a frosted modal — no
  caller-side configuration required.
- `IconButtonTheme` baked into every frosted sheet so close/back/action buttons
  get a circular highlight at a uniform overlay color.
- Neumorphic painter, frosted glass primitives, frosted app bar, frosted
  scaffold, frosted ink splash.
- Sheet-based components: filter sheet, search sheet, selection sheet, share
  menu, options menu, alert dialog (confirm / danger / with input / info),
  custom dropdown.
- Layout: responsive shell, responsive grid, multi-panel layout, mobile nav
  bar, floating nav dock, navigation view, item navigation view, blurred app
  bar, frosted scaffold.
- Display: cached image, image carousel, action tile, rating display / input,
  progress bar, step tracker, sound wave, voice visualizer.
- Inputs: secure PIN keypad, custom dropdown.
- Feedback: notification toast, app fader effect.
- Audio: real-time FFT spectrum analyzer powered by Rust + flutter_rust_bridge.

### Notes
- The modal sheet behavior contract was studied from the
  [`modal_bottom_sheet`](https://github.com/jamesblasco/modal_bottom_sheet)
  package by Jaime Blasco, MIT-licensed. See `NOTICE.md` for full attribution.
