// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "Chat",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "ExyteChat",
            targets: ["ExyteChat"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/exyte/MediaPicker.git",
            from: "3.4.4"
        ),
        .package(
            url: "https://github.com/exyte/AnchoredPopup.git",
            from: "1.1.3"
        ),
        .package(
            url: "https://github.com/exyte/SVGView.git",
            from: "1.0.6"
        ),
    ],
    targets: [
        .target(
            name: "ExyteChat",
            dependencies: [
                .product(name: "ExyteMediaPicker", package: "MediaPicker"),
                .product(name: "AnchoredPopup", package: "AnchoredPopup"),
                .product(name: "SVGView", package: "SVGView"),
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
                .enableUpcomingFeature("BareSlashRegexLiterals")
            ]
        ),
        .testTarget(
            name: "ExyteChatTests",
            dependencies: ["ExyteChat"]),
    ],
    swiftLanguageModes: [.v5]
)
