# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SoundPilot (formerly "Sony Headphones Client") is a macOS-only client for Sony headphones using the MDR (Mobile Device Receiver) protocol. It consists of two main components: `MDRProtocol/` (pure Swift protocol library) and `client-swift/` (native SwiftUI GUI). Supports dual distribution: direct (Developer ID + notarization + DMG) and Mac App Store (sandboxed).

## Build Commands

```bash
# Quick build (recommended) — builds MDRProtocol + SwiftUI app into .app bundle
./build_app.sh

# App Store build — excludes MediaRemote, AppleScript, CGEvent, floating windows
./build_app.sh --appstore

# Signed build (direct distribution)
./build_app.sh --sign="Developer ID Application: Your Name (TEAMID)"

# Signed App Store build
./build_app.sh --appstore --sign="3rd Party Mac Developer Application: Your Name (TEAMID)"

# Build DMG installer (calls build_app.sh if needed)
./build_dmg.sh

# Signed + notarized DMG
./build_dmg.sh --sign="Developer ID Application: Your Name (TEAMID)" --notarize="PROFILE"

# Run MDRProtocol tests
swift test --package-path MDRProtocol

# Alternatively, open client-swift/SonyHeadphonesClient.xcodeproj in Xcode and build (Cmd+R).
```

## Build Scripts

- **`build_app.sh`** — One-step CLI build: `swift build` MDRProtocol → `ar` static library → `swiftc` SwiftUI app → assemble .app bundle with Info.plist, icon, and resources. Supports `--appstore` (adds `-D APPSTORE` to swiftc) and `--sign=IDENTITY` (code signing with entitlements). Output: `build/SoundPilot.app`
- **`build_dmg.sh`** — Creates styled DMG installer with custom background, positioned icons, white Finder labels. Supports `--sign=IDENTITY` and `--notarize=PROFILE`. Calls `build_app.sh` if app not already built. Output: `build/SoundPilot-{version}.dmg`

## Architecture

### Two-layer design

- **`MDRProtocol/`** — Swift Package implementing the Sony MDR V2 Bluetooth protocol. macOS 14+, Swift 6.0. Built as a static library via SPM, linked into the app. Key directories:
  - `Sources/MDRProtocol/Base/` — Foundation types: `BigEndian.swift`, `DataReader.swift`, `DataWriter.swift`, `MDRError.swift`, `Serializable.swift`, `PrefixedString.swift`, `PodArray.swift`
  - `Sources/MDRProtocol/Enums/` — Protocol enums: `V2Enums.swift`, `T1Enums.swift`, `T1Command.swift`, `T2Enums.swift`, `T2Command.swift`
  - `Sources/MDRProtocol/Payloads/T1/` — T1 payload structs (~137 structs): Connect, Common, Power, NcAsm, EqEbb, Audio, Play, System, Alert, GeneralSetting
  - `Sources/MDRProtocol/Payloads/T2/` — T2 payload structs (~49 structs): Connect, Peripheral, VoiceGuidance, SafeListening
  - `Sources/MDRProtocol/Framing/` — Command framing: `Escape.swift`, `PackUnpack.swift`, `Constants.swift`
  - `Sources/MDRProtocol/StateMachine/` — Core state machine: `MDRHeadphones.swift`, `MDRProperty.swift`, `MDRTransport.swift`, `MDREvent.swift`
  - `Sources/MDRProtocol/Handlers/` — Protocol handlers: `HandleV2T1.swift`, `HandleV2T2.swift`, `RequestInit.swift`, `RequestSync.swift`, `RequestCommit.swift`
  - `Sources/MDRProtocol/Platform/` — IOBluetooth RFCOMM transport: `BluetoothTransport.swift`
  - `Tests/MDRProtocolTests/` — 402 tests covering all layers

- **`client-swift/`** — Native SwiftUI GUI application ("SoundPilot"). Xcode project at `SonyHeadphonesClient.xcodeproj`. Uses `MDRProtocol` directly (no bridging header). Key files:
  - `App/SonyHeadphonesClientApp.swift` — `@main` entry point, `WindowGroup`, `Settings` scene (Cmd+,), `AppTheme` enum, theme management via `NSApp.appearance`
  - `App/ContentView.swift` — State-machine router based on connection state
  - `Models/HeadphonesManager.swift` — Central `@MainActor ObservableObject` with 60Hz poll loop. Uses `MDRHeadphones` directly via `import MDRProtocol`. Bridges MDRProtocol enum types to UI enum types via raw values.
  - `Models/MDREnums.swift` — UI-layer enums with `displayName` properties (subset of MDRProtocol enums for picker UI)
  - `Models/DeviceState.swift` — Swift value types for connection/battery/device state
  - `Models/HeadphonesSnapshot.swift` — `Codable` snapshot struct for widget data sharing via `UserDefaults(suiteName:)`
  - `Views/` — SwiftUI views organized by connection state (Discovery, Connecting, Connected, Disconnected). About tab doubles as app settings (theme, window, permissions).
  - `Views/Connected/PlaybackTab.swift` — Playback tab with `NowPlayingMonitor` (MediaRemote + AppleScript in direct build; stub in App Store build via `#if !APPSTORE`), `MediaSource` model, `SourcePill` view, and smart routing (AppleScript for app-targeted controls, AVRCP fallback). `AudioVisualizerView` animated bars.
  - `Views/MenuBar/MenuBarPopoverView.swift` — Menu bar popover: battery, NC controls, playback with multi-source pills (`MenuBarSourcePill`), volume. Uses `MenuBarExtra` scene with `.window` style.
  - `Resources/Info.plist` — Bundle config (name: "SoundPilot", icon, Bluetooth usage). Contains `$(EXECUTABLE_NAME)` / `$(PRODUCT_BUNDLE_IDENTIFIER)` Xcode variables resolved by `build_app.sh` at build time.
  - `Resources/SoundPilot.entitlements` — App Store entitlements (sandbox + bluetooth + network)
  - `Resources/SoundPilot-Direct.entitlements` — Direct distribution entitlements (unsigned executable memory)
  - `Resources/AppIcon.icns` — App icon for CLI builds (all sizes 16-512@2x)
  - `Resources/Assets.xcassets/AppIcon.appiconset/` — App icon for Xcode builds
  - `Resources/dmg-background.png`, `dmg-background@2x.png` — DMG installer background

