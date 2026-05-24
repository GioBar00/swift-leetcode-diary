import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - Problem Metadata DTO

struct ProblemMetadata: Sendable {
    let title: String
    let camelCaseName: String
    let difficulty: String
    let problemStatement: String
    let swiftCode: String?
    let exampleTestcases: String?
    let metaDataJson: String?
}

// MARK: - Metadata Provider Protocol

protocol LeetCodeMetadataProvider: Sendable {
    func fetchMetadata(for slug: String) async throws -> ProblemMetadata
}

// MARK: - Local (Offline) Provider

struct LocalMetadataProvider: LeetCodeMetadataProvider {
    func fetchMetadata(for slug: String) async throws -> ProblemMetadata {
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

// MARK: - Online (GraphQL) Provider

struct OnlineMetadataProvider: LeetCodeMetadataProvider {
    func fetchMetadata(for slug: String) async throws -> ProblemMetadata {
        let url = URL(string: "https://leetcode.com/graphql/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 10
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            forHTTPHeaderField: "User-Agent"
        )
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
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, _) = try await URLSession.shared.data(for: request)

        let response = try JSONDecoder().decode(LeetCodeGraphQLResponse.self, from: data)
        guard let question = response.data.question else {
            throw LeetCodeFetchError.problemNotFound(slug)
        }

        let title = question.title
            ?? slug.components(separatedBy: "-").map { $0.capitalized }.joined(separator: " ")
        let camelCaseName = slug.components(separatedBy: "-").map { $0.capitalized }.joined()
        let swiftSnippet = question.codeSnippets?.first(where: { $0.langSlug == "swift" })?.code

        return ProblemMetadata(
            title: title,
            camelCaseName: camelCaseName,
            difficulty: question.difficulty ?? "Easy (Change if needed)",
            problemStatement: HTMLToMarkdownConverter.convert(
                question.content ?? "Paste the problem statement here from LeetCode."
            ),
            swiftCode: swiftSnippet,
            exampleTestcases: question.exampleTestcases,
            metaDataJson: question.metaData
        )
    }
}

// MARK: - Fetch Error

enum LeetCodeFetchError: LocalizedError {
    case problemNotFound(String)

    var errorDescription: String? {
        switch self {
        case .problemNotFound(let slug):
            return "LeetCode problem not found or returned null for '\(slug)'"
        }
    }
}

// MARK: - LeetCode GraphQL Response Models (private to this file)

private struct LeetCodeGraphQLResponse: Decodable {
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

struct LeetCodeMetaDataSchema: Decodable, Sendable {
    let name: String
    let params: [Param]
    let `return`: ReturnType

    struct Param: Decodable, Sendable {
        let name: String
        let type: String
    }

    struct ReturnType: Decodable, Sendable {
        let type: String
    }
}

// MARK: - LeetCode → Swift Type Mapper

enum LeetCodeTypeMapper {
    static func mapType(_ type: String) -> String {
        switch type {
        case "integer":     return "Int"
        case "integer[]":   return "[Int]"
        case "integer[][]": return "[[Int]]"
        case "string":      return "String"
        case "string[]":    return "[String]"
        case "double":      return "Double"
        case "double[]":    return "[Double]"
        case "boolean":     return "Bool"
        case "boolean[]":   return "[Bool]"
        case "character":   return "Character"
        case "character[]": return "[Character]"
        case "ListNode":    return "ListNode?"
        case "TreeNode":    return "TreeNode?"
        default:            return "String"
        }
    }

