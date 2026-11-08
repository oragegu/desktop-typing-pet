# Typing Pet for macOS

This is a native macOS reimplementation of the supplied Windows `.NET` executable. The original executable is not run or bundled.

## Build

```sh
./script/setup_local_signing.sh
./build-macos-app.sh
```

The first command checks for an Apple Development identity from Xcode. A free Personal Team is enough; a paid Developer ID is not required. Reusing that identity gives macOS a stable identity for remembering Input Monitoring permission across rebuilds and restarts. This workflow is for local development and is not suitable for distributing the app to other people.

The universal build (Apple Silicon and Intel) is staged temporarily under `/private/tmp` so Spotlight does not list it as a second installed app and File Provider metadata cannot invalidate its signature. To build and install the stable copy at `/Applications/Typing Pet.app`, run:

```sh
./script/install_local.sh
```

Use `./script/build_and_run.sh` to rebuild, install, and launch it in one step.

## First launch

macOS asks for **Input Monitoring** permission so the pet can react while other apps are active. Typing Pet only responds to key-down events; it does not store or transmit the keys you type.

Always grant permission to the installed `/Applications/Typing Pet.app` copy. The first locally signed build is a new identity, so you must grant permission once more after switching from an older ad-hoc-signed build.

The app retries automatically after permission is granted. If macOS still does not deliver events, quit and reopen it. Use the paw icon in the menu bar for settings, permission status, size, window behavior, position reset, and quit. Right-clicking the pet opens the same menu.

## Included behavior

- Transparent, draggable desktop pet
- Alternating left/right typing frames and bounce animation
- Special bundled reactions for Space and Return
- Global keyboard monitoring
- Menu-bar controls and right-click menu
- Native launch-at-login control in the settings window and paw menu
- Four sizes, always-on-top, and click-through position lock
- Custom images for all five states
- Saved position and settings

The Windows-only tray, registry startup entry, WPF settings UI, and low-level Win32 hooks were replaced with native AppKit equivalents.
