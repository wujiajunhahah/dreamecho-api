// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DreamEchoApp",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(name: "DreamEchoApp", targets: ["DreamEchoApp"])
    ],
    targets: [
        .target(name: "DreamEchoApp", path: "Sources"),
        .testTarget(name: "DreamEchoAppTests", dependencies: ["DreamEchoApp"], path: "Tests")
    ]
)
