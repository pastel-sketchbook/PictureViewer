// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "PictureViewer",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "PictureViewer",
            path: "Sources/PictureViewer",
            resources: [
                .copy("Resources/Fonts"),
                .copy("Resources/Icons"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        )
    ]
)
