## Context

The `create.swift` script currently scaffolds a new LeetCode problem locally using static string manipulations on the lowercase snail-case slug. It provides placeholder text for the problem statement and sets a default difficulty level of `"Easy (Change if needed)"`. Developers have to manually navigate to LeetCode, copy the problem description, convert it into markdown, populate the local README file, and manually copy the Swift function signatures, which is slow and prone to formatting and syntax inconsistencies.

By integrating a lightweight, zero-dependency GraphQL client and a robust HTML-to-markdown text processing engine, `create.swift` can fetch metadata directly from LeetCode. Additionally, we must build a safeguarded directory scaffolding pipeline that prevents overwriting user solutions when name conflicts occur on the local filesystem.

## Goals / Non-Goals

**Goals:**
- **Automated Metadata Fetching**: Connect to the public LeetCode GraphQL API to fetch the official title, difficulty level, and HTML problem description.
- **Swift Starter Blueprint Integration**: Retrieve the official starting Swift blueprint from `codeSnippets` and inject it directly into the generated code stubs inside `SolutionV1`.
- **Default Sample Test Cases**: Retrieve the raw default sample test cases (`exampleTestcases` and `metaData` JSON) and save them to a new resource file (`input_testcases.txt`) inside the test suite directories for direct test runner execution.
- **Fail-by-Default Execution**: Ensure network errors during the default fetch loop fail explicitly with suggestions to use the offline flag, avoiding silent, half-completed folder scaffolding.
- **Selective Scaffolding & Preservation**: Protect existing solution source and test files on name conflicts while refreshing metadata `README.md`.
- **Dynamic Difficulty Scaffolding**: Automatically configure benchmark iterations and README structures based on the problem's actual difficulty.
- **HTML-to-Markdown Translation**: Automatically sanitize and parse common HTML tags (`<p>`, `<code>`, `<pre>`, `<strong>`, lists, blockquotes) into clean markdown text using pure regular expressions.
- **Cross-Platform Compatibility**: Implement networking and file operations that compile and run warning-free on both macOS and Linux without external Swift dependencies.

**Non-Goals:**
- **Premium Problem Authentication**: No implementation of OAuth or cookie-based authentication for premium-only LeetCode problems; the tool is restricted to public problems.
- **LeetCode Code Sync / Submissions**: Running tests or submitting solutions back to LeetCode is out of scope.
- **Multiple Platform Scrapers**: Scraping from HackerRank, Codeforces, or other platforms is out of scope.

## Decisions

### 1. Zero-Dependency Swift GraphQL Client
- **Choice**: Use standard `URLSession` combined with a `DispatchSemaphore` to run synchronous networking inside the CLI script.
- **Rationale**: Since `create.swift` is executed as a standalone script, including heavy external SPM libraries (like Apollo iOS or SwiftGraphQL) would require complex project targets and significantly slow down compiler startup. A pure synchronous network block utilizing `DispatchSemaphore` keeps compilation fast and maintains cross-platform compatibility without external dependencies.
- **Query Structure**: The script will POST to `https://leetcode.com/graphql/` requesting the following fields:
  ```graphql
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
  ```

### 2. Swift Starter Blueprint Processing
- **Choice**: Filter `codeSnippets` for `langSlug == "swift"`. Strip the outer `class Solution {` wrapper and trailing `}` using standard string manipulation/trimming to isolate the inner function definitions. Inject these functions directly into `SolutionV1` in `{CamelCaseName}_v1.swift`.
- **Rationale**: This gives the developer the exact method signature expected by LeetCode (e.g. `func twoSum(_ nums: [Int], _ target: Int) -> [Int]`) without clashing with the namespace structure or requiring the redundant `class Solution` wrapper.
- **Fallback**: If no Swift snippet is found, default to a standard `func solve()` placeholder.

### 3. Sample Test Cases Resource File
- **Choice**: Create a new resource file named `input_testcases.txt` containing the raw multiline string of `exampleTestcases`. Store it inside `Tests/leetcodesTests/<slug>/`. Also insert the `metaData` JSON string into `README.md` for reference.
- **Rationale**: Keeps the test runner fully decoupled and lets developers read clean sample cases from disk.

### 4. Network Failure and Flag Rules
- **Choice**: Implement an explicit fail-by-default behavior when network fetch is aborted, and require `--local` or `--offline` to proceed offline.
- **Rationale**: If the tool silently fell back to local generation when offline, the user might end up with empty stubs without realizing their connection failed. Explicit errors keep the CLI predictable.

### 5. Safe Selective Refresh for Folder Conflicts
- **Choice**: Default to a safe **Selective Refresh** flow that refreshes the `README.md` but skips writing all code files and test files, accompanied by an explicit `--force` override option.
- **Rationale**: Developers frequently want to sync or update descriptions without wiping their hard-earned solution code. Total folder overwrite by default would be a catastrophic developer experience.

### 6. Zero-Dependency Regex HTML to Markdown Parsing
- **Choice**: Implement a linear regular expression processing pipeline using `NSRegularExpression` mapping HTML block tags and character entities to their Markdown equivalents.
- **Rationale**: Pure Foundation-based text parsing works seamlessly across macOS and Linux, requiring no external parsing libraries.

## Risks / Trade-offs

- **[Risk] LeetCode GraphQL Schema Changes / Rate Limiting** $\rightarrow$ *Mitigation*: Ensure the query remains basic, asking only for standard properties. If LeetCode blocks the request (e.g. via Cloudflare), the script fails gracefully with advice to run with `--local` so developers can easily bypass the block.
- **[Risk] Linux Network Support** $\rightarrow$ *Mitigation*: Conditionally import `FoundationNetworking` on non-macOS platforms to ensure compilability on Linux (Ubuntu).
