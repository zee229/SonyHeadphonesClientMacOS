SonyHeadphonesClient
===

A macOS client for Sony headphones based on [mos9527's SonyHeadphonesClient](https://github.com/mos9527/SonyHeadphonesClient) — now streamlined for macOS only.

[![Build](https://github.com/mos9527/sonyheadphonesclient/actions/workflows/cmake.yml/badge.svg)](https://github.com/mos9527/SonyHeadphonesClient/actions/workflows/cmake.yml)

## Roadmap
- [ ] Support for legacy (`v1` protocol) devices, e.g. WH-1000XM4, WH-1000XM3

For device support, refer to `docs/device-support` to check. If the feature support status for your own device is missing/incorrect/untested here, feel free to submit an [Issue](https://github.com/mos9527/SonyHeadphonesClient/issues/new) so we can work on it!

## For Developers

We have extensive documentations available in the source files. Moreover, refer to the respective README files in each source folder to understand what they do!

A C++20 compliant compiler is required. Clang 21 (Xcode) is used for development.

### Building
This is no different from your regular CMake projects.
Third-party dependencies (see `contrib`) are managed by CMake's `FetchContent` and are always statically linked, so no worries - Expect things to *just work*.

**For Developers:** See also `tooling` for codegen dependencies.

#### Example
```bash
mkdir build
cd build
cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build . --target SonyHeadphonesClient
```

#### Universal binary (arm64 + x86_64)
```bash
mkdir build
cd build
cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64"
cmake --build . --target SonyHeadphonesClient
```
