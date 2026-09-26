// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PelagicaI18n",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v15),
        .tvOS(.v15),
        .macOS(.v12),
        .watchOS(.v8),
    ],
    products: [
        .library(name: "PelagicaI18n", targets: ["PelagicaI18n"]),
    ],
    targets: [
        .target(
            name: "PelagicaI18n",
            // Symlink to ../../locales
            resources: [.copy("Resources")]
        ),
        .testTarget(
            name: "PelagicaI18nTests",
            dependencies: ["PelagicaI18n"],
            resources: [.copy("Fixtures")]
        ),
    ]
)
