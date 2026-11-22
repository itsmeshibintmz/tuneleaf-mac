// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Tuneleaf",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "Tuneleaf"),
        .testTarget(name: "TuneleafTests", dependencies: ["Tuneleaf"])
    ]
)
