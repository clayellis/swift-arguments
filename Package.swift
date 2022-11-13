// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "swift-arguments",
    products: [
        .library(
            name: "Arguments",
            targets: ["Arguments"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(name: "Arguments", dependencies: []),
        .testTarget(name: "ArgumentsTests", dependencies: ["Arguments"])
    ]
)
