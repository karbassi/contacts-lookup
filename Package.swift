// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "apple-contacts-cli",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
    ],
    targets: [
        .executableTarget(
            name: "apple-contacts-cli",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/apple-contacts-cli",
            exclude: ["Resources"]
        ),
        .testTarget(
            name: "apple-contacts-cliTests",
            dependencies: ["apple-contacts-cli"],
            path: "Tests/apple-contacts-cliTests"
        ),
    ]
)
