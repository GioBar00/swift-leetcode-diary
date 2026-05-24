import Foundation

// MARK: - Template Generator

struct TemplateGenerator {
    private let fileManager = FileManager.default
    private let currentDirectory: URL

    init() {
        self.currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
    }

    // MARK: - Schema Parsing

    func parseSchema(from metadata: ProblemMetadata) -> LeetCodeMetaDataSchema? {
        guard let jsonString = metadata.metaDataJson,
              let data = jsonString.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(LeetCodeMetaDataSchema.self, from: data)
    }

    // MARK: - Scaffold Orchestration

    /// Returns `true` if only a selective refresh was performed (existing slug, no `--force`),
    /// or `false` if a full fresh scaffold was created.
    func createSetup(
        for slug: String,
        metadata: ProblemMetadata,
        schema: LeetCodeMetaDataSchema?,
        force: Bool
    ) throws -> Bool {
        let sourceDir = currentDirectory
            .appendingPathComponent("Sources")
            .appendingPathComponent("leetcodes")
            .appendingPathComponent(slug)
        let testDir = currentDirectory
            .appendingPathComponent("Tests")
            .appendingPathComponent("leetcodesTests")
            .appendingPathComponent(slug)

        let sourceExists = fileManager.fileExists(atPath: sourceDir.path)

        // Selective refresh: slug already exists and --force not passed
        if sourceExists && !force {
            print("⚠️ Challenge directory already exists: \(sourceDir.path)")
            let readmeContent = generateReadme(metadata: metadata, slug: slug)
            try readmeContent.write(
                to: sourceDir.appendingPathComponent("README.md"),
                atomically: true, encoding: .utf8
            )
            print("📝 Overwrote README.md with updated LeetCode metadata (difficulty: \(metadata.difficulty))")
            print("🔒 Skipped code scaffolding to preserve existing solutions.")
            return true
        }

        // Force: remove existing directories first
        if sourceExists && force {
            print("💥 Force flag passed. Deleting existing directories...")
            try fileManager.removeItem(at: sourceDir)
            if fileManager.fileExists(atPath: testDir.path) {
                try fileManager.removeItem(at: testDir)
            }
        }

        try fileManager.createDirectory(at: sourceDir, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: testDir, withIntermediateDirectories: true)

        print("📁 Created directories:")
        print("  - \(sourceDir.path)")
        print("  - \(testDir.path)")

        let name = metadata.camelCaseName

        try generateReadme(metadata: metadata, slug: slug)
            .write(to: sourceDir.appendingPathComponent("README.md"), atomically: true, encoding: .utf8)

        try generateNamespace(metadata: metadata, slug: slug, schema: schema)
            .write(to: sourceDir.appendingPathComponent("\(name).swift"), atomically: true, encoding: .utf8)

        try generateSolutionV1(metadata: metadata)
            .write(to: sourceDir.appendingPathComponent("\(name)_v1.swift"), atomically: true, encoding: .utf8)

        try generateBenchmark(metadata: metadata, slug: slug)
            .write(to: sourceDir.appendingPathComponent("\(name)+Benchmark.swift"), atomically: true, encoding: .utf8)

        try generateTests(metadata: metadata, schema: schema)
            .write(to: testDir.appendingPathComponent("\(name)Tests.swift"), atomically: true, encoding: .utf8)

        try generateTestCasesJson(metadata: metadata, schema: schema)
            .write(to: testDir.appendingPathComponent("testcases.json"), atomically: true, encoding: .utf8)

        print("✍️ Created template files:")
        print("  - README.md")
        print("  - \(name).swift")
        print("  - \(name)_v1.swift")
        print("  - \(name)+Benchmark.swift")
        print("  - \(name)Tests.swift")
        print("  - testcases.json")

        return false
    }

    // MARK: - README.md

    private func generateReadme(metadata: ProblemMetadata, slug: String) -> String {
        var metaSection = ""
        if let json = metadata.metaDataJson {
            metaSection = """


            ---

            ## LeetCode Metadata (JSON)
            ```json
            \(json)
            ```
            """
        }

        return """
        # \(metadata.title)

        \(metadata.problemStatement)

        ## Difficulty: \(metadata.difficulty)

        ---

        ## Complexity & Explanations

        | Version | Time Complexity | Space Complexity | Approach Description |
        | :--- | :--- | :--- | :--- |
        | **V1 (Initial)** | O(?) | O(?) | Describe initial approach here. |

        ---

        ## Link
        https://leetcode.com/problems/\(slug)/\(metaSection)
        """
    }

