// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "swift-example",
    dependencies: [],
    targets: [
        .executableTarget(
            name: "swift-example",
            dependencies: []
        ),
        .testTarget(
            name: "swift-exampleTests",
            dependencies: ["swift-example"]
        )
    ]
)
