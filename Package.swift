// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MyVoiceAssistant",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "MyVoiceAssistant",
            path: "Sources/MyVoiceAssistant",
            resources: [
                .copy("../../Resources/Info.plist")
            ]
        )
    ]
)
