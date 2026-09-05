// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "LabelProofCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "LabelProofCore",
            targets: ["LabelProofCore"]
        )
    ],
    targets: [
        .target(
            name: "LabelProofCore",
            dependencies: [],
            path: "Sources/LabelProofCore"
        ),
        .testTarget(
            name: "LabelProofCoreTests",
            dependencies: ["LabelProofCore"],
            path: "Tests/LabelProofCoreTests"
        )
    ]
)
