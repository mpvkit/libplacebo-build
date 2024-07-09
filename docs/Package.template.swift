// swift-tools-version:5.8

import PackageDescription

let package = Package(
    name: "libplacebo",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13)],
    products: [
        .library(
            name: "libplacebo", 
            targets: ["Libplacebo", "Libshaderc_combined", "MoltenVK", "Libdovi", "lcms2"]
        ),
    ],
    targets: [
        .binaryTarget(
            name: "Libplacebo",
            url: "\(Libplacebo_url)",
            checksum: "\(Libplacebo_checksum)"
        ),
        .binaryTarget(
            name: "Libshaderc_combined",
            url: "\(Libshaderc_combined_url)",
            checksum: "\(Libshaderc_combined_checksum)"
        ),
        .binaryTarget(
            name: "MoltenVK",
            url: "\(MoltenVK_url)",
            checksum: "\(MoltenVK_checksum)"
        ),
        .binaryTarget(
            name: "Libdovi",
            url: "\(Libdovi_url)",
            checksum: "\(Libdovi_checksum)"
        ),
        .binaryTarget(
            name: "lcms2",
            url: "\(lcms2_url)",
            checksum: "\(lcms2_checksum)"
        )
    ]
)
