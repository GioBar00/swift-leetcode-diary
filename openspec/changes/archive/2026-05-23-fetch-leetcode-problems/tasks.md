## 1. Network Interface and CLI Options Parsing

- [x] 1.1 Support parsing options `--local`/`--offline` and `--force` from `CommandLine.arguments` in the script's `main()` runner.
- [x] 1.2 Add conditional import block for `FoundationNetworking` when compiling on Linux.
- [x] 1.3 Implement `OnlineMetadataProvider` conforming to `LeetCodeMetadataProvider` to fetch the problem description, difficulty, code snippets, default sample test cases, and metadata via the public LeetCode GraphQL API.
- [x] 1.4 Add validation to throw distinct errors and output offline instructions (suggesting `--local`) when online network fetches fail.

## 2. HTML to Markdown Parser

- [x] 2.1 Implement `HTMLToMarkdownConverter` with regex-based replacements to clean LeetCode's HTML tags (including paragraphs, inline code, bold text, list items, code blocks, and character entities) into standard markdown.
- [x] 2.2 Wire the converter output into the `README.md` scaffolding logic.

## 3. Swift Blueprint & Sample Test Cases Integration

- [x] 3.1 Write utility to search fetched `codeSnippets` for `langSlug == "swift"`, strip the outer `class Solution { ... }` boundaries, and isolate the inner function declarations.
- [x] 3.2 Inject the isolated Swift starter functions as the starter body inside the generated `{CamelCaseName}_v1.swift` Solution struct.
- [x] 3.3 Create and write raw fetched `exampleTestcases` into `input_testcases.txt` within the challenge test folder directory.
- [x] 3.4 Append the fetched `metaData` JSON string into `README.md` under a reference section.

## 4. Scaffolding Safeguards and Selective Refresh

- [x] 4.1 Modify `TemplateGenerator.createSetup` to check if the challenge directory already exists.
- [x] 4.2 Implement the "Selective Refresh" flow: if the directory exists and `--force` is NOT passed, overwrite only `README.md` and skip writing all `.swift` and `.txt`/`input_testcases.txt` files.
- [x] 4.3 Implement "Force Overwrite" flow: if the directory exists and `--force` IS passed, perform a complete re-scaffolding of all templates.
- [x] 4.4 Modify `TemplateGenerator.registerChallenge` to skip modifying the challenge registry file if the slug is already registered.

## 5. Difficulty-Customized Templates

- [x] 5.1 Update `TemplateGenerator` to dynamically configure benchmarking iteration count inside `[CamelCase]+Benchmark.swift` based on fetched difficulty (e.g., 1000 for Easy, 100 for Hard).
- [x] 5.2 Update docstring complexity stubs and table templates based on the fetched difficulty.

## 6. Script Verification & Testing

- [x] 6.1 Run the script online with a new slug (e.g., `contains-duplicate`) to verify complete, high-fidelity metadata generation, including Swift blueprint extraction and `input_testcases.txt` output.
- [x] 6.2 Test "Selective Refresh" by running `create.swift` again on `contains-duplicate` and verifying existing solution files are untouched.
- [x] 6.3 Test the `--force` flag to verify complete regeneration of all templates.
- [x] 6.4 Test offline handling by manually severing internet connection or simulating network failure to verify correct instruction messaging and command termination.
