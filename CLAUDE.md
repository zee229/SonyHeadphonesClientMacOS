# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Sony Headphones is a macOS-only client for Sony headphones using the MDR (Mobile Device Receiver) protocol. It consists of three main components: `libmdr` (protocol library), `client/` (legacy SDL3+ImGui GUI), and `client-swift/` (native SwiftUI GUI).

## Build Commands

```bash
# Quick build (recommended) — builds libmdr + SwiftUI app into .app bundle
./build_app.sh

# Build DMG installer (calls build_app.sh if needed)
./build_dmg.sh

# Manual: build libmdr only
mkdir -p build && cd build
cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build . --target mdr mdr_PlatformMacOS

# Build legacy SDL3+ImGui client
cmake --build . --target SonyHeadphonesClient

# Alternatively, open client-swift/SonyHeadphonesClient.xcodeproj in Xcode and build (Cmd+R).

# Universal binary (arm64 + x86_64)
cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64"

# Debug build with logging
cmake .. -DMDR_DEBUG=ON

# Build with Address Sanitizer
cmake .. -DMDR_BUILD_WITH_ASAN=ON
```

There are no tests in this project.

## Build Scripts

- **`build_app.sh`** — One-step CLI build: cmake libmdr → swiftc SwiftUI app → assemble .app bundle with Info.plist, icon, and resources. Output: `build/Sony Headphones.app`
- **`build_dmg.sh`** — Creates styled DMG installer with custom background, positioned icons, white Finder labels. Calls `build_app.sh` if app not already built. Output: `build/SonyHeadphones-{version}.dmg`

## Architecture

### Two-layer design

- **`libmdr/`** — Static library implementing the Sony MDR V1/V2 Bluetooth protocol. Pure C++20 with a C API header layer (`include/mdr-c/`). Uses coroutines (`MDRTask`) for async command handling. Key files:
  - `include/mdr/Protocol.hpp` — Base types, `MDR_CHECK` macros, logging
  - `include/mdr/ProtocolV2T1.hpp`, `ProtocolV2T2.hpp` — V2 protocol packet/payload struct definitions
  - `include/mdr/Headphones.hpp` — Coroutine-based headphone state machine
  - `src/Headphones*.cpp` — Protocol command implementations
  - `include/mdr/Generated/` — Auto-generated enum converters, traits
  - `src/Generated/` — Auto-generated serialization and validation code

- **`client/`** — Legacy GUI application using SDL3 + Dear ImGui. Single main UI file `Client.cpp` (~52K). Entry point in `SDLMain.cpp`.

- **`client-swift/`** — Native SwiftUI GUI application ("Sony Headphones"). Xcode project at `SonyHeadphonesClient.xcodeproj`. Uses a bridging header to call the C API from `libmdr`. Key files:
  - `App/SonyHeadphonesClientApp.swift` — `@main` entry point, `WindowGroup`, `Settings` scene (Cmd+,), `AppTheme` enum, theme management via `NSApp.appearance`
  - `App/ContentView.swift` — State-machine router based on connection state
  - `Models/HeadphonesManager.swift` — Central `@MainActor ObservableObject` with 60Hz poll loop
  - `Models/MDREnums.swift` — Swift enums mirroring C++ protocol enums
  - `Models/DeviceState.swift` — Swift value types for connection/battery/device state
  - `Models/HeadphonesSnapshot.swift` — `Codable` snapshot struct for widget data sharing via `UserDefaults(suiteName:)`
  - `Views/` — SwiftUI views organized by connection state (Discovery, Connecting, Connected, Disconnected). About tab doubles as app settings (theme, window, permissions).
  - `Views/Connected/PlaybackTab.swift` — Playback tab with `NowPlayingMonitor` (multi-source AppleScript polling), `MediaSource` model, `SourcePill` view, and smart routing (AppleScript for app-targeted controls, AVRCP fallback). `AudioVisualizerView` animated bars.
  - `Views/MenuBar/MenuBarPopoverView.swift` — Menu bar popover: battery, NC controls, playback with multi-source pills (`MenuBarSourcePill`), volume. Uses `MenuBarExtra` scene with `.window` style.
  - `Bridge/SonyHeadphonesClient-Bridging-Header.h` — Imports all C API headers
  - `Resources/Info.plist` — Bundle config (name: "Sony Headphones", icon, Bluetooth usage). Contains `$(EXECUTABLE_NAME)` / `$(PRODUCT_BUNDLE_IDENTIFIER)` Xcode variables resolved by `build_app.sh` at build time.
  - `Resources/AppIcon.icns` — App icon for CLI builds (all sizes 16-512@2x)
  - `Resources/Assets.xcassets/AppIcon.appiconset/` — App icon for Xcode builds
  - `Resources/dmg-background.png`, `dmg-background@2x.png` — DMG installer background

