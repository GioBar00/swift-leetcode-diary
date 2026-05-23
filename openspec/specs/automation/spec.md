# Challenge Automation Specification

## Purpose
The Challenge Automation module (`create.swift` script) streamlines the process of starting new LeetCode challenges. It validates inputs, generates all required directories, writes standard templated source and test files, and automatically registers the new problem into the core system registry.

## Requirements

### Requirement: Alphanumeric Snail-Case Slug Validation
The automation script MUST strictly validate that the input slug conforms to a snail-case standard containing only lowercase alphanumeric characters and hyphens.

#### Scenario: Validating valid and invalid slugs
- **WHEN** the script is executed with a valid slug (e.g. `longest-common-prefix`)
- **THEN** it MUST accept the argument and proceed with scaffolding
- **AND** if the slug contains uppercase letters, spaces, or special characters, it MUST throw an error and terminate execution

### Requirement: Scaffolded Directory Layout and Templates
The script MUST generate two dedicated directories (for source files and unit tests) and populate them with standard template files.

#### Scenario: Generating challenge files
- **WHEN** a valid slug is scaffolded (e.g., `palindrome-number` matching `PalindromeNumber` in CamelCase)
- **THEN** it MUST create the folders `Sources/leetcodes/palindrome-number/` and `Tests/leetcodesTests/palindrome-number/`
- **AND** it MUST create the following template files:
  - `README.md` containing problem link, difficulty, and complexity tables
  - `PalindromeNumber.swift` declaring the LeetCodeChallenge protocol namespace
  - `PalindromeNumber_v1.swift` containing SolutionV1 stub and popover docstrings
  - `PalindromeNumber+Benchmark.swift` defining performance benchmark runs
  - `PalindromeNumberTests.swift` defining parameterized tests using modern Apple `Testing` framework
  - `input_large.txt` placeholder resource inside the test directory

### Requirement: Automatic Registry Ingestion
The script MUST parse the central `ChallengeRegistry.swift` file and automatically register the new challenge definition.

#### Scenario: Injecting the challenge entry into registry
- **WHEN** scaffolding a new challenge slug
- **THEN** the script MUST open `Sources/leetcodes/Shared/ChallengeRegistry.swift`
- **AND** it MUST search for the static challenges dictionary start pattern
- **AND** it MUST insert the challenge entry `"slug": CamelCaseName.self,` automatically into the dictionary without corrupting existing mappings
