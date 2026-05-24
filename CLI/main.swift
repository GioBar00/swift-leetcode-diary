import Foundation
import ArgumentParser

struct LeetSwift: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "leetswift",
        abstract: "🚀 LeetCode Swift Diary CLI Tool for local execution, parameterized testing, and high-fidelity benchmarks.",
        subcommands: [
            ListCommand.self,
            RunCommand.self,
            BenchmarkCommand.self,
            TestCommand.self,
            CreateCommand.self
        ],
        defaultSubcommand: ListCommand.self
    )
}

await { await LeetSwift.main() }()
