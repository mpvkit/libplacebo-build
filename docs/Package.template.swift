// swift-tools-version:5.8

import PackageDescription

let package = Package(
    name: "libplacebo",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13)],
    products: [
        .library(
            name: "Libplacebo", 
            targets: ["Libplacebo"]
        ),
        .library(
            name: "lcms2", 
            targets: ["lcms2"]
        ),
    ],
    targets: [
        .binaryTarget(
            name: "Libplacebo",
            url: "\(Libplacebo_url)",
            checksum: "\(Libplacebo_checksum)"
        ),
        .binaryTarget(
            name: "lcms2",
            url: "\(lcms2_url)",
            checksum: "\(lcms2_checksum)"
        )
    ]
)
