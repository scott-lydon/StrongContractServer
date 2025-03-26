// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "StrongContractServer",
    platforms: [
        .macOS(.v10_15), // Ensuring it's only used for macOS (and Linux)
        // ❌ No `.linux` here, since SwiftPM assumes Linux support by default if no restrictions are set.
    ],
    products: [
        // ✅ Defines the library product that other packages can import
        .library(
            name: "StrongContractServer",
            targets: ["StrongContractServer"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/scott-lydon/StrongContractClient.git", exact: "10.0.7"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
    ],
    targets: [
        .target(
            name: "StrongContractServer",
            dependencies: [
                "StrongContractClient",
                .product(name: "Vapor", package: "vapor") // ✅ Includes Vapor
            ]
        ),
        .testTarget(
            name: "StrongContractServerTests",
            dependencies: ["StrongContractServer"]
        ),
    ]
)
