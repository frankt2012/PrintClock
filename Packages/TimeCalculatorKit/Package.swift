// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TimeCalculatorKit",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "TimeCalculatorKit", targets: ["TimeCalculatorKit"])
    ],
    targets: [
        .target(name: "TimeCalculatorKit"),
        .testTarget(
            name: "TimeCalculatorKitTests",
            dependencies: ["TimeCalculatorKit"]
        )
    ]
)
