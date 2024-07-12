import Foundation
import Darwin

do {
    let options = try ArgumentOptions.parse(CommandLine.arguments)
    try Build.performCommand(options)

    try BuildLittleCms().buildALL()
    try BuildDovi().buildALL()
    try BuildShaderc().buildALL()
    try BuildVulkan().buildALL()
    try BuildPlacebo().buildALL()
} catch {
    print(error.localizedDescription)
    exit(1)
}


enum Library: String, CaseIterable {
    case libshaderc, vulkan, lcms2, libdovi, libplacebo
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
        case .libplacebo:
            return "https://github.com/haasn/libplacebo"
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



private class BuildVulkan: BaseBuild {
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
                let srcPkgConfigPath = directoryURL + ["pkgconfig-example"]
                let destPkgConfigPath = destThinPath + ["lib", "pkgconfig"]
                try? FileManager.default.copyItem(at: srcPkgConfigPath, to: destPkgConfigPath)

                // update pkgconfig prefix
                Utility.listAllFiles(in: destPkgConfigPath).forEach { file in
                    if let data = FileManager.default.contents(atPath: file.path), var str = String(data: data, encoding: .utf8) {
                        str = str.replacingOccurrences(of: "/path/to/workdir", with: URL.currentDirectory.path)
                        str = str.replacingOccurrences(of: "/path/to/thin/platform", with:  "/\(platform.rawValue)/thin/\(arch.rawValue)")
                        try! str.write(toFile: file.path, atomically: true, encoding: .utf8)
                    }
                }
            }
        }
    }
}
