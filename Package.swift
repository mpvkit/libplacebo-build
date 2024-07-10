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
            url: "https://github.com/mpvkit/libplacebo-build/releases/download/7.349.0/Libplacebo.xcframework.zip",
            checksum: "0b3675d6ee7b763461a2513f47ad020fd01883625ff0c18f885ed6866a0ea265"
        ),
        .binaryTarget(
            name: "lcms2",
            url: "https://github.com/mpvkit/libplacebo-build/releases/download/7.349.0/lcms2.xcframework.zip",
            checksum: "92c1ba6965697a72fec68d3d019dfd22b70daa67def2f845303715315e30a349"
        )
    ]
)
