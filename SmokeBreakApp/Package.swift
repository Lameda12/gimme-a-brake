// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SmokeBreak",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "SmokeBreak",
            path: "Sources/SmokeBreak",
            resources: [
                .copy("../../Resources/claudecode-color.svg"),
                .copy("../../Resources/codex-color.svg"),
                .copy("../../Resources/smoking.gif"),
                .copy("../../Resources/Sounds")
            ]
        )
    ]
)
