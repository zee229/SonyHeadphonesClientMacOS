// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MDRProtocol",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "MDRProtocol", targets: ["MDRProtocol"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-testing.git", from: "0.12.0"),
    ],
    targets: [
        .target(
            name: "MDRProtocol",
            path: "Sources/MDRProtocol"
        ),
        .testTarget(
            name: "MDRProtocolTests",
            dependencies: [
                "MDRProtocol",
                .product(name: "Testing", package: "swift-testing"),
            ],
            path: "Tests/MDRProtocolTests"
        ),
    ]
)