### MDRProtocol design patterns

- `MDRSerializable` protocol: `serialize(to:)` / `deserialize(from:)` for command-level structs
- `MDRReadWritable` protocol: `read(from:)` / `write(to:)` for sub-type structs
- `MDRProperty<T>` — Generic property with desired/current value tracking for dirty-checking
- `MDRTransport` — Protocol abstracting Bluetooth transport (send/receive). `MockTransport` for testing, `BluetoothTransport` for real IOBluetooth RFCOMM.
- `MDRHeadphones` — Main state machine class with `pollEvents()` loop, send/receive buffers, awaiter mechanism
- `MDREvent` — Enum for event codes returned by `pollEvents()`
- Callback-based awaiter mechanism: `setAwaiter(.type) { result in ... }` + `awake(.type)` to resume
- Command framing: pack/unpack with escape sequences, checksum, start/end markers
- `MDRDataType`: `.dataMdr` for T1 commands, `.dataMdrNo2` for T2 commands, `.ack` for acknowledgments
- All payload structs: first field is command byte, field-by-field serialization via DataReader/DataWriter

### Legacy files (kept for reference)

- **`libmdr/`** — Original C++20 protocol library (superseded by MDRProtocol). Kept for reference.
- **`tooling/`** — LLVM/libclang codegen tools for the C++ library.
- **`contrib/`** — fmt library dependency for C++ code.

## UI Theme

**SwiftUI client** (`client-swift/`): Supports System/Light/Dark theme switching via `NSApp.appearance` (persisted in `@AppStorage("appTheme")`). On macOS 26 (Tahoe), uses Liquid Glass design language (`glassEffect` API) for cards, pills, badges, and buttons with `@available(macOS 26, *)` checks — falls back to manual background/cornerRadius/stroke styling on macOS 14/15. Shared modifiers: `GlassCardModifier`, `ModePillModifier` (in `SoundTab.swift`), `BadgeModifier` (in `HeaderView.swift`), `DeviceCardModifier` (in `DevicesTab.swift`), `DiscoveryRowModifier` (in `DiscoveryView.swift`), `PlayButtonModifier`, `SourcePill` (in `PlaybackTab.swift`). Battery progress bars use context-sensitive colors (green/orange/red).

## CI

GitHub Actions workflow (`.github/workflows/cmake.yml`): runs MDRProtocol tests, builds the SwiftUI client (app + DMG) on every push/PR to `main` and `macos-only`. Uploads DMG as artifact.

## Dual Distribution (Direct + App Store)

The app supports two distribution channels via compile-time `#if APPSTORE` / `#if !APPSTORE` guards:

- **Direct distribution** (default `./build_app.sh`): Full features — MediaRemote now-playing detection, AppleScript playback controls, CGEvent media keys, Always on Top window level. Signed with Developer ID + notarized.
- **App Store** (`./build_app.sh --appstore`): Sandboxed build that excludes all private/banned APIs. `NowPlayingMonitor` is a stub (AVRCP-only playback). No Automation section in About. No Always on Top. Uses `NSWorkspace` for relaunch instead of `Process`.

Files with `#if !APPSTORE` guards:
- `PlaybackTab.swift` — Full `NowPlayingMonitor` vs stub
- `SonyHeadphonesClientApp.swift` — `relaunchApp()` implementation
- `AboutTab.swift` — Automation permission row, Always on Top toggle, `setWindowLevel()`

## Key Conventions

- Pure Swift project (Swift 6.0), no C++ or CMake needed
- macOS 14+ deployment target, macOS 26+ for Liquid Glass
- macOS only
- App name: "SoundPilot", bundle ID: `com.YOURNAME.SoundPilot`
- MDRProtocol uses SCREAMING_CASE enum values (`.NC`, `.ASM`, `.OFF`); client MDREnums.swift uses camelCase (`.nc`, `.asm_`, `.off`) with `displayName` properties for UI
- HeadphonesManager bridges between MDRProtocol and UI types via raw values
