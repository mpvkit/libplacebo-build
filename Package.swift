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
            checksum: "6b06349690b08aac64c2724d35b925fe18504757b67de5004a4af4b2eaae1981"
        ),
        .binaryTarget(
            name: "lcms2",
            url: "https://github.com/mpvkit/libplacebo-build/releases/download/7.349.0/lcms2.xcframework.zip",
            checksum: "bd2816cfb6b1e6929bd6d04e95ee2b6f7cc905b5a83e1b36c19995785e969c66"
        )
    ]
)
