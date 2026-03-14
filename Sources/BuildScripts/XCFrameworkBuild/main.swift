import Foundation
import BuildShared

do {
    let options = try BuildRunner.performCommand()

    try BuildLittleCms(options: options).buildALL()
    try BuildDovi(options: options).buildALL()
    try BuildShaderc(options: options).buildALL()
    try BuildVulkan(options: options).buildALL()
    try BuildSpirvCross(options: options).buildALL()
    try BuildPlacebo(options: options).buildALL()
} catch {
    print(error.localizedDescription)
    exit(1)
}


enum Library: String, CaseIterable, BuildLibrary {
    case libshaderc, vulkan, lcms2, libdovi, spirvcross, libplacebo
    
    var version: String {
        switch self {
        case .lcms2:
            return "2.17.0"
        case .libdovi:
            return "3.3.2"
        case .vulkan:
            return "1.4.1"
        case .libshaderc:  // compiling GLSL (OpenGL Shading Language) shaders into SPIR-V (Standard Portable Intermediate Representation - Vulkan) code
            return "2025.5.0"
        case .spirvcross:  // parsing and converting SPIR-V to other shader languages.
            return "vulkan-sdk-1.4.309.0"
        case .libplacebo:
            return "v7.360.1"
        }
    }

    var url: String {
        switch self {
        case .lcms2:
            return "https://github.com/mpvkit/lcms2-build/releases/download/\(self.version)/lcms2-all.zip"
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

    var targets: [PackageTarget] {
        switch self {
        case .lcms2:
            return [
                .target(
                    name: "lcms2",
                    url: "https://github.com/mpvkit/lcms2-build/releases/download/\(self.version)/lcms2.xcframework.zip",
                    checksum: "https://github.com/mpvkit/lcms2-build/releases/download/\(self.version)/lcms2.xcframework.checksum.txt"
                ),
            ]
        case .libdovi:
            return [
                .target(
                    name: "Libdovi",
                    url: "https://github.com/mpvkit/libdovi-build/releases/download/\(self.version)/Libdovi.xcframework.zip",
                    checksum: "https://github.com/mpvkit/libdovi-build/releases/download/\(self.version)/Libdovi.xcframework.checksum.txt"
                ),
            ]
        case .vulkan:
            return [
                .target(
                    name: "MoltenVK",
                    url: "https://github.com/mpvkit/moltenvk-build/releases/download/\(self.version)/MoltenVK.xcframework.zip",
                    checksum: "https://github.com/mpvkit/moltenvk-build/releases/download/\(self.version)/MoltenVK.xcframework.checksum.txt"
                ),
            ]
        case .libshaderc:
            return [
                .target(
                    name: "Libshaderc_combined",
                    url: "https://github.com/mpvkit/libshaderc-build/releases/download/\(self.version)/Libshaderc_combined.xcframework.zip",
                    checksum: "https://github.com/mpvkit/libshaderc-build/releases/download/\(self.version)/Libshaderc_combined.xcframework.checksum.txt"
                ),
            ]
        case .libplacebo:
            return [
                .target(
                    name: "Libplacebo",
                    url: "https://github.com/mpvkit/libplacebo-build/releases/download/\(BuildRunner.options!.releaseVersion)/Libplacebo.xcframework.zip",
                    checksum: "https://github.com/mpvkit/libplacebo-build/releases/download/\(BuildRunner.options!.releaseVersion)/Libplacebo.xcframework.checksum.txt"
                ),
            ]
        default:
            return []
        }
    }
}


private class BuildPlacebo: BaseBuild {
    init(options: ArgumentOptions) {
        super.init(library: Library.libplacebo, options: options)
    }

    override func beforeBuild() throws {
        try super.beforeBuild()

        
        // // switch to master branch, to pull newest code
        // try! Utility.launch(path: "/usr/bin/git", arguments: ["remote", "set-branches", "--add", "origin", "master"], currentDirectoryURL: directoryURL)
        // try! Utility.launch(path: "/usr/bin/git", arguments: ["fetch", "origin", "master:master"], currentDirectoryURL: directoryURL)
        // try! Utility.launch(path: "/usr/bin/git", arguments: ["checkout", "master"], currentDirectoryURL: directoryURL)

        // pull all submodules
        Utility.shell("git submodule update --init --recursive", currentDirectoryURL: directoryURL)
  
        // install jinja2 for distutils dependency
        if Utility.shell("python3 -m pip list|grep jinja2") == nil {
            Utility.shell("python3 -m pip install jinja2")
        }
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

    override func flagsDependencelibrarys() -> [any BuildLibrary] {
        [Library.libdovi]
    }
}


private class BuildSpirvCross: BaseBuild {
    init(options: ArgumentOptions) {
        super.init(library: Library.spirvcross, options: options)
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

    override func arguments(platform: PlatformType, arch: ArchType) -> [String] {
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


private class BuildLittleCms: ZipBaseBuild {
    init(options: ArgumentOptions) {
        super.init(library: Library.lcms2, options: options)
    }
}

private class BuildDovi: ZipBaseBuild {
    init(options: ArgumentOptions) throws {
        super.init(library: Library.libdovi, options: options)
    }
}

private class BuildShaderc: ZipBaseBuild {
    init(options: ArgumentOptions) throws {
        super.init(library: Library.libshaderc, options: options)
    }
}


private class BuildVulkan: ZipBaseBuild {
    init(options: ArgumentOptions) {
        super.init(library: Library.vulkan, options: options)
    }

    override func buildALL() throws {
        try self.beforeBuild()
        try? FileManager.default.removeItem(at: URL.currentDirectory + library.rawValue)
        try? FileManager.default.removeItem(at: directoryURL.appendingPathExtension("log"))
        try? FileManager.default.createDirectory(atPath: (URL.currentDirectory + library.rawValue).path, withIntermediateDirectories: true, attributes: nil)
        for platform in platforms() {
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

        try self.afterBuild()
    }
}
