// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "contacts-lookup",
    platforms: [.macOS(.v12)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
    ],
    targets: [
        .executableTarget(
            name: "contacts-lookup",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/contacts-lookup",
            exclude: ["Resources"]
        ),
        .testTarget(
            name: "contacts-lookupTests",
            dependencies: ["contacts-lookup"],
            path: "Tests/contacts-lookupTests"
        ),
    ]
)
