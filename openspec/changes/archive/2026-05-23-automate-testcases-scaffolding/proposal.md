## Why

Scaffolding a new LeetCode challenge using the `create.swift` script currently produces empty Swift stubs with non-Void return signatures that fail to compile immediately out-of-the-box. Furthermore, sample test cases downloaded into `input_testcases.txt` are raw, line-separated text files that are completely unintegrated with our unit tests, requiring manual and error-prone copy-pasting of input types and expected values.

---

## What Changes

- **Zero-Error Compilation**: Empty scaffolded function stubs are injected with `fatalError("TODO")` so they compile immediately without manual return statements.
- **Dynamic Type Mapping**: The scraper parses LeetCode's structured GraphQL `metaData` schema to automatically generate a tailored `Arguments` struct and argument-unpacking `run()` method inside the challenge namespace.
- **Unification under `testcases.json`**: Removes `input_large.txt` and instead generates a unified `testcases.json` for all test cases. The generator parses LeetCode's downloaded `exampleTestcases` (grouping inputs by parameter count), matches them with best-effort scraped expected outputs from markdown description examples (falling back to return-type defaults), and writes them to the JSON file.
- **Dynamic Parameterized Tests**: Updates `TestDataLoader` with a generic JSON parser and modifies the scaffolded test template to automatically load and run the test cases from `testcases.json` dynamically using Swift Testing.

---

## Capabilities

### New Capabilities
*(None)*

### Modified Capabilities
- `automation`:
  - Update `Scaffolded Directory Layout and Templates` to replace `input_large.txt` and `input_testcases.txt` with `testcases.json`.
  - Update `Swift Starter Code Blueprint Parsing` to inject `fatalError("TODO")` into empty function blocks for instant compilation.
  - Update `Default Sample Test Cases Extraction` to parse the metadata schema and example test cases into a structured `testcases.json` file.

---

## Impact

- **Affected Files**:
  - `create.swift`: Core updates to scaffolding templates, parser, HTML tag parsing, and file writes.
  - `Tests/leetcodesTests/Shared/TestDataLoader.swift`: Adding a generic `loadJSON` loader.
  - Swift Templates: Updates to the generated namespace, `SolutionV1` stubs, and unit tests templates.
