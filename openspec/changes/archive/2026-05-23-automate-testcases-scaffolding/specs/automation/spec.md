## MODIFIED Requirements

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
