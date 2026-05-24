## 1. Test Utilities Upgrades

- [x] 1.1 Implement generic loadJSON loader inside TestDataLoader.swift

## 2. Generator Modifications in create.swift

- [x] 2.1 Update SwiftBlueprintProcessor to inject fatalError("TODO") inside empty function stubs
- [x] 2.2 Define types and parsing structures for the LeetCode question metaData JSON
- [x] 2.3 Add LeetCode-to-Swift type mapping and default placeholder resolution utilities
- [x] 2.4 Implement a robust regular expression expected output parser for problem markdown examples
- [x] 2.5 Modify createSetup and TemplateGenerator to construct and write structured testcases.json
- [x] 2.6 Refactor generated namespace template to declare Arguments struct and run() parameters unpacking
- [x] 2.7 Update generated unit tests template to load testcases.json and execute parameterized test suites

## 3. Verification

- [x] 3.1 Scaffold a test challenge using swift create.swift and verify error-free compilation
- [x] 3.2 Verify generated testcases.json has all inputs and scraped expected values formatted correctly
- [x] 3.3 Run swift test for the scaffolded challenge to verify parameterized execution
