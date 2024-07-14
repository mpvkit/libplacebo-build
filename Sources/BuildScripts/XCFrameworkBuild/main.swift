import Foundation
import Darwin

do {
    let options = try ArgumentOptions.parse(CommandLine.arguments)
    try Build.performCommand(options)

    try BuildLittleCms().buildALL()
    try BuildDovi().buildALL()
    try BuildShaderc().buildALL()
    try BuildVulkan().buildALL()
    try BuildSpirvCross().buildALL()
    try BuildPlacebo().buildALL()
} catch {
    print(error.localizedDescription)
    exit(1)
}


enum Library: String, CaseIterable {
    case libshaderc, vulkan, lcms2, libdovi, spirvcross, libplacebo
    var version: String {
        switch self {
        case .lcms2:
            return "lcms2.16"
        case .libdovi:
            return "v3.3.0"
        case .vulkan:
            return "1.2.9"
        case .libshaderc:  // compiling GLSL (OpenGL Shading Language) shaders into SPIR-V (Standard Portable Intermediate Representation - Vulkan) code
            return "2024.1.0"
        case .spirvcross:  // parsing and converting SPIR-V to other shader languages.
            return "vulkan-sdk-1.3.268.0"
        case .libplacebo:
            return "v7.349.0"
        }
    }

    var url: String {
        switch self {
        case .lcms2:
            return "https://github.com/mm2/Little-CMS"
        case .libdovi:
            return "https://github.com/mpvkit/libdovi-build/releases/download/\(self.version)/libdovi-all.zip"
        case .vulkan:
            return "https://github.com/mpvkit/moltenvk-build/releases/download/\(self.version)/MoltenVK-all.zip"
        case .libshaderc:
            return "https://github.com/mpvkit/libshaderc-build/releases/download/\(self.version)/libshaderc-all.zip"
        case .spirvcross:
            return "https://github.com/KhronosGroup/SPIRV-Cross"
        case .libplacebo:
            return "https://github.com/haasn/libplacebo"
        }
    }


    // for generate Package.swift
    var targets : [PackageTarget] {
        switch self {
        case .lcms2:
            return  [
                .target(
                    name: "lcms2",
                    url: "https://github.com/mpvkit/libplacebo-build/releases/download/\(BaseBuild.options.releaseVersion)/lcms2.xcframework.zip",
                    checksum: "https://github.com/mpvkit/libplacebo-build/releases/download/\(BaseBuild.options.releaseVersion)/lcms2.xcframework.checksum.txt"
                ),
            ]
        case .libdovi:
            return  [
                .target(
                    name: "Libdovi",
                    url: "https://github.com/mpvkit/libdovi-build/releases/download/\(self.version)/Libdovi.xcframework.zip",
                    checksum: "https://github.com/mpvkit/libdovi-build/releases/download/\(self.version)/Libdovi.xcframework.checksum.txt"
                ),
            ]
        case .vulkan:
            return  [
                .target(
                    name: "MoltenVK",
                    url: "https://github.com/mpvkit/moltenvk-build/releases/download/\(self.version)/MoltenVK.xcframework.zip",
                    checksum: "https://github.com/mpvkit/moltenvk-build/releases/download/\(self.version)/MoltenVK.xcframework.checksum.txt"
                ),
            ]
        case .libshaderc:
            return  [
                .target(
                    name: "Libshaderc",
                    url: "https://github.com/mpvkit/libshaderc-build/releases/download/\(self.version)/Libshaderc.xcframework.zip",
                    checksum: "https://github.com/mpvkit/libshaderc-build/releases/download/\(self.version)/Libshaderc.xcframework.checksum.txt"
                ),
            ]
        case .libplacebo:
            return  [
                .target(
                    name: "Libplacebo",
                    url: "https://github.com/mpvkit/libplacebo-build/releases/download/\(BaseBuild.options.releaseVersion)/Libplacebo.xcframework.zip",
                    checksum: "https://github.com/mpvkit/libplacebo-build/releases/download/\(BaseBuild.options.releaseVersion)/Libplacebo.xcframework.checksum.txt"
                ),
            ]
        default:
            return []
        }
    }
}



private class BuildPlacebo: BaseBuild {
    init() {
        super.init(library: .libplacebo)
        
        // // switch to master branch, to pull newest code
        // try! Utility.launch(path: "/usr/bin/git", arguments: ["remote", "set-branches", "--add", "origin", "master"], currentDirectoryURL: directoryURL)
        // try! Utility.launch(path: "/usr/bin/git", arguments: ["fetch", "origin", "master:master"], currentDirectoryURL: directoryURL)
        // try! Utility.launch(path: "/usr/bin/git", arguments: ["checkout", "master"], currentDirectoryURL: directoryURL)

        // pull all submodules
        Utility.shell("git submodule update --init --recursive", currentDirectoryURL: directoryURL)
    }

