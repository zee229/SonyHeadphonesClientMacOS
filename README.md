# Sony Headphones for macOS

A native macOS app to control Sony wireless headphones — noise cancelling, EQ, touch controls, and more — without the Sony Sound Connect mobile app.

Built with SwiftUI and a custom reverse-engineered implementation of Sony's proprietary Bluetooth protocol (MDR V2).

![macOS](https://img.shields.io/badge/macOS-14.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-SwiftUI-orange)
![C++](https://img.shields.io/badge/C%2B%2B-20-blue)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Noise Cancelling / Ambient Sound** — switch modes, adjust ambient level, auto-adapt
- **Equalizer** — 5-band and 10-band EQ with visual sliders, preset selection, Clear Bass
- **DSEE** — toggle DSEE HX / DSEE HX AI upscaling
- **Speak to Chat** — sensitivity and timeout configuration
- **Playback** — volume, play/pause, track skip with multi-source awareness (Spotify, Apple Music)
- **Touch Controls** — assign functions to left/right touch sensors
- **Device Management** — multipoint switching, pairing mode, paired device list
- **Battery** — single, left/right, and case battery levels with charging status
- **Menu Bar Widget** — quick access to battery, NC mode, playback controls from the menu bar
- **System** — auto power off, voice guidance volume, head gesture, wearing detection pause
- **About** — model info, firmware version, codec indicator

## Supported Devices

This app uses Sony's **MDR V2 protocol**. It works with newer Sony headphones and earbuds that use this protocol variant.

### Tested & Working

| Model | Type | Status |
|-------|------|--------|
| **WH-1000XM6** | Over-ear | Full support |
| **WH-1000XM5** | Over-ear | Full support |
| **WF-1000XM5** | Earbuds | Full support |
| **WH-CH720N** | Over-ear | Partial (some features untested) |
| **WF-C510** | Earbuds | Partial (limited feature set) |
| **WF-LS900N (LinkBuds S)** | Earbuds | Mostly untested |

### Expected to Work (V2 protocol, untested)

These models use the same V2 protocol and are likely compatible, but haven't been verified:

- WH-1000XM4 (later firmware) — may use V2
- WH-XB910N
- WH-CH720N
- WF-1000XM4
- WF-C700N / WF-C710N
- WF-L900 (LinkBuds)
- ULT WEAR (WH-ULT900N)
- INZONE H9 II (WH-G910N)
- INZONE Buds (WF-G700N)

### Not Supported (V1 protocol)

Older devices use the legacy V1 protocol, which is **not implemented**:

- WH-1000XM3 and earlier
- WH-1000XM2
- WI-1000X / WI-1000XM2
- WF-1000X / WF-1000XM3
- MDR-1000X
- WH-H900N / WH-H800
- Most WI-series (WI-C600N, WI-H700, WI-SP600N)
- MDR-XB950B1 / MDR-XB950N1

> **Note:** The WH-1000XM4 is a borderline case. Early firmware versions use V1, but later updates may have added V2 support. Your mileage may vary.

## System Requirements

- **macOS 14.0 (Sonoma)** or later
- Apple Silicon (arm64) or Intel (x86_64)
- Bluetooth — the headphones must be paired with your Mac via System Settings

### macOS Compatibility

| macOS Version | Supported |
|---------------|-----------|
| macOS 26 (Tahoe) | Yes (Liquid Glass UI) |
| macOS 15 (Sequoia) | Yes |
| macOS 14 (Sonoma) | Yes (minimum) |
| macOS 13 and earlier | No |

## Installation

Download the latest `.dmg` from [Releases](../../releases), open it, and drag **Sony Headphones** to your Applications folder.

## Building from Source

### Prerequisites

- Xcode Command Line Tools (or Xcode)
- CMake 3.20+

### Quick Build

```bash
# Build the app (libmdr + SwiftUI → .app bundle)
./build_app.sh

# Or build a DMG installer
./build_dmg.sh
```

The app bundle is created at `build/Sony Headphones.app`.

### With Xcode

1. Build libmdr first:
   ```bash
   mkdir -p build && cd build
   cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo
   cmake --build . --target mdr mdr_PlatformMacOS
   ```
2. Open `client-swift/SonyHeadphonesClient.xcodeproj`
3. Build & Run (Cmd+R)

## Architecture

```
libmdr/              Protocol library (C++20, static)
  include/mdr/         Protocol types, headphone state machine, coroutines
  include/mdr-c/       C API headers (bridging layer for Swift)
  src/                 Protocol implementation, codegen output
  Platform/MacOS/      CoreBluetooth transport

client-swift/        SwiftUI app ("Sony Headphones")
  App/                 Entry point, content view router
  Models/              HeadphonesManager, enums, state types
  Views/               SwiftUI views by screen (Discovery, Connected, etc.)
  Bridge/              Objective-C bridging header
  Resources/           Info.plist, AppIcon, DMG background

tooling/             LLVM-based codegen tools (not needed for building)
build_app.sh         CLI build script (libmdr + SwiftUI → .app)
build_dmg.sh         DMG installer packaging script
```

The Swift app communicates with `libmdr` through a C API shim layer (`HeadphonesAccess.h`). A 60Hz timer poll loop reads device state and updates `@Published` properties, triggering SwiftUI view updates.

## Credits

Based on protocol research from [mos9527/SonyHeadphonesClient](https://github.com/mos9527/SonyHeadphonesClient) and the broader Sony headphones reverse-engineering community.

## Disclaimer

This project is not affiliated with, endorsed by, or connected to Sony Group Corporation. Use at your own risk. Sony, WH-1000XM5, WF-1000XM5, and related product names are trademarks of Sony Group Corporation.
