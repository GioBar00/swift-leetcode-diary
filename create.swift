#!/usr/bin/env swift
import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - Protocols & DTOs for Future-Proof Scraping
protocol LeetCodeMetadataProvider {
    func fetchMetadata(for slug: String) throws -> ProblemMetadata
}

struct ProblemMetadata {
    let title: String
    let camelCaseName: String
    let difficulty: String
    let problemStatement: String
    let swiftCode: String?
    let exampleTestcases: String?
    let metaDataJson: String?
}

// MARK: - LeetCode GraphQL Decodable Structures
struct LeetCodeResponse: Decodable {
    let data: DataContainer
    
    struct DataContainer: Decodable {
        let question: QuestionDetail?
    }
    
    struct QuestionDetail: Decodable {
        let title: String?
        let content: String?
        let difficulty: String?
        let sampleTestCase: String?
        let exampleTestcases: String?
        let metaData: String?
        let codeSnippets: [CodeSnippet]?
    }
    
    struct CodeSnippet: Decodable {
        let lang: String?
        let langSlug: String?
        let code: String?
    }
}

// MARK: - LeetCode Metadata Schema
struct LeetCodeMetaDataSchema: Decodable {
    let name: String
    let params: [Param]
    let `return`: ReturnType
    
    struct Param: Decodable {
        let name: String
        let type: String
    }
    
    struct ReturnType: Decodable {
        let type: String
    }
}

// MARK: - LeetCode to Swift Type Mapping Utilities
struct LeetCodeTypeMapper {
    static func mapType(_ type: String) -> String {
        switch type {
        case "integer": return "Int"
        case "integer[]": return "[Int]"
        case "integer[][]": return "[[Int]]"
        case "string": return "String"
        case "string[]": return "[String]"
        case "double": return "Double"
        case "double[]": return "[Double]"
        case "boolean": return "Bool"
        case "boolean[]": return "[Bool]"
        case "character": return "Character"
        case "character[]": return "[Character]"
        case "ListNode": return "ListNode?"
        case "TreeNode": return "TreeNode?"
        default: return "String"
        }
    }
    
    static func defaultPlaceholder(for type: String) -> String {
        let swiftType = mapType(type)
        switch swiftType {
        case "Int": return "0"
        case "[Int]": return "[]"
        case "[[Int]]": return "[]"
        case "String": return "\"\""
        case "[String]": return "[]"
        case "Double": return "0.0"
        case "[Double]": return "[]"
        case "Bool": return "false"
        case "[Bool]": return "[]"
        case "Character": return "\"?\""
        case "[Character]": return "[]"
        case "ListNode?": return "nil"
        case "TreeNode?": return "nil"
        default: return "\"\""
        }
    }
}

