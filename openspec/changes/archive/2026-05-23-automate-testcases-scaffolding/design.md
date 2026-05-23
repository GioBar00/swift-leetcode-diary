## Context

Scaffolding a new LeetCode challenge using `create.swift` generates source stubs and test stubs. Currently, this process is plagued by two main issues:
1. **Compilation Errors on Scaffold**: The fetched Swift code blocks are empty methods that expect non-Void return values. This prevents the project from compiling after scaffolding until the user manually inserts mock return statements.
2. **Disconnected Test Cases**: The fetched example test cases are saved as raw line-separated text files (`input_testcases.txt`) but are completely unintegrated with the Swift unit tests. The generated test file contains hardcoded dummy structures (`static let testCases = [("example_input", true)]`) that the user must manually rewrite to fit the problem types.

---

## Goals / Non-Goals

**Goals:**
- **Instant Compilation**: Scaffolded files must compile cleanly with `swift test` out-of-the-box by injecting `fatalError("TODO")` inside empty method stubs.
- **Dynamic Type Safety**: Parse the structured GraphQL `metaData` JSON schema from LeetCode to dynamically write custom type-safe `Arguments` structs and unpacking wrappers.
- **Automated Parameterized Tests**: Generate a complete `testcases.json` and update `[CamelCase]Tests.swift` to dynamically load and decode it, running parameterized tests instantly.
- **Scraped Expected Outputs**: Use a regex-based parser to scrape the expected outputs directly from Markdown examples, falling back to return-type-specific defaults.

**Non-Goals:**
- Dynamically build complex custom class parsers for graphs/linked lists (e.g. `ListNode`, `TreeNode`) beyond standard array/value types.
- Provide a persistent local offline database of descriptions or network cache.

---

## Decisions

### Decision 1: Using `testcases.json` instead of Line-by-Line Swift Parsing
- **Alternative considered**: Parsing raw line-separated inputs inside unit tests at runtime.
- **Trade-off / Rationale**: Statically parsing line-separated inputs is brittle and requires custom parsing code in every test suite. By writing a structured `testcases.json` during scaffolding, we separate the test data from logic. Swift Testing can decode the JSON directly into the type-safe `Arguments` struct, simplifying test suites and eliminating the need for `input_large.txt`.

### Decision 2: Injecting `fatalError("TODO")` to solve empty return signatures
- **Alternative considered**: Injecting type-based dummy values like `return 0` or `return false`.
- **Trade-off / Rationale**: Injected dummy values might mask logical gaps and cause false-positive test results if a naive implementation returns the same value. `fatalError()` satisfies the Swift compiler's type checker (returning `Never`), compiles instantly, and clearly fails at runtime if a solution method is called before implementation.

### Decision 3: Regex-Based Output Scraper with Type-Safe Fallbacks
- **Alternative considered**: Requiring manual input of all expected outputs.
- **Trade-off / Rationale**: Manually typing simple expected outputs is tedious. We implement a best-effort Markdown scraper matching `**Output:** <value>` or `Output: <value>`. For safety, if a value is missing or has a type mismatch, we fall back to sensible defaults matching the metadata return type (e.g., `0` for `Int`, `false` for `Bool`, `""` for `String`, `[]` for arrays).

---

## Risks / Trade-offs

- **[Risk] Scraped output is formatted differently or incorrect** ───► **[Mitigation]** We use a type-safe fallback mechanism and keep the data in `testcases.json` so the developer can review and correct expected outputs without modifying Swift files.
- **[Risk] Complex structural inputs (e.g. linked lists represented as array `[1,2,3]`)** ───► **[Mitigation]** The generator maps the parameters as arrays in the `Arguments` struct, letting the developer decode them natively in their Solution code as-is, keeping the deserialization layers highly clean.
