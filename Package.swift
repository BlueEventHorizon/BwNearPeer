// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
// 'v11' is deprecated: iOS 12.0 is the oldest supported version

import PackageDescription

let package = Package(
    name: "BwNearPeer",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "BwNearPeer",
            targets: ["BwNearPeer"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "BwNearPeer"
        ),
        .testTarget(
            name: "BwNearPeerTests",
            dependencies: ["BwNearPeer"]
        ),
    ]
)