    // MARK: - [CamelCase].swift (Namespace + Arguments + run)

    private func generateNamespace(
        metadata: ProblemMetadata,
        slug: String,
        schema: LeetCodeMetaDataSchema?
    ) -> String {
        let argumentsStruct: String
        let runMethodBody: String

        if let schema = schema {
            let fields = schema.params.map {
                "        public let \($0.name): \(LeetCodeTypeMapper.mapType($0.type))"
            }.joined(separator: "\n")

            let initParams = schema.params.map {
                "\($0.name): \(LeetCodeTypeMapper.mapType($0.type))"
            }.joined(separator: ", ")

            let initBody = schema.params.map {
                "            self.\($0.name) = \($0.name)"
            }.joined(separator: "\n")

            let callArgs = schema.params.map { "args.\($0.name)" }.joined(separator: ", ")

            argumentsStruct = """


                public struct Arguments: Codable, Sendable {
            \(fields)

                    public init(\(initParams)) {
            \(initBody)
                    }
                }
            """

            runMethodBody = """
                    let args: Arguments
                    do {
                        args = try decoder.decode(Arguments.self, from: Data(inputJson.utf8))
                    } catch {
                        throw LeetCodeError.invalidInput("Expected JSON object matching Arguments structure: \\(error.localizedDescription)")
                    }

                    switch solutionId.lowercased() {
                    case "v1", "solutionv1":
                        let result = SolutionV1().\(schema.name)(\(callArgs))
                        return String(describing: result)
                    default:
                        throw LeetCodeError.unknownSolution(solutionId)
                    }
            """
        } else {
            argumentsStruct = ""
            runMethodBody = """
                    // TODO: Define your input model, decode it, and run the solution.
                    // For example:
                    // let input = try decoder.decode(Int.self, from: Data(inputJson.utf8))
                    // let result = SolutionV1().solve(input)
                    // return String(describing: result)

                    switch solutionId.lowercased() {
                    case "v1", "solutionv1":
                        return "TODO: Implement run logic in \(metadata.camelCaseName).swift"
                    default:
                        throw LeetCodeError.unknownSolution(solutionId)
                    }
            """
        }

        return """
        import Foundation

        /// Namespace for \(metadata.title) challenge
        public enum \(metadata.camelCaseName): LeetCodeChallenge {
            public static var slug: String { "\(slug)" }
            public static var name: String { "\(metadata.title)" }\(argumentsStruct)

            public static func run(solutionId: String, inputJson: String) throws -> String {
                let decoder = JSONDecoder()
                _ = decoder // Silences unused warning during initial setup

        \(runMethodBody)
            }
        }
        """
    }

    // MARK: - [CamelCase]_v1.swift

    private func generateSolutionV1(metadata: ProblemMetadata) -> String {
        let solutionCode: String
        if let swiftCode = metadata.swiftCode {
            solutionCode = indent(SwiftBlueprintProcessor.process(swiftCode), by: 8)
        } else {
            solutionCode = """
                    public func solve() {
                        // Write solution here
                    }
            """
        }

        return """
        import Foundation

        extension \(metadata.camelCaseName) {
            /// **Approach 1: Initial Solution**
            ///
            /// A detailed description of the first approach and how it works.
            ///
            /// - Complexity:
            ///   - **Time:** O(?)
            ///   - **Space:** O(?)
            ///
            /// - Note: Add any important notes, constraints, or boundary conditions handled here.
            public struct SolutionV1 {
                public init() {}

        \(solutionCode)
            }
        }
        """
    }

    // MARK: - [CamelCase]+Benchmark.swift

