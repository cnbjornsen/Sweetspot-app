// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SweetSpotKit",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10),
    ],
    products: [
        .library(name: "SweetSpotKit", targets: ["SweetSpotKit"]),
    ],
    targets: [
        .target(
            name: "SweetSpotKit",
            path: "Sources/SweetSpotKit"
        ),
        .testTarget(
            name: "SweetSpotKitTests",
            dependencies: ["SweetSpotKit"],
            path: "Tests/SweetSpotKitTests"
        ),
    ]
)