// MARK: - HTML-to-Markdown Tag Parser
struct HTMLToMarkdownConverter {
    static func convert(_ html: String) -> String {
        var text = html
        
        // 1. Examples and standard formatting
        text = text.replacingOccurrences(of: "<strong class=\"example\">", with: "### ")
        text = text.replacingOccurrences(of: "<strong>", with: "**")
        text = text.replacingOccurrences(of: "</strong>", with: "**")
        text = text.replacingOccurrences(of: "<b>", with: "**")
        text = text.replacingOccurrences(of: "</b>", with: "**")
        text = text.replacingOccurrences(of: "<em>", with: "*")
        text = text.replacingOccurrences(of: "</em>", with: "*")
        text = text.replacingOccurrences(of: "<i>", with: "*")
        text = text.replacingOccurrences(of: "</i>", with: "*")
        
        // 2. Inline code & code blocks
        text = text.replacingOccurrences(of: "<code>", with: "`")
        text = text.replacingOccurrences(of: "</code>", with: "`")
        text = text.replacingOccurrences(of: "<pre>", with: "\n```\n")
        text = text.replacingOccurrences(of: "</pre>", with: "\n```\n")
        
        // 3. Lists
        text = text.replacingOccurrences(of: "<ul>", with: "\n")
        text = text.replacingOccurrences(of: "</ul>", with: "\n")
        text = text.replacingOccurrences(of: "<li>", with: "- ")
        text = text.replacingOccurrences(of: "</li>", with: "\n")
        
        // 4. Paragraphs and breaks
        text = text.replacingOccurrences(of: "<p>", with: "")
        text = text.replacingOccurrences(of: "</p>", with: "\n\n")
        text = text.replacingOccurrences(of: "<br />", with: "\n")
        text = text.replacingOccurrences(of: "<br/>", with: "\n")
        text = text.replacingOccurrences(of: "<br>", with: "\n")
        
        // 5. HTML Character Entities
        text = text.replacingOccurrences(of: "&amp;", with: "&")
        text = text.replacingOccurrences(of: "&lt;", with: "<")
        text = text.replacingOccurrences(of: "&gt;", with: ">")
        text = text.replacingOccurrences(of: "&quot;", with: "\"")
        text = text.replacingOccurrences(of: "&apos;", with: "'")
        text = text.replacingOccurrences(of: "&nbsp;", with: " ")
        
        // 6. Superscripts
        text = text.replacingOccurrences(of: "<sup>", with: "^")
        text = text.replacingOccurrences(of: "</sup>", with: "")
        
        // 7. Strip any remaining HTML tags using regular expression (safety fallthrough)
        if let regex = try? NSRegularExpression(pattern: "<[^>]+>", options: .caseInsensitive) {
            let range = NSRange(location: 0, length: text.utf16.count)
            text = regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "")
        }
        
        // 8. Clean up consecutive newlines
        while text.contains("\n\n\n") {
            text = text.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }
        
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Expected Output Markdown Scraper
struct ExpectedOutputScraper {
    static func extractExpectedOutputs(from markdown: String) -> [String] {
        var outputs: [String] = []
        let pattern = "(?:\\*\\*Output:\\*\\*|Output:)\\s*`?([^`\\n\\r]+)`?"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return []
        }
        
        let range = NSRange(location: 0, length: markdown.utf16.count)
        let matches = regex.matches(in: markdown, options: [], range: range)
        
        for match in matches {
            if match.numberOfRanges > 1 {
                let outputRange = match.range(at: 1)
                if let swiftRange = Range(outputRange, in: markdown) {
                    let val = markdown[swiftRange].trimmingCharacters(in: .whitespacesAndNewlines)
                    outputs.append(val)
                }
            }
        }
        
        return outputs
    }
    
    static func formatExpectedOutput(scraped: String, type: String) -> String {
        let swiftType = LeetCodeTypeMapper.mapType(type)
        let cleaned = scraped.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch swiftType {
        case "String":
            if cleaned.hasPrefix("\"") && cleaned.hasSuffix("\"") {
                return cleaned
            }
            return "\"\(cleaned)\""
        case "Character":
            if cleaned.hasPrefix("\"") && cleaned.hasSuffix("\"") {
                return cleaned
            }
            if cleaned.hasPrefix("'") && cleaned.hasSuffix("'") {
                let inner = cleaned.dropFirst().dropLast()
                return "\"\(inner)\""
            }
            return "\"\(cleaned)\""
        case "Bool":
            return cleaned.lowercased()
        default:
            return cleaned
        }
    }
}

