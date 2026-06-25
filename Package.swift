// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "ShortcutCoach",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "ShortcutCoach", targets: ["ShortcutCoach"]),
        .executable(name: "ShortcutCoachChecks", targets: ["ShortcutCoachChecks"])
    ],
    targets: [
        // Shared library with models, services, and support logic.
        .target(
            name: "ShortcutCoachCore",
            resources: [
                .process("Resources")
            ]
        ),
        // macOS SwiftUI menu-bar app.
        .executableTarget(
            name: "ShortcutCoach",
            dependencies: ["ShortcutCoachCore"],
            resources: [
                .process("Resources")
            ]
        ),
        // Lightweight non-XCTest check runner.
        .executableTarget(
            name: "ShortcutCoachChecks",
            dependencies: ["ShortcutCoachCore"]
        )
    ]
)
