import Foundation
import ArgumentParser

struct CreateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Scaffold a new LeetCode challenge from its URL slug."
    )

    @Argument(help: "The LeetCode URL slug of the challenge (e.g. 'two-sum').")
    var slug: String

    @Flag(
        name: [.customLong("local"), .customLong("offline")],
        help: "Scaffold without fetching from LeetCode (useful offline or when rate-limited)."
    )
    var isLocal: Bool = false

    @Flag(
        name: .customLong("force"),
        help: "Delete and recreate an existing challenge directory."
    )
    var isForce: Bool = false

    mutating func validate() throws {
        slug = slug.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !slug.isEmpty else {
            throw ValidationError("Slug cannot be empty.")
        }
        let isValid = slug.allSatisfy { $0.isLetter || $0.isNumber || $0 == "-" }
        guard isValid else {
            throw ValidationError(
                "Invalid slug '\(slug)'. Slugs must contain only lowercase letters, digits, and hyphens (e.g. 'longest-common-prefix')."
            )
        }
    }

    func run() async throws {
        // slug is already normalized by validate()
        let provider: any LeetCodeMetadataProvider = isLocal
            ? LocalMetadataProvider()
            : OnlineMetadataProvider()

        print("🚀 Setting up LeetCode challenge: \(slug)...")

        let metadata: ProblemMetadata
        do {
            metadata = try await provider.fetchMetadata(for: slug)
        } catch {
            if !isLocal {
                print("❌ Error: Failed to fetch metadata from LeetCode.")
                print("   Reason: \(error.localizedDescription)")
                print("💡 Suggestion: If you're offline or rate-limited, run with '--local' or '--offline'.")
                print("   Example: leetswift create \(slug) --local")
            } else {
                print("❌ Critical Error: \(error.localizedDescription)")
            }
            throw ExitCode.failure
        }

        let generator = TemplateGenerator()
        let schema = generator.parseSchema(from: metadata)

        let isSelectiveRefresh = try generator.createSetup(
            for: slug,
            metadata: metadata,
            schema: schema,
            force: isForce
        )

        if !isSelectiveRefresh {
            let projectRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            try ChallengeRegistrar.register(
                slug: slug,
                camelCaseName: metadata.camelCaseName,
                projectRoot: projectRoot
            )
            print("✅ Setup complete! Reload your Xcode project or run 'leetswift list' to see the new challenge.")
        } else {
            print("✅ Selective refresh complete! Metadata updated successfully.")
        }
    }
}
