## Why

Scaffolding new LeetCode challenges manually requires copy-pasting descriptions, manually translating titles to CamelCase, hardcoding boilerplate difficulty configurations, and manually copying starter Swift function definitions. This creates friction when starting new challenges and leads to inconsistent code blueprints or incomplete `README.md` files. Automating this directly using LeetCode's public GraphQL API will streamline the developer workflow, increase metadata accuracy, inject the official Swift code signatures, capture default sample test cases, and elevate the developer experience of this tool.

## What Changes

- **Automatic Online Fetching**: Scaffolding a challenge slug will automatically fetch its metadata (title, difficulty, description, Swift starter code, and default test cases) from LeetCode's public GraphQL API.
- **Official Swift Code Signature Scaffolding**: Fetches the official starter code snippet matching `langSlug == "swift"` and injects it as the starter blueprint for the solution struct in `{CamelCaseName}_v1.swift`.
- **Default Sample Test Cases Integration**: Fetches the default test case inputs (`exampleTestcases` and `metaData`) and writes them directly into a new `input_testcases.txt` resource file in the test directory, making them immediately available for test loader logic.
- **Fail-by-Default on Network Outages**: If the network fetch fails, the script will throw a distinct error and prompt the user to use the `--local` flag to proceed.
- **Local Fallback Flag (`--local`)**: A new `--local` flag will bypass online fetching entirely, falling back to the offline rule-based metadata generator and standard stubs.
- **Safe Name Conflict Resolution**:
  - If a slug directory already exists, a **Selective Refresh** process will run: it overwrites the `README.md` with the updated description but protects existing `.swift` source and test files to prevent losing existing solution implementations. It will also skip modifying the registry if the slug is already registered.
  - A `--force` flag will override this safeguard and trigger a full, fresh overwrite of all files.
- **Fidelity Markdown Translation**: A built-in regex-based HTML cleaner will convert standard LeetCode HTML structures into clean markdown in the generated `README.md` and docstrings.
- **Difficulty-Customized Boilerplates**: Templates will customize complexity expectations and benchmark iteration loops dynamically based on the challenge difficulty (Easy vs Medium/Hard).

## Capabilities

### New Capabilities

*(None)*

### Modified Capabilities

- `automation`: Standardizes automation workflows to support online metadata fetching, Swift starter blueprint parsing, sample testcase generation, selective directory refreshes on conflicts, dynamic difficulty-based template configuration, and local fallback toggles.

## Impact

- **Affected script**: `create.swift` at the workspace root.
- **System implications**: Internet connection requirement for `create.swift` under default usage.
- **New scaffold file**: `input_testcases.txt` added to the test suite folder for every fetched challenge.
- **Dependencies**: Requires standard platform library components (conditional imports of `FoundationNetworking` on Linux).