    static func defaultPlaceholder(for type: String) -> String {
        switch mapType(type) {
        case "Int":                             return "0"
        case "[Int]", "[[Int]]", "[String]",
             "[Double]", "[Bool]", "[Character]": return "[]"
        case "String":                          return "\"\""
        case "Double":                          return "0.0"
        case "Bool":                            return "false"
        case "Character":                       return "\"?\""
        case "ListNode?", "TreeNode?":          return "nil"
        default:                                return "\"\""
        }
    }
}

// MARK: - HTML → Markdown Converter

enum HTMLToMarkdownConverter {
    // Ordered table of tag → replacement pairs, applied in a single declarative pass
    private static let replacements: [(String, String)] = [
        ("<strong class=\"example\">", "### "),
        ("<strong>", "**"),  ("</strong>", "**"),
        ("<b>",      "**"),  ("</b>",      "**"),
        ("<em>",     "*"),   ("</em>",     "*"),
        ("<i>",      "*"),   ("</i>",      "*"),
        ("<code>",   "`"),   ("</code>",   "`"),
        ("<pre>",    "\n```\n"), ("</pre>", "\n```\n"),
        ("<ul>",     "\n"),  ("</ul>",     "\n"),
        ("<li>",     "- "),  ("</li>",     "\n"),
        ("<p>",      ""),    ("</p>",      "\n\n"),
        ("<br />",   "\n"),  ("<br/>",     "\n"),  ("<br>", "\n"),
        ("&amp;",    "&"),   ("&lt;",      "<"),   ("&gt;",  ">"),
        ("&quot;",   "\""),  ("&apos;",    "'"),   ("&nbsp;", " "),
        ("<sup>",    "^"),   ("</sup>",    ""),
    ]

    static func convert(_ html: String) -> String {
        var text = html

        for (tag, replacement) in replacements {
            text = text.replacingOccurrences(of: tag, with: replacement)
        }

        // Strip any remaining HTML tags
        if let regex = try? NSRegularExpression(pattern: "<[^>]+>", options: .caseInsensitive) {
            let range = NSRange(location: 0, length: text.utf16.count)
            text = regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "")
        }

        // Collapse consecutive blank lines
        while text.contains("\n\n\n") {
            text = text.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Expected Output Scraper

enum ExpectedOutputScraper {
    static func extractExpectedOutputs(from markdown: String) -> [String] {
        let pattern = "(?:\\*\\*Output:\\*\\*|Output:)\\s*`?([^`\\n\\r]+)`?"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return []
        }
        let range = NSRange(location: 0, length: markdown.utf16.count)
        return regex.matches(in: markdown, range: range).compactMap { match in
            guard match.numberOfRanges > 1,
                  let swiftRange = Range(match.range(at: 1), in: markdown) else { return nil }
            return markdown[swiftRange].trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    static func formatExpectedOutput(scraped: String, type: String) -> String {
        let cleaned = scraped.trimmingCharacters(in: .whitespacesAndNewlines)
        switch LeetCodeTypeMapper.mapType(type) {
        case "String":
            return cleaned.hasPrefix("\"") && cleaned.hasSuffix("\"") ? cleaned : "\"\(cleaned)\""
        case "Character":
            if cleaned.hasPrefix("\"") && cleaned.hasSuffix("\"") { return cleaned }
            if cleaned.hasPrefix("'") && cleaned.hasSuffix("'") {
                return "\"\(cleaned.dropFirst().dropLast())\""
            }
            return "\"\(cleaned)\""
        case "Bool":
            return cleaned.lowercased()
        default:
            return cleaned
        }
    }
}

// MARK: - Swift Blueprint Processor

enum SwiftBlueprintProcessor {
    /// Strips the `class Solution { }` wrapper from LeetCode's Swift snippet,
    /// dedents the body, and injects `fatalError("TODO")` into empty methods.
    static func process(_ code: String) -> String {
        var cleanCode = code.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let classRange = cleanCode.range(of: "class Solution\\s*\\{", options: .regularExpression) else {
            return cleanCode
        }

        cleanCode.removeSubrange(cleanCode.startIndex..<classRange.upperBound)

        if let lastBrace = cleanCode.lastIndex(of: "}") {
            cleanCode.remove(at: lastBrace)
        }

        // Inject fatalError into empty method bodies { }
        if let regex = try? NSRegularExpression(pattern: "\\{\\s*\\}", options: []) {
            let range = NSRange(location: 0, length: cleanCode.utf16.count)
            cleanCode = regex.stringByReplacingMatches(
                in: cleanCode, range: range,
                withTemplate: "{\n        fatalError(\"TODO\")\n    }"
            )
        }

        // Dedent one level (4 spaces or 1 tab)
        let dedented = cleanCode.components(separatedBy: .newlines).map { line -> String in
            if line.hasPrefix("    ") { return String(line.dropFirst(4)) }
            if line.hasPrefix("\t")  { return String(line.dropFirst(1)) }
            return line
        }

        return dedented.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
