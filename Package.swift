// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "QRCodeReader",
    platforms: [
        .iOS(.v10),
    ],
    products: [
        .library(name: "QRCodeReader", targets: ["QRCodeReader"]),
    ],
    dependencies: [
        .package(url: "https://github.com/dnpp73/GPUCIImageView", .upToNextMinor(from: "0.1.0")),
        .package(url: "https://github.com/dnpp73/SimpleCamera", .upToNextMinor(from: "0.1.1")),
    ],
    targets: [
        .target(
            name: "QRCodeReader",
            dependencies: ["GPUCIImageView", "SimpleCamera"],
            path: "Sources"
        ),
    ]
)
