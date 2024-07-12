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
            checksum: "1d7b374bb714b082a6c9aa678c7eee97301e0f1ca935706a43d40a868c250cb0"
        ),
        .binaryTarget(
            name: "lcms2",
            url: "https://github.com/mpvkit/libplacebo-build/releases/download/7.349.0/lcms2.xcframework.zip",
            checksum: "0f86ed24779fc1bfa990407a7250f4000c5ab5233864107d8e4112e19fdd6211"
        )
    ]
)
