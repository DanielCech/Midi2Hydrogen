// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Midi2Hydrogen",
    platforms: [
        .macOS(.v10_12),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "git@github.com:JohnSundell/Files.git", from: "4.1.1"),
        .package(url: "git@github.com:DanielCech/Moderator.git", from: "0.5.1"),
        .package(url: "git@github.com:DanielCech/ScriptToolkit.git", .branch("master")),
        .package(url: "https://github.com/kareman/SwiftShell.git", from: "5.0.1"),
        .package(url: "https://github.com/kareman/FileSmith.git", from: "0.3.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "Midi2Hydrogen",
            dependencies: ["Files", "FileSmith", "SwiftShell", "ScriptToolkit", "Moderator"]
        ),
        .testTarget(
            name: "Midi2HydrogenTests",
            dependencies: ["Midi2Hydrogen"]
        ),
    ]
)
