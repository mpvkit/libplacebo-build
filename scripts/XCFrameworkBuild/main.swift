import Foundation

do {
    try Build.performCommand(arguments: Array(CommandLine.arguments.dropFirst()))

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
            return "v1.2.9"
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
            return "https://github.com/cxfksword/libdovi-build/releases/download/\(self.version)/libdovi-all.zip"
        case .vulkan:
            return "https://github.com/KhronosGroup/MoltenVK"
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
            "-Dvulkan=enabled", 
            "-Dshaderc=enabled", 
            // "-Dglslang=enabled",
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

        // // switch to main branch, to pull newest code
        // try! Utility.launch(path: "/usr/bin/git", arguments: ["remote", "set-branches", "--add", "origin", "main"], currentDirectoryURL: directoryURL)
        // try! Utility.launch(path: "/usr/bin/git", arguments: ["fetch", "origin", "main:main"], currentDirectoryURL: directoryURL)
        // try! Utility.launch(path: "/usr/bin/git", arguments: ["checkout", "main"], currentDirectoryURL: directoryURL)
    }

    override func buildALL() throws {
        // // build from source code
        // let version = self.library.version.trimmingCharacters(in: CharacterSet(charactersIn: "v"))
        // var arguments = platforms().map {
        //     "--\($0.name)"
        // }
        // try Utility.launch(path: (directoryURL + "fetchDependencies").path, arguments: arguments, currentDirectoryURL: directoryURL)
        // arguments = platforms().map(\.name)
        // try Utility.launch(path: "/usr/bin/make", arguments: arguments, currentDirectoryURL: directoryURL)
        // try? FileManager.default.removeItem(at: URL.currentDirectory + "../Sources/MoltenVK.xcframework")
        // try? FileManager.default.copyItem(at: directoryURL + "Package/Release/MoltenVK/MoltenVK.xcframework", to: URL.currentDirectory + "../Sources/MoltenVK.xcframework")

        // compile is very slow, change to use github action build xciframework
        let version = self.library.version.trimmingCharacters(in: CharacterSet(charactersIn: "v"))
        let downloadUrl = "https://github.com/KhronosGroup/MoltenVK/releases/download/v\(version)/MoltenVK-all.tar"
        let packageURL = directoryURL + "Package/"
        let releaseURL = packageURL + "Release/"
        try? FileManager.default.removeItem(at: releaseURL)
        try? FileManager.default.createDirectory(at: packageURL, withIntermediateDirectories: true)
        Utility.shell("wget \(downloadUrl) -q -O MoltenVK-all.tar", currentDirectoryURL: packageURL)
        Utility.shell("tar xvf MoltenVK-all.tar", currentDirectoryURL: packageURL)
        try? FileManager.default.moveItem(at: packageURL + "MoltenVK", to: releaseURL)
        let oldXcframework = URL.currentDirectory + "../Sources/MoltenVK.xcframework"
        let newXcframework = releaseURL + "MoltenVK/static/MoltenVK.xcframework"
        if FileManager.default.fileExists(atPath: newXcframework.path) {
            try? FileManager.default.removeItem(at: oldXcframework)
            try? FileManager.default.copyItem(at: newXcframework, to: oldXcframework)
        } else {
            throw NSError(domain: "xcframework not found", code: -1)
        }

        for platform in platforms() {
            var frameworks = ["CoreFoundation", "CoreGraphics", "Foundation", "IOSurface", "Metal", "QuartzCore"]
            if platform == .macos {
                frameworks.append("Cocoa")
            } 
            if platform != .macos {
                frameworks.append("UIKit")
            }
            if !(platform == .tvos || platform == .tvsimulator) {
                frameworks.append("IOKit")
            }
            let libframework = frameworks.map {
                "-framework \($0)"
            }.joined(separator: " ")
            for arch in platform.architectures {
                let prefix = thinDir(platform: platform, arch: arch) + "/lib/pkgconfig"
                try? FileManager.default.removeItem(at: prefix)
                try? FileManager.default.createDirectory(at: prefix, withIntermediateDirectories: true, attributes: nil)
                let vulkanPC = prefix + "vulkan.pc"

                let content = """
                prefix=\((directoryURL + "Package/Release/MoltenVK").path)
                includedir=${prefix}/include
                libdir=${prefix}/static/MoltenVK.xcframework/\(platform.frameworkName)

                Name: Vulkan-Loader
                Description: Vulkan Loader
                Version: \(version)
                Libs: -L${libdir} -lMoltenVK \(libframework)
                Cflags: -I${includedir}
                """
                FileManager.default.createFile(atPath: vulkanPC.path, contents: content.data(using: .utf8), attributes: nil)
            }
        }
    }
}