    override func arguments(platform: PlatformType, arch: ArchType) -> [String] {
        var args = [
            "-Dopengl=enabled", 
            "-Dvulkan=enabled", 
            "-Dshaderc=enabled",
            "-Dlcms=enabled", 
            
            "-Dxxhash=disabled", 
            "-Dunwind=disabled", 
            "-Dglslang=disabled",
            "-Dd3d11=disabled",
            "-Ddemos=false",
            "-Dtests=false",
        ]

        let path = URL.currentDirectory + [Library.libdovi.rawValue, platform.rawValue, "thin", arch.rawValue]
        if FileManager.default.fileExists(atPath: path.path) {
            args += ["-Ddovi=enabled", "-Dlibdovi=enabled"]
        } else {
            args += ["-Ddovi=disabled", "-Dlibdovi=disabled"]
        }
        return args
    }

    override func flagsDependencelibrarys() -> [Library] {
        [.libdovi]
    }
}


private class BuildSpirvCross: BaseBuild {
    init() {
        super.init(library: .spirvcross)
    }


    override func build(platform: PlatformType, arch: ArchType) throws {
        try super.build(platform: platform, arch: arch)

        let prefix = thinDir(platform: platform, arch: arch)
        let version = self.library.version.replacingOccurrences(of: "vulkan-sdk-", with: "").replacingOccurrences(of: "sdk-", with: "")
        let pcDir = prefix + "/lib/pkgconfig"
        try? FileManager.default.removeItem(at: pcDir)
        try? FileManager.default.createDirectory(at: pcDir, withIntermediateDirectories: true, attributes: nil)
        let pc = pcDir + "spirv-cross-c-shared.pc"

        let content = """
        prefix=\(prefix.path)
        exec_prefix=${prefix}
        includedir=${prefix}/include/spirv_cross
        libdir=${prefix}/lib

        Name: spirv-cross-c-shared
        Description: C API for SPIRV-Cross
        Version: \(version)
        Libs: -L${libdir} -lspirv-cross-c -lspirv-cross-glsl -lspirv-cross-hlsl -lspirv-cross-reflect -lspirv-cross-msl -lspirv-cross-util -lspirv-cross-core -lstdc++
        Cflags: -I${includedir}
        """
        FileManager.default.createFile(atPath: pc.path, contents: content.data(using: .utf8), attributes: nil)
    }

    override func arguments(platform _: PlatformType, arch _: ArchType) -> [String] {
        [
            "-DSPIRV_CROSS_SHARED=OFF",
            "-DSPIRV_CROSS_STATIC=ON", 
            "-DSPIRV_CROSS_CLI=OFF", 
            "-DSPIRV_CROSS_ENABLE_TESTS=OFF",
            "-DSPIRV_CROSS_FORCE_PIC=ON", 
            "-Ddemos=false-DSPIRV_CROSS_ENABLE_CPP=OFF"
        ]
    }

    override func frameworks() throws -> [String] {
        // ignore generate xci framework
        return []
    }
}


private class BuildLittleCms: BaseBuild {
    init() {
        super.init(library: .lcms2)
    }
}

private class BuildDovi: ZipBaseBuild {
    init() throws {
        super.init(library: .libdovi)
    }
}

private class BuildShaderc: ZipBaseBuild {
    init() throws {
        super.init(library: .libshaderc)
    }
}


private class BuildVulkan: ZipBaseBuild {
    init() {
        super.init(library: .vulkan)
    }

    override func buildALL() throws {
        try? FileManager.default.removeItem(at: URL.currentDirectory + library.rawValue)
        try? FileManager.default.removeItem(at: directoryURL.appendingPathExtension("log"))
        try? FileManager.default.createDirectory(atPath: (URL.currentDirectory + library.rawValue).path, withIntermediateDirectories: true, attributes: nil)
        for platform in BaseBuild.platforms {
            for arch in architectures(platform) {
                // restore lib
                let srcThinLibPath = directoryURL + ["lib", "MoltenVK.xcframework", platform.frameworkName]
                let destThinPath = thinDir(platform: platform, arch: arch)
                let destThinLibPath = destThinPath + ["lib"]
                try? FileManager.default.createDirectory(atPath: destThinPath.path, withIntermediateDirectories: true, attributes: nil)
                try? FileManager.default.copyItem(at: srcThinLibPath, to: destThinLibPath)

                // restore include
                let srcIncludePath = directoryURL + ["include"]
                let destIncludePath = destThinPath + ["include"]
                try? FileManager.default.copyItem(at: srcIncludePath, to: destIncludePath)

                // restore pkgconfig
                let srcPkgConfigPath = directoryURL + ["pkgconfig-example", platform.rawValue, arch.rawValue]
                let destPkgConfigPath = destThinPath + ["lib", "pkgconfig"]
                try? FileManager.default.copyItem(at: srcPkgConfigPath, to: destPkgConfigPath)
                Utility.listAllFiles(in: destPkgConfigPath).forEach { file in
                    if let data = FileManager.default.contents(atPath: file.path), var str = String(data: data, encoding: .utf8) {
                        str = str.replacingOccurrences(of: "/path/to/workdir", with: URL.currentDirectory.path)
                        try! str.write(toFile: file.path, atomically: true, encoding: .utf8)
                    }
                }
            }
        }
    }
}
