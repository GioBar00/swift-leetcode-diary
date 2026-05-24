# Challenge Automation Specification

## Purpose
The Challenge Automation module (`leetswift create` command) streamlines the process of starting new LeetCode challenges. It validates inputs, generates all required directories, writes standard templated source and test files, and automatically registers the new problem into the core system registry.
## Requirements
### Requirement: Alphanumeric Snail-Case Slug Validation
The automation script MUST validate that the input slug conforms to a snail-case standard containing only lowercase alphanumeric characters and hyphens, after trimming surrounding whitespaces/newlines and lowercasing.

#### Scenario: Validating valid and invalid slugs
- **WHEN** the script is executed with a valid slug (e.g. `longest-common-prefix`, or `Longest-Common-Prefix` which is automatically normalized and lowercased)
- **THEN** it MUST accept the argument and proceed with scaffolding
- **AND** if the normalized slug contains spaces, underscores, or special characters, it MUST throw an error and terminate execution

### Requirement: Scaffolded Directory Layout and Templates
The script MUST generate two dedicated directories (for source files and unit tests) and populate them with standard template files.

#### Scenario: Generating challenge files
- **WHEN** a valid slug is scaffolded (e.g., `palindrome-number` matching `PalindromeNumber` in CamelCase)
- **THEN** it MUST create the folders `Sources/leetcodes/palindrome-number/` and `Tests/leetcodesTests/palindrome-number/`
- **AND** it MUST create the following template files:
  - `README.md` containing problem link, difficulty, complexity tables, and LeetCode metadata JSON
  - `PalindromeNumber.swift` declaring the LeetCodeChallenge protocol namespace with a type-safe `Arguments` struct and argument-unpacking `run()` method
  - `PalindromeNumber_v1.swift` containing SolutionV1 stub populated with fetched Swift blueprints, popover docstrings, and a compilable body containing `fatalError("TODO")`
  - `PalindromeNumber+Benchmark.swift` defining performance benchmark runs configured dynamically by difficulty
  - `PalindromeNumberTests.swift` defining parameterized tests using modern Apple `Testing` framework that dynamically loads `testcases.json`
  - `testcases.json` containing the pre-filled inputs for all example test cases and scraped or default expected outputs

---

### Requirement: Automatic Registry Ingestion
The script MUST parse the central `ChallengeRegistry.swift` file and automatically register the new challenge definition.

#### Scenario: Injecting the challenge entry into registry
- **WHEN** scaffolding a new challenge slug
- **THEN** the script MUST open `Sources/leetcodes/Shared/ChallengeRegistry.swift`
- **AND** if the challenge is not already present, it MUST insert the challenge entry `"slug": CamelCaseName.self,` automatically into the dictionary without corrupting existing mappings

### Requirement: Online Challenge Metadata Fetching
The automation script MUST attempt to fetch problem details (title, difficulty level, HTML description, Swift starter code, and default test cases) from the LeetCode GraphQL API using standard HTTP networking, unless the offline mode flag is active.

#### Scenario: Successfully fetching problem details online
- **WHEN** the script is executed with a valid slug and no offline flags
- **THEN** it MUST perform a POST request to `https://leetcode.com/graphql/` with a GraphQL payload query targeting the slug
- **AND** it MUST successfully parse the JSON response to extract the problem's official title, difficulty, content HTML, codeSnippets, sampleTestCase, exampleTestcases, and metaData

#### Scenario: Failing network fetch without local flag
- **WHEN** the script is executed without offline flags but the network connection fails or LeetCode returns a rate-limit/server error
- **THEN** it MUST terminate execution with a distinct error message advising the user to run the command with `--local` to proceed offline

#### Scenario: Bypassing network fetch with local option
- **WHEN** the script is executed with the `--local` flag
- **THEN** it SHALL bypass all network calls entirely
- **AND** it MUST use the rule-based local generator to construct mock metadata (setting title from slug, difficulty to "Easy", and description to a placeholder)

### Requirement: Swift Starter Code Blueprint Parsing
The automation script MUST filter the fetched code snippets for the language `Swift` (langSlug `swift`), clean the wrapping class structures, and inject the isolated function definitions as starter code.

#### Scenario: Injecting Swift function definitions into solution templates
- **WHEN** the fetched code snippets contain an entry with `langSlug == "swift"`
- **THEN** the script MUST extract the starter code text block
- **AND** it MUST strip the outer `class Solution {` and trailing `}` characters
- **AND** it MUST write the inner function declaration directly into the `SolutionV1` template inside the `{CamelCaseName}_v1.swift` file
- **AND** it MUST inject `fatalError("TODO")` inside the empty method block to ensure instant out-of-the-box compilation

---

### Requirement: Default Sample Test Cases Extraction
The automation script MUST extract default sample test cases and function signatures from the LeetCode API and serialize them into dedicated test resource files.

#### Scenario: Scaffolding default sample testcase file
- **WHEN** the fetched data contains non-empty `exampleTestcases` and `metaData` JSON strings
- **THEN** it MUST create the file `testcases.json` inside the challenge's test folder
- **AND** it MUST parse the parameter types and names from the `metaData` JSON schema
- **AND** it MUST parse the `exampleTestcases` multi-line string, grouping input lines by parameter count
- **AND** it MUST attempt to extract expected outputs from the converted problem statement markdown examples (e.g. matching `**Output:** <value>`)
- **AND** if an output cannot be extracted, it MUST fall back to a return-type default value (e.g. `0`, `false`, `""`)
- **AND** it MUST write the structured array of test cases containing both `"input"` parameters and `"expected"` output to `testcases.json`

### Requirement: HTML to Markdown Tag Parsing
The automation script MUST convert HTML structural elements returned by LeetCode into clean, standard Markdown formatting when writing the problem statement to `README.md` and docstrings.

#### Scenario: Converting HTML tags to markdown
- **WHEN** the fetched problem statement HTML is parsed
- **THEN** it MUST convert paragraph tags (`<p>`, `</p>`) into standard newlines
- **AND** it MUST convert inline code tags (`<code>`, `</code>`) into standard backticks
- **AND** it MUST convert bold tags (`<strong>`, `<b>`) into double asterisks (`**`)
- **AND** it MUST convert list items (`<li>`, `</li>`) into bulleted lines (`- `)
- **AND** it MUST convert preformatted text blocks (`<pre>`, `</pre>`) into triple-backtick markdown blocks

### Requirement: Scaffolding Safe Name Conflict Resolution
The automation script MUST protect existing solution code files on disk if the challenge's directory slug already exists, unless explicitly overridden by a force flag.

#### Scenario: Selective Refreshing metadata on conflict
- **WHEN** the target challenge directory already exists on disk and the `--force` flag is NOT passed
- **THEN** the script MUST overwrite the `README.md` file with the newly fetched/generated problem description
- **AND** it MUST skip writing or modifying all `.swift` source, benchmark, and test files to preserve existing solutions
- **AND** it MUST skip registry injection to prevent duplicate entries

#### Scenario: Forcing complete overwrite on conflict
- **WHEN** the target challenge directory already exists on disk and the `--force` flag is passed
- **THEN** the script MUST delete the existing folders
- **AND** it MUST perform a full, fresh scaffolding of all template files and registration

