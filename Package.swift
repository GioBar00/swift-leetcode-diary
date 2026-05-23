// swift-tools-version: 6.0
import PackageDescription
import Foundation

// MARK: - Dynamic File Exclusion to Keep Build 100% Warning-Free
// Since we want this repository to be a clean template that others can clone and add unlimited
// LeetCode problems to, we dynamically scan and exclude markdown files, JSON benchmark metrics,
// and raw text test input files from being compiled.
let packageDir = URL(fileURLWithPath: #filePath).deletingLastPathComponent().path

func discoverExcludes(in subDirectory: String, extensions: [String]) -> [String] {
    let fileManager = FileManager.default
    let targetPath = packageDir + "/" + subDirectory
    var excludes: [String] = []
    
    guard let enumerator = fileManager.enumerator(atPath: targetPath) else { return [] }
    while let relativePath = enumerator.nextObject() as? String {
        let fileURL = URL(fileURLWithPath: relativePath)
        if extensions.contains(fileURL.pathExtension) {
            excludes.append(relativePath)
        }
    }
    return excludes.sorted()
}

let coreExcludes = discoverExcludes(in: "Sources/leetcodes", extensions: ["md", "json"])
let testExcludes = discoverExcludes(in: "Tests/leetcodesTests", extensions: ["txt", "json"])

// MARK: - Package Definition
let package = Package(
    name: "swift-leetcode-diary",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "leetcodes", targets: ["leetcodes"]),
        .executable(name: "leetswift", targets: ["leetswift"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0")
    ],
    targets: [
        .target(
            name: "leetcodes",
            dependencies: [],
            path: "Sources/leetcodes",
            exclude: coreExcludes
        ),
        .executableTarget(
            name: "leetswift",
            dependencies: [
                "leetcodes",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "CLI"
        ),
        .testTarget(
            name: "leetcodesTests",
            dependencies: ["leetcodes"],
            path: "Tests/leetcodesTests",
            exclude: testExcludes
        )
    ]
)
