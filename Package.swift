// swift-tools-version: 5.9
import Foundation
import PackageDescription

let packageDir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
let npmArtifacts = ["node_modules", "dist"].filter {
    FileManager.default.fileExists(atPath: packageDir.appendingPathComponent($0).path)
}

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
            // Rooted at the repo so locales/ is bundled directly. A symlink into Sources/ breaks on older toolchains, which copy the link itself
            path: ".",
            exclude: [
                "Tests", "scripts", "src", "LICENSE", "README.md", "package.json", "pnpm-lock.yaml",
                "tsconfig.json", "tsup.config.ts",
            ] + npmArtifacts,
            sources: ["Sources/PelagicaI18n"],
            resources: [.copy("locales")]
        ),
        .testTarget(
            name: "PelagicaI18nTests",
            dependencies: ["PelagicaI18n"],
            path: "Tests/PelagicaI18nTests",
            resources: [.copy("Fixtures")]
        ),
    ]
)
