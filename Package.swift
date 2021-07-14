// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BwNearPeer",
    platforms: [
        .iOS(.v10),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "BwNearPeer",
            targets: ["BwNearPeer"]
        ),
    ],
    dependencies: [
        // .package(url: "https://github.com/BlueEventHorizon/BwLogger.git", from: "4.0.12"),
        .package(url: "https://github.com/BlueEventHorizon/BwLogger.git", .branch("main")),
        .package(url: "https://github.com/BlueEventHorizon/InfoPlistKeys.git", .branch("main")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "BwNearPeer",
            dependencies: ["BwLogger", "InfoPlistKeys"]
        ),
        .testTarget(
            name: "BwNearPeerTests",
            dependencies: ["BwNearPeer"]
        ),
    ]
)