// MARK: - Swift Starter Code Processor
struct SwiftBlueprintProcessor {
    static func process(_ code: String) -> String {
        var cleanCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Find if it has the standard "class Solution" signature
        if let classRange = cleanCode.range(of: "class Solution\\s*\\{", options: .regularExpression) {
            cleanCode.removeSubrange(cleanCode.startIndex..<classRange.upperBound)
            
            // Remove the final closing brace
            if let lastBraceIndex = cleanCode.lastIndex(of: "}") {
                cleanCode.remove(at: lastBraceIndex)
            }
            
            // Inject fatalError("TODO") inside empty methods to allow out-of-the-box compilation
            if let regex = try? NSRegularExpression(pattern: "\\{\\s*\\}", options: []) {
                let range = NSRange(location: 0, length: cleanCode.utf16.count)
                cleanCode = regex.stringByReplacingMatches(in: cleanCode, options: [], range: range, withTemplate: "{\n        fatalError(\"TODO\")\n    }")
            }
            
            // Deduct indentation (4 spaces or 1 tab) from each line
            let lines = cleanCode.components(separatedBy: .newlines)
            let dedentedLines = lines.map { line -> String in
                if line.hasPrefix("    ") {
                    return String(line.dropFirst(4))
                } else if line.hasPrefix("\t") {
                    return String(line.dropFirst(1))
                }
                return line
            }
            
            return dedentedLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return code.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - String Indentation Helper
func indent(_ text: String, by spaces: Int) -> String {
    let padding = String(repeating: " ", count: spaces)
    return text.components(separatedBy: .newlines).map { line -> String in
        if line.isEmpty { return "" }
        return padding + line
    }.joined(separator: "\n")
}

// MARK: - Current Manual / Rule-Based Metadata Generator
class LocalMetadataProvider: LeetCodeMetadataProvider {
    func fetchMetadata(for slug: String) throws -> ProblemMetadata {
        // Simple conversion: "two-sum" -> "Two Sum" and "TwoSum"
        let components = slug.components(separatedBy: "-")
        let title = components.map { $0.capitalized }.joined(separator: " ")
        let camelCaseName = components.map { $0.capitalized }.joined()
        
        return ProblemMetadata(
            title: title,
            camelCaseName: camelCaseName,
            difficulty: "Easy (Change if needed)",
            problemStatement: "Paste the problem statement here from LeetCode.",
            swiftCode: nil,
            exampleTestcases: nil,
            metaDataJson: nil
        )
    }
}

// MARK: - Unsafe Thread-Safe Box for Concurrency Safety in Swift 6
final class UnsafeBox<T>: @unchecked Sendable {
    var value: T?
    init(_ value: T? = nil) {
        self.value = value
    }
}

// MARK: - GraphQL Online Metadata Scraper
class OnlineMetadataProvider: LeetCodeMetadataProvider {
    func fetchMetadata(for slug: String) throws -> ProblemMetadata {
        let url = URL(string: "https://leetcode.com/graphql/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        request.setValue("https://leetcode.com/problems/\(slug)/", forHTTPHeaderField: "Referer")
        
        let query = """
        query questionData($titleSlug: String!) {
          question(titleSlug: $titleSlug) {
            title
            content
            difficulty
            sampleTestCase
            exampleTestcases
            metaData
            codeSnippets {
              lang
              langSlug
              code
            }
          }
        }
        """
        
        let payload: [String: Any] = [
            "query": query,
            "variables": ["titleSlug": slug]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        
        let fetchErrorBox = UnsafeBox<Error>()
        let resultMetadataBox = UnsafeBox<ProblemMetadata>()
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            defer { semaphore.signal() }
            
            if let error = error {
                fetchErrorBox.value = error
                return
            }
            
            guard let data = data else {
                fetchErrorBox.value = NSError(domain: "OnlineMetadataProvider", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data returned from LeetCode API"])
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let responseObj = try decoder.decode(LeetCodeResponse.self, from: data)
                
                guard let question = responseObj.data.question else {
                    fetchErrorBox.value = NSError(domain: "OnlineMetadataProvider", code: -2, userInfo: [NSLocalizedDescriptionKey: "LeetCode problem not found or returns null for '\(slug)'"])
                    return
                }
                
                let title = question.title ?? slug.components(separatedBy: "-").map { $0.capitalized }.joined(separator: " ")
                let components = slug.components(separatedBy: "-")
                let camelCaseName = components.map { $0.capitalized }.joined()
                
                var swiftCodeSnippet: String? = nil
                if let snippets = question.codeSnippets {
                    swiftCodeSnippet = snippets.first(where: { $0.langSlug == "swift" })?.code
                }
                
                resultMetadataBox.value = ProblemMetadata(
                    title: title,
                    camelCaseName: camelCaseName,
                    difficulty: question.difficulty ?? "Easy (Change if needed)",
                    problemStatement: HTMLToMarkdownConverter.convert(question.content ?? "Paste the problem statement here from LeetCode."),
                    swiftCode: swiftCodeSnippet,
                    exampleTestcases: question.exampleTestcases,
                    metaDataJson: question.metaData
                )
            } catch {
                fetchErrorBox.value = error
            }
        }
        
        task.resume()
        _ = semaphore.wait(timeout: .now() + 10) // 10 seconds timeout
        
        if let error = fetchErrorBox.value {
            throw error
        }
        
        guard let metadata = resultMetadataBox.value else {
            throw NSError(domain: "OnlineMetadataProvider", code: -3, userInfo: [NSLocalizedDescriptionKey: "Request timed out or metadata could not be populated. Ensure you have an active internet connection."])
        }
        
        return metadata
    }
}

// MARK: - Template Generator
class TemplateGenerator {
    private let fileManager = FileManager.default
    private let currentDirectory: URL
    
    init() {
        self.currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
    }
    
    private func generateReadme(metadata: ProblemMetadata, slug: String) -> String {
        var metaDataRefSection = ""
        if let metaDataJson = metadata.metaDataJson {
            metaDataRefSection = """
            
            ---
            
            ## LeetCode Metadata (JSON)
            ```json
            \(metaDataJson)
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
        https://leetcode.com/problems/\(slug)/\(metaDataRefSection)
        """
    }
    
    private func parseSchema(from metadata: ProblemMetadata) -> LeetCodeMetaDataSchema? {
        guard let jsonString = metadata.metaDataJson,
              let data = jsonString.data(using: .utf8) else {
            return nil
        }
        return try? JSONDecoder().decode(LeetCodeMetaDataSchema.self, from: data)
    }
    
    private func generateTestCasesJson(metadata: ProblemMetadata) -> String {
        guard let schema = parseSchema(from: metadata),
              let exampleTestcases = metadata.exampleTestcases else {
            return "[]"
        }
        
        let lines = exampleTestcases.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            
        let paramCount = schema.params.count
        if paramCount == 0 || lines.isEmpty {
            return "[]"
        }
        
        let numTestcases = lines.count / paramCount
        if numTestcases == 0 {
            return "[]"
        }
        
        // Extract scraped outputs from markdown
        let scrapedOutputs = ExpectedOutputScraper.extractExpectedOutputs(from: metadata.problemStatement)
        
        var testcasesArray: [String] = []
        
        for i in 0..<numTestcases {
            var inputs: [String] = []
            for j in 0..<paramCount {
                let lineIdx = i * paramCount + j
                if lineIdx < lines.count {
                    let param = schema.params[j]
                    let val = lines[lineIdx]
                    inputs.append("      \"\(param.name)\": \(val)")
                }
            }
            
            let scrapedOutput = i < scrapedOutputs.count ? scrapedOutputs[i] : ""
            let expectedVal: String
            if !scrapedOutput.isEmpty {
                expectedVal = ExpectedOutputScraper.formatExpectedOutput(scraped: scrapedOutput, type: schema.return.type)
            } else {
                expectedVal = LeetCodeTypeMapper.defaultPlaceholder(for: schema.return.type)
            }
            
            let testcaseJson = """
              {
                "input": {
            \(inputs.joined(separator: ",\n"))
                },
                "expected": \(expectedVal)
              }
            """
            testcasesArray.append(testcaseJson)
        }
        
        return "[\n" + testcasesArray.joined(separator: ",\n") + "\n]"
    }
    
    private func generateNamespace(metadata: ProblemMetadata, slug: String) -> String {
        let schema = parseSchema(from: metadata)
        
        var argumentsStruct = ""
        var runMethodBody = ""
        
        if let schema = schema {
            // Generate Decodable Arguments struct
            let fields = schema.params.map { param -> String in
                let swiftType = LeetCodeTypeMapper.mapType(param.type)
                return "        public let \(param.name): \(swiftType)"
            }.joined(separator: "\n")
            
            let initParams = schema.params.map { param -> String in
                let swiftType = LeetCodeTypeMapper.mapType(param.type)
                return "\(param.name): \(swiftType)"
            }.joined(separator: ", ")
            
            let initBody = schema.params.map { param -> String in
                return "            self.\(param.name) = \(param.name)"
            }.joined(separator: "\n")
            
            argumentsStruct = """
            
                public struct Arguments: Codable, Sendable {
            \(fields)
                    
                    public init(\(initParams)) {
            \(initBody)
                    }
                }
            """
            
            // Generate run method logic
            let solutionMethodName = schema.name
            let callArgs = schema.params.map { param -> String in
                return "args.\(param.name)"
            }.joined(separator: ", ")
            
            runMethodBody = """
                    let args: Arguments
                    do {
                        args = try decoder.decode(Arguments.self, from: Data(inputJson.utf8))
                    } catch {
                        throw LeetCodeError.invalidInput("Expected JSON object matching Arguments structure: \\(error.localizedDescription)")
                    }
                    
                    switch solutionId.lowercased() {
                    case "v1", "solutionv1":
                        let result = SolutionV1().\(solutionMethodName)(\(callArgs))
                        return String(describing: result)
                    default:
                        throw LeetCodeError.unknownSolution(solutionId)
                    }
            """
        } else {
            // Fallback to original generic placeholder
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
    
    private func generateSolutionV1(metadata: ProblemMetadata) -> String {
        let solutionCode: String
        if let swiftCode = metadata.swiftCode {
            let processed = SwiftBlueprintProcessor.process(swiftCode)
            solutionCode = indent(processed, by: 8)
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
    
    private func generateBenchmark(metadata: ProblemMetadata, slug: String) -> String {
        let iterations: Int
        let difficulty = metadata.difficulty.lowercased()
        if difficulty.contains("easy") {
            iterations = 1000
        } else if difficulty.contains("medium") {
            iterations = 200
        } else {
            iterations = 50
        }
        
        return """
        import Foundation
        
        extension \(metadata.camelCaseName) {
            public static func runBenchmarks() {
                // Configure dynamic benchmark iterations based on difficulty
                BenchmarkConfig.iterationsOverride = \(iterations)
                
                // Define benchmark inputs of different sizes
                let inputs: [(size: Int, data: String)] = [
                    (size: 10, data: "input_10"),
                    (size: 100, data: "input_100"),
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
    
    private func generateTests(metadata: ProblemMetadata) -> String {
        let schema = parseSchema(from: metadata)
        let returnSwiftType = schema != nil ? LeetCodeTypeMapper.mapType(schema!.return.type) : "Bool"
        
        var solverCall = ""
        if let schema = schema {
            let paramsCall = schema.params.map { param -> String in
                return "caseData.input.\(param.name)"
            }.joined(separator: ", ")
            solverCall = """
                    let solver = \(metadata.camelCaseName).SolutionV1()
                    let result = solver.\(schema.name)(\(paramsCall))
                    #expect(result == caseData.expected)
            """
        } else {
            solverCall = """
                    // let solver = \(metadata.camelCaseName).SolutionV1()
                    // #expect(solver.solve(caseData.input) == caseData.expected)
            """
        }
        
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
        \(solverCall)
            }
        }
        """
    }
    
    // Returns true if selective refresh was performed, false if full fresh scaffolding
    func createSetup(for slug: String, metadata: ProblemMetadata, force: Bool) throws -> Bool {
        // Define directory paths
        let sourceDir = currentDirectory
            .appendingPathComponent("Sources")
            .appendingPathComponent("leetcodes")
            .appendingPathComponent(slug)
            
        let testDir = currentDirectory
            .appendingPathComponent("Tests")
            .appendingPathComponent("leetcodesTests")
            .appendingPathComponent(slug)
            
        let sourceExists = fileManager.fileExists(atPath: sourceDir.path)
        
        if sourceExists && !force {
            print("⚠️ Challenge directory already exists: \(sourceDir.path)")
            
            // Selective Refresh: Only rewrite README.md
            let readmeContent = generateReadme(metadata: metadata, slug: slug)
            try readmeContent.write(to: sourceDir.appendingPathComponent("README.md"), atomically: true, encoding: .utf8)
            print("📝 Overwrote README.md with updated LeetCode metadata (difficulty: \(metadata.difficulty))")
            print("🔒 Skipped code scaffolding to preserve existing solutions.")
            return true
        }
        
        if sourceExists && force {
            print("💥 Force flag passed. Deleting existing directories...")
            if fileManager.fileExists(atPath: sourceDir.path) {
                try fileManager.removeItem(at: sourceDir)
            }
            if fileManager.fileExists(atPath: testDir.path) {
                try fileManager.removeItem(at: testDir)
            }
        }
        
        // 1. Create directories on disk
        try fileManager.createDirectory(at: sourceDir, withIntermediateDirectories: true, attributes: nil)
        try fileManager.createDirectory(at: testDir, withIntermediateDirectories: true, attributes: nil)
        
        print("📁 Created directories:")
        print("  - \(sourceDir.path)")
        print("  - \(testDir.path)")
        
        // 2. Generate and write README.md
        let readmeContent = generateReadme(metadata: metadata, slug: slug)
        try readmeContent.write(to: sourceDir.appendingPathComponent("README.md"), atomically: true, encoding: .utf8)
        
        // 3. Generate and write Namespace.swift
        let namespaceContent = generateNamespace(metadata: metadata, slug: slug)
        try namespaceContent.write(to: sourceDir.appendingPathComponent("\(metadata.camelCaseName).swift"), atomically: true, encoding: .utf8)
        
        // 4. Generate and write [CamelCase]_v1.swift
        let solutionContent = generateSolutionV1(metadata: metadata)
        try solutionContent.write(to: sourceDir.appendingPathComponent("\(metadata.camelCaseName)_v1.swift"), atomically: true, encoding: .utf8)
        
        // 4b. Generate and write [CamelCase]+Benchmark.swift
        let benchmarkContent = generateBenchmark(metadata: metadata, slug: slug)
        try benchmarkContent.write(to: sourceDir.appendingPathComponent("\(metadata.camelCaseName)+Benchmark.swift"), atomically: true, encoding: .utf8)
        
        // 5. Generate and write [CamelCase]Tests.swift
        let testsContent = generateTests(metadata: metadata)
        try testsContent.write(to: testDir.appendingPathComponent("\(metadata.camelCaseName)Tests.swift"), atomically: true, encoding: .utf8)
        
        // 6. Generate and write testcases.json
        let testcasesJsonContent = generateTestCasesJson(metadata: metadata)
        try testcasesJsonContent.write(to: testDir.appendingPathComponent("testcases.json"), atomically: true, encoding: .utf8)
        print("  - testcases.json")
        
        print("✍️ Created template files:")
        print("  - README.md")
        print("  - \(metadata.camelCaseName).swift")
        print("  - \(metadata.camelCaseName)_v1.swift")
        print("  - \(metadata.camelCaseName)+Benchmark.swift")
        print("  - \(metadata.camelCaseName)Tests.swift")
        print("  - testcases.json")
        
        return false
    }
    
    func registerChallenge(slug: String, camelCaseName: String) throws {
        let registryURL = currentDirectory
            .appendingPathComponent("Sources")
            .appendingPathComponent("leetcodes")
            .appendingPathComponent("Shared")
            .appendingPathComponent("ChallengeRegistry.swift")
        
        guard fileManager.fileExists(atPath: registryURL.path) else {
            print("⚠️ Warning: ChallengeRegistry.swift not found at \(registryURL.path). Skipped auto-registration.")
            return
        }
        
        var content = try String(contentsOf: registryURL, encoding: .utf8)
        
        // Check if already registered
        if content.contains("\"\(slug)\":") {
            print("ℹ️ Challenge '\(slug)' is already registered in ChallengeRegistry.swift.")
            return
        }
        
        // Find standard dictionary start
        let pattern = "challenges: \\[String: any LeetCodeChallenge\\.Type\\] = \\["
        if let range = content.range(of: pattern, options: .regularExpression) {
            let insertPos = range.upperBound
            let registryEntry = "\n        \"\(slug)\": \(camelCaseName).self,"
            content.insert(contentsOf: registryEntry, at: insertPos)
            
            try content.write(to: registryURL, atomically: true, encoding: .utf8)
            print("✏️ Automatically registered '\(slug)' in ChallengeRegistry.swift")
        } else {
            print("⚠️ Warning: Could not locate standard challenges dictionary in ChallengeRegistry.swift. Please register manually.")
        }
    }
}

// MARK: - Main Runner
func main() {
    var slug = ""
    var isLocalMode = false
    var isForceMode = false
    
    let args = CommandLine.arguments
    guard args.count > 1 else {
        print("❌ Error: Missing argument.")
        print("Usage: swift create.swift <leetcode-snail-case-name> [--local | --offline] [--force]")
        print("Example: swift create.swift two-sum")
        exit(1)
    }
    
    // Parse arguments
    for arg in args.dropFirst() {
        if arg == "--local" || arg == "--offline" {
            isLocalMode = true
        } else if arg == "--force" {
            isForceMode = true
        } else if arg.hasPrefix("-") {
            print("❌ Error: Unknown option '\(arg)'.")
            exit(1)
        } else {
            if slug.isEmpty {
                slug = arg.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            } else {
                print("❌ Error: Multiple arguments provided.")
                exit(1)
            }
        }
    }
    
    // Simple validation (must be alphanumeric and hyphens only)
    let regex: NSRegularExpression
    do {
        regex = try NSRegularExpression(pattern: "^[a-z0-9-]+$")
    } catch {
        print("❌ Internal Error: Failed to compile slug validation regex: \(error.localizedDescription)")
        exit(1)
    }
    let range = NSRange(location: 0, length: slug.utf16.count)
    if regex.firstMatch(in: slug, options: [], range: range) == nil {
        print("❌ Error: Invalid slug '\(slug)'.")
        print("Slugs should be lowercased and separated by hyphens (e.g., 'longest-common-prefix').")
        exit(1)
    }
    
    var provider: LeetCodeMetadataProvider
    if isLocalMode {
        provider = LocalMetadataProvider()
    } else {
        provider = OnlineMetadataProvider()
    }
    
    do {
        print("🚀 Setting up LeetCode: \(slug)...")
        let metadata: ProblemMetadata
        do {
            metadata = try provider.fetchMetadata(for: slug)
        } catch {
            if !isLocalMode {
                print("❌ Error: Failed to fetch online metadata from LeetCode.")
                print("   Reason: \(error.localizedDescription)")
                print("💡 Suggestion: If you are offline or getting rate-limited, run with '--local' or '--offline' to scaffold manually.")
                print("   Example: swift create.swift \(slug) --local")
            } else {
                print("❌ Critical Error: \(error.localizedDescription)")
            }
            exit(1)
        }
        
        let generator = TemplateGenerator()
        let isSelectiveRefresh = try generator.createSetup(for: slug, metadata: metadata, force: isForceMode)
        
        if !isSelectiveRefresh {
            try generator.registerChallenge(slug: slug, camelCaseName: metadata.camelCaseName)
            print("✅ Setup complete! Reloading your Xcode project or running the CLI will automatically display the new challenge.")
        } else {
            print("✅ Selective refresh complete! Metadata updated successfully.")
        }
    } catch {
        print("❌ Critical Error: \(error.localizedDescription)")
        exit(1)
    }
}

main()
