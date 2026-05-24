import Foundation
import ArgumentParser
import leetcodes

struct ListCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List all available LeetCode challenges."
    )
    
    func run() throws {
        print("💡 Available LeetCode Challenges")
        print("==================================================================")
        
        let sortedChallenges = ChallengeRegistry.challenges.values.sorted { $0.slug < $1.slug }
        
        guard !sortedChallenges.isEmpty else {
            print("No challenges registered yet. Use 'create.swift' to add one!")
            return
        }
        
        for (index, challenge) in sortedChallenges.enumerated() {
            let numStr = String(format: "%02d.", index + 1)
            print("  \(numStr) \(challenge.name) [\(challenge.slug)]")
        }
        
        print("==================================================================")
        print("Run one with: leetswift run <slug-or-path>")
        print("Test one with: leetswift test <slug-or-path>")
        print("Benchmark one with: leetswift benchmark <slug-or-path>")
        print("Create a new one with: leetswift create <slug>")
    }
}
