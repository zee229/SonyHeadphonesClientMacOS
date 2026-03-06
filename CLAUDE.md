# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SonyHeadphonesClient is a macOS-only client for Sony headphones using the MDR (Mobile Device Receiver) protocol. It consists of two main components: `libmdr` (protocol library) and `client` (GUI application).

## Build Commands

```bash
# Standard build
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build . --target SonyHeadphonesClient

# Universal binary (arm64 + x86_64)
cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64"

# Debug build with logging
cmake .. -DMDR_DEBUG=ON

# Build with Address Sanitizer
cmake .. -DMDR_BUILD_WITH_ASAN=ON
```

There are no tests in this project.

## Architecture

### Two-layer design

- **`libmdr/`** — Static library implementing the Sony MDR V1/V2 Bluetooth protocol. Pure C++20 with a C API header layer (`include/mdr-c/`). Uses coroutines (`MDRTask`) for async command handling. Key files:
  - `include/mdr/Protocol.hpp` — Base types, `MDR_CHECK` macros, logging
  - `include/mdr/ProtocolV2T1.hpp`, `ProtocolV2T2.hpp` — V2 protocol packet/payload struct definitions
  - `include/mdr/Headphones.hpp` — Coroutine-based headphone state machine
  - `src/Headphones*.cpp` — Protocol command implementations
  - `include/mdr/Generated/` — Auto-generated enum converters, traits
  - `src/Generated/` — Auto-generated serialization and validation code

- **`client/`** — GUI application using SDL3 + Dear ImGui. Single main UI file `Client.cpp` (~52K). Entry point in `SDLMain.cpp`.

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

## Key Conventions

- C++20 required (Clang/Xcode)
- macOS only — `MDR_PLATFORM_OS` is always `MACOS`
- Exceptions used for validation failures and `MDR_CHECK`s
- CI targets `macos-only` and `main` branches
- `.clang-format` and `.clang-tidy` configs present at repo root