- **`libmdr/include/mdr-c/HeadphonesAccess.h`** — C shim layer exposing all `MDRProperty` fields as C getter/setter functions. Used by the SwiftUI client via bridging header. Implementation in `libmdr/src/HeadphonesAccess.cpp`.

### Platform abstraction

Both `libmdr` and `client` have macOS-specific code under `Platform/MacOS/` directories. The platform layer provides Bluetooth transport (CoreBluetooth) and platform integration.

### Code generation (tooling/)

The `tooling/` directory contains LLVM/libclang-based AST walkers that generate code from `libmdr` header annotations. Requires LLVM dev libraries (Homebrew `llvm` on macOS). Codegen is NOT run automatically during build.

**Codegen tools** (run via `libmdr/generate_all.sh` from the repo root):
- `tooling_EnumCodegen` — Generates enum-to-string/string-to-enum converters
- `tooling_SerializationCodegen` — Generates `Serialize`/`Deserialize` functions for non-trivial payload structs
- `tooling_ValidationCodegen` — Generates field validation code from `CODEGEN` comments
- `tooling_TraitsCodegen` — Generates type traits headers

### Payload struct conventions (AGENTS.md)

Payload structs in `libmdr`:
- First field is always `Command command{Command::...}`
- Trivially serializable (POD) structs use `MDR_DEFINE_TRIVIAL_SERIALIZATION(Type)` with `#pragma pack(push, 1)`
- Non-trivial structs (containing vectors/strings) use `MDR_DEFINE_EXTERN_SERIALIZATION(Type)` — implementations are codegen'd
- Field-level Read/Write for sub-types: `MDR_DEFINE_EXTERN_READ_WRITE(SubType)`
- Validation hints via `CODEGEN EnumRange`, `CODEGEN Range`, `CODEGEN Field` comments above fields
- Use `MDR_CODEGEN_IGNORE_SERIALIZATION` / `MDR_CODEGEN_IGNORE_VALIDATION` to exclude from codegen

### Dependencies (all via CMake FetchContent)

- **fmt** (12.1.0) — String formatting
- **SDL3** (3.2.26) — Windowing/rendering
- **Dear ImGui** (1.92.4) — GUI

## UI Theme

**SwiftUI client** (`client-swift/`): Supports System/Light/Dark theme switching via `NSApp.appearance` (persisted in `@AppStorage("appTheme")`). On macOS 26 (Tahoe), uses Liquid Glass design language (`glassEffect` API) for cards, pills, badges, and buttons with `@available(macOS 26, *)` checks — falls back to manual background/cornerRadius/stroke styling on macOS 14/15. Shared modifiers: `GlassCardModifier`, `ModePillModifier` (in `SoundTab.swift`), `BadgeModifier` (in `HeaderView.swift`), `DeviceCardModifier` (in `DevicesTab.swift`), `DiscoveryRowModifier` (in `DiscoveryView.swift`), `PlayButtonModifier`, `SourcePill` (in `PlaybackTab.swift`). Battery progress bars use context-sensitive colors (green/orange/red).

**Legacy ImGui client** (`client/`): Uses a custom macOS Sequoia dark mode theme defined in `SetupMacOSStyle()` in `SDLMain.cpp`. Accent color is macOS system blue `#0A84FF`.

## CI

GitHub Actions workflow (`.github/workflows/cmake.yml`): builds both legacy ImGui client (universal binary) and SwiftUI client (app + DMG) on every push/PR to `main` and `macos-only`. Uploads DMG and zip as artifacts.

## Key Conventions

- C++20 required (Clang/Xcode), Swift 6.0
- macOS 14+ deployment target, macOS 26+ for Liquid Glass
- macOS only — `MDR_PLATFORM_OS` is always `MACOS`
- Exceptions used for validation failures and `MDR_CHECK`s
- `.clang-format` and `.clang-tidy` configs present at repo root
- App name: "Sony Headphones", bundle ID: `com.mos9527.SonyHeadphonesClient`
