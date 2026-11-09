// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PrintClockKit",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "PrintClockKit", targets: ["PrintClockKit"])
    ],
    targets: [
        .target(name: "PrintClockKit"),
        .testTarget(
            name: "PrintClockKitTests",
            dependencies: ["PrintClockKit"]
        )
    ]
)