    private func generateBenchmark(metadata: ProblemMetadata, slug: String) -> String {
        let difficulty = metadata.difficulty.lowercased()
        let iterations = difficulty.contains("easy") ? 1000
                       : difficulty.contains("medium") ? 200
                       : 50

        return """
        import Foundation

        extension \(metadata.camelCaseName) {
            public static func runBenchmarks() {
                // Configure dynamic benchmark iterations based on difficulty
                BenchmarkConfig.iterationsOverride = \(iterations)

                // Define benchmark inputs of different sizes
                let inputs: [(size: Int, data: String)] = [
                    (size: 10,   data: "input_10"),
                    (size: 100,  data: "input_100"),
                    (size: 1000, data: "input_1000")
                ]

                BenchmarkRunner.run(
                    challenge: "\(slug)",
                    solution: "SolutionV1",
                    inputs: inputs
                ) { input in
                    // Call your solution here:
                    // _ = SolutionV1().solve(input)
                }
            }
        }
        """
    }

    // MARK: - [CamelCase]Tests.swift

    private func generateTests(metadata: ProblemMetadata, schema: LeetCodeMetaDataSchema?) -> String {
        guard let schema = schema else {
            // Schema unavailable (offline/local mode): generate a placeholder test file
            // that compiles cleanly without referencing the non-existent Arguments struct.
            return """
            import Testing
            import Foundation
            @testable import leetcodes

            @Suite("\(metadata.title) Tests")
            struct \(metadata.camelCaseName)Tests {

                // TODO: Add your test cases here once the challenge arguments are defined.
                // Example:
                // @Test("Solution V1")
                // func testSolutionV1() {
                //     let solver = \(metadata.camelCaseName).SolutionV1()
                //     #expect(solver.solve() == expectedResult)
                // }
            }
            """
        }

        let returnSwiftType = LeetCodeTypeMapper.mapType(schema.return.type)
        let paramsCall = schema.params.map { "caseData.input.\($0.name)" }.joined(separator: ", ")

        return """
        import Testing
        import Foundation
        @testable import leetcodes

        @Suite("\(metadata.title) Tests")
        struct \(metadata.camelCaseName)Tests {

            struct TestCase: Decodable, Sendable {
                let input: \(metadata.camelCaseName).Arguments
                let expected: \(returnSwiftType)
            }

            static let testCases = TestDataLoader.loadJSON(
                [TestCase].self,
                fileName: "testcases.json",
                callingFile: #filePath
            ) ?? []

            @Test("Solution V1 - Parameterized from JSON", arguments: testCases)
            func testSolutionV1(caseData: TestCase) {
                let solver = \(metadata.camelCaseName).SolutionV1()
                let result = solver.\(schema.name)(\(paramsCall))
                #expect(result == caseData.expected)
            }
        }
        """
    }

    // MARK: - testcases.json

    private func generateTestCasesJson(
        metadata: ProblemMetadata,
        schema: LeetCodeMetaDataSchema?
    ) -> String {
        guard let schema = schema,
              let exampleTestcases = metadata.exampleTestcases else { return "[]" }

        let lines = exampleTestcases.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let paramCount = schema.params.count
        guard paramCount > 0, !lines.isEmpty else { return "[]" }

        let numTestcases = lines.count / paramCount
        guard numTestcases > 0 else { return "[]" }

        let scrapedOutputs = ExpectedOutputScraper.extractExpectedOutputs(from: metadata.problemStatement)

        var testcasesArray: [String] = []

        for i in 0..<numTestcases {
            var inputs: [String] = []
            for j in 0..<paramCount {
                let lineIdx = i * paramCount + j
                if lineIdx < lines.count {
                    inputs.append("      \"\(schema.params[j].name)\": \(lines[lineIdx])")
                }
            }

            let scraped = i < scrapedOutputs.count ? scrapedOutputs[i] : ""
            let expectedVal = scraped.isEmpty
                ? LeetCodeTypeMapper.defaultPlaceholder(for: schema.return.type)
                : ExpectedOutputScraper.formatExpectedOutput(scraped: scraped, type: schema.return.type)

            testcasesArray.append("""
              {
                "input": {
            \(inputs.joined(separator: ",\n"))
                },
                "expected": \(expectedVal)
              }
            """)
        }

        return "[\n" + testcasesArray.joined(separator: ",\n") + "\n]"
    }

    // MARK: - Indentation Helper

    private func indent(_ text: String, by spaces: Int) -> String {
        let padding = String(repeating: " ", count: spaces)
        return text.components(separatedBy: .newlines).map { line in
            line.isEmpty ? "" : padding + line
        }.joined(separator: "\n")
    }
}
