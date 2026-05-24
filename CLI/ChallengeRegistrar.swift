import Foundation

// MARK: - Challenge Registrar

enum ChallengeRegistrar {
    /// Inserts `slug: CamelCaseName.self` into ChallengeRegistry.swift if not already present.
    static func register(slug: String, camelCaseName: String, projectRoot: URL) throws {
        let registryURL = projectRoot
            .appendingPathComponent("Sources")
            .appendingPathComponent("leetcodes")
            .appendingPathComponent("Shared")
            .appendingPathComponent("ChallengeRegistry.swift")

        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: registryURL.path) else {
            print("⚠️ Warning: ChallengeRegistry.swift not found at \(registryURL.path). Skipped auto-registration.")
            return
        }

        var content = try String(contentsOf: registryURL, encoding: .utf8)

        guard !content.contains("\"\(slug)\":") else {
            print("ℹ️ Challenge '\(slug)' is already registered in ChallengeRegistry.swift.")
            return
        }

        // Anchor on the dictionary literal — tightened to avoid false positives
        let pattern = #"challenges:\s*\[String:\s*any LeetCodeChallenge\.Type\]\s*=\s*\["#
        if let range = content.range(of: pattern, options: .regularExpression) {
            let entry = "\n        \"\(slug)\": \(camelCaseName).self,"
            content.insert(contentsOf: entry, at: range.upperBound)
            try content.write(to: registryURL, atomically: true, encoding: .utf8)
            print("✏️ Automatically registered '\(slug)' in ChallengeRegistry.swift")
        } else {
            print("⚠️ Warning: Could not locate the challenges dictionary in ChallengeRegistry.swift. Please register manually.")
        }
    }
}
