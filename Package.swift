// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "Aquarium",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Aquarium", targets: ["Aquarium"]),
    ],
    targets: [
        .executableTarget(name: "Aquarium"),
        .testTarget(
            name: "AquariumTests",
            dependencies: ["Aquarium"]
        ),
    ]
)
