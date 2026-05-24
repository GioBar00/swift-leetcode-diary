# 📖 Swift LeetCode Diary

> A beautifully structured, IDE-agnostic local Swift environment for writing, testing, and benchmarking LeetCode solutions. Perfect to use as a personal diary/journal to record and track your coding milestones.

[![Swift CI](https://github.com/GioBar00/swift-leetcode-diary/actions/workflows/test.yml/badge.svg)](https://github.com/GioBar00/swift-leetcode-diary/actions/workflows/test.yml)
[![Language](https://img.shields.io/badge/language-Swift%206.0+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-blue.svg)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

Why write your LeetCode solutions in a clunky web browser when you can code locally? With **Swift LeetCode Diary**, you get Xcode/VS Code autocompletion, type safety, parameterized unit testing, high-fidelity memory/execution benchmarks, and automated template generation.

---

## ✨ Features

- 🛠️ **IDE Agnostic**: Pure Swift Package Manager (SPM). Open seamlessly in **Xcode** (drag-and-drop the directory), **VS Code** (with Swift extension), **Cursor**, **CLion**, or pure **Terminal**.
- 🚀 **Integrated `leetswift` CLI**: A unified, high-performance command-line interface. Run, test, benchmark, and create challenges from a single tool.
- 📂 **Smart Path Resolver**: Pass either a raw slug (e.g. `two-sum`) or a directory path (e.g. `Sources/leetcodes/two-sum`) to CLI commands. It automatically resolves path inputs!
- ⚙️ **Automatic Registration**: Creating a new LeetCode problem automatically generates standard source files, test stubs, benchmarks, and registers the problem in a central registry automatically.
- ⚡ **High-Fidelity Benchmarks**: Measure absolute memory footprint (`task_vm_info`) and execution speeds (via `ContinuousClock`), complete with warm-ups and live horizontal ASCII complexity charts.
- 🧪 **Subprocess Test Runner**: Run tests directly from the CLI. Spawn `swift test --filter` and stream compilation and test logs in real-time.
- 🧹 **100% Warning-Free**: Package.swift dynamically scans and excludes markdown, JSON metrics, and test files so your console remains warning-free.

---

## 🛠️ Getting Started

### 1. Create Your Diary
To create your own personal copy of this diary, click the green **"Use this template"** button at the top right of this GitHub page and clone the repository locally.

### 2. Shortcut Setup & Global Installation
We provide two convenient ways to run the CLI tool shortcut, avoiding long `swift run` commands:
- **Local Wrapper Script**: Simply run commands using `./leetswift` in the project root folder.
- **Global Installation**: Compile in release mode and install the binary globally to your system path:
  ```bash
  make install
  ```
  Now you can run the `leetswift` command from **any** folder on your machine!

### 3. Workspace Setup
Open the folder in your favorite editor:
- **Xcode**: Double-click `Package.swift` or run `open Package.swift` in your terminal.
- **VS Code / Cursor**: Open the root folder (ensure you have the **Swift** extension installed).
- **Terminal**: Run `swift build` to compile the package.

---

## 💻 CLI Commands

*All examples below can be run globally as `leetswift` or locally as `./leetswift`.*

### 1. List Registered Challenges
See all your logged LeetCode challenges:
```bash
leetswift list
```
*Output:*
```text
💡 Available LeetCode Challenges
==================================================================
  01. Two Sum [two-sum]
==================================================================
Run one with: leetswift run <slug-or-path>
Test one with: leetswift test <slug-or-path>
Benchmark one with: leetswift benchmark <slug-or-path>
Create a new one with: leetswift create <slug>
```

### 2. Run a Solution
Execute a specific solution version with type-safe arguments passed as inline JSON or linked files:
```bash
# Inline JSON using slug
leetswift run two-sum --solution v1 --input '{"nums": [2, 7, 11, 15], "target": 9}'

# Using smart folder path input instead of slug
leetswift run Sources/leetcodes/two-sum --solution v1 --input '{"nums": [2, 7, 11, 15], "target": 9}'
```
*Output:*
```text
🚀 Running Two Sum...
------------------------------------------------------------------
  Challenge: two-sum
  Solution:  v1
  Input:     {"nums": [2, 7, 11, 15], "target": 9}
------------------------------------------------------------------
✨ Execution Successful!
------------------------------------------------------------------
  Result: [0, 1]
  Time:   70.38 µs
==================================================================
```

### 3. Run Unit Tests (Subprocess Streamed)
Test a specific LeetCode challenge and stream compiler progress and unit test logs to your console:
```bash
leetswift test two-sum

# Or by passing a directory path
leetswift test Sources/leetcodes/two-sum
```
*Output:*
```text
🧪 Running Tests for: Two Sum
------------------------------------------------------------------
  Filter: TwoSumTests
------------------------------------------------------------------

✔ Test "Solution V1 (Hash Map) - Parameterized" with 4 test cases passed.
✔ Test "Solution V2 (Brute Force) - Parameterized" with 4 test cases passed.
✔ Suite "Two Sum Tests" passed.
✔ Test run with 2 tests in 1 suite passed.

------------------------------------------------------------------
✔ Tests Completed Successfully!
==================================================================
```

### 4. Run Performance Benchmarks
Compare execution speeds and memory footprints of different approaches (e.g. O(N) vs O(N²)) across multiple input sizes. You can override iterations and warm-up counts dynamically:
```bash
# Default benchmarks
leetswift benchmark two-sum

# Custom overrides (5 iterations, 1 warmup loop) for fast checks
leetswift benchmark Sources/leetcodes/two-sum --iterations 5 --warmup 1
```
*Output:*
```text
⚡️ Initializing Benchmarks for: Two Sum
------------------------------------------------------------------
📊 Benchmarking: two-sum (SolutionV1 (Hash Map))
==================================================================
  ✅ Size: 10    ->   2.26 µs | Memory Footprint: 8.50 MB
  ✅ Size: 100   ->  19.96 µs | Memory Footprint: 8.52 MB
  ✅ Size: 1,000 -> 185.19 µs | Memory Footprint: 8.58 MB

📈 Complexity Analysis Chart (Execution Time vs Size)
------------------------------------------------------------------
  Size 10       [░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░]    2.26 µs
  Size 100      [███░░░░░░░░░░░░░░░░░░░░░░░░░░░]   19.96 µs
  Size 1000     [██████████████████████████████]  185.19 µs
💾 Saved metrics to: Sources/leetcodes/two-sum/benchmark_results.json
==================================================================

📊 Benchmarking Complete!
```

---

## 📝 Logging a New LeetCode Challenge

To log a new challenge, use the `leetswift create` command:
```bash
leetswift create <leetcode-slug>
```
*Example:*
```bash
leetswift create reverse-integer
```

This will automatically:
1. Fetch the problem title, description, difficulty, and Swift starter code from LeetCode (or scaffold offline with `--local`).
2. Create `Sources/leetcodes/reverse-integer/` and populate it with stubs for your solutions, a README, and a custom benchmark.
3. Create `Tests/leetcodesTests/reverse-integer/` populated with stubs for unit tests (`Swift Testing` suite) and a pre-filled `testcases.json`.
4. Automatically append the problem metadata and register `ReverseInteger` in `Sources/leetcodes/Shared/ChallengeRegistry.swift`.
5. Work instantly with zero manual wiring!

**Options:**
- `--local` / `--offline`: Scaffold without an internet connection.
- `--force`: Delete and fully recreate an existing challenge directory (preserves nothing — use carefully).
- Running without `--force` on an existing slug performs a **selective refresh**: only `README.md` is overwritten, preserving your solutions.

---

## 📁 Repository Structure

```text
swift-leetcode-diary/
├── Package.swift                  # SPM build definition (with dynamic file exclusions)
├── leetswift                      # Root executable shell script wrapper
├── Makefile                       # Makefile for global leetswift CLI installation
├── CHANGELOG.md                   # Release history
├── CONTRIBUTING.md                # Contribution guide & commit convention
├── CLI/                           # CLI Executable Source (Main entry point)
│   ├── main.swift                 # CLI Parser Root (AsyncParsableCommand)
│   ├── CreateCommand.swift        # Command to scaffold new challenges
│   ├── LeetCodeFetcher.swift      # GraphQL fetcher, HTML→MD, type mapping
│   ├── TemplateGenerator.swift    # Template engine + file I/O
│   ├── ChallengeRegistrar.swift   # Auto-registers challenges in the registry
│   ├── ListCommand.swift          # Command to list logged challenges
│   ├── RunCommand.swift           # Command to execute solutions with input
│   ├── TestCommand.swift          # Subprocess test runner with log streaming
│   ├── BenchmarkCommand.swift     # Command to run performance suites
│   └── CLIHelpers.swift           # Shared CLI helpers (path resolver, formatters)
├── Sources/                       # Library Sources containing LeetCode solutions
│   └── leetcodes/
│       ├── Shared/                # Shared utilities
│       │   ├── LeetCodeChallenge.swift  # Core challenge protocol & error types
│       │   ├── ChallengeRegistry.swift  # Challenge mappings registry
│       │   ├── BenchmarkRunner.swift    # High-fidelity benchmark engine
│       │   ├── ListNode.swift           # Linked list node (LeetCode standard)
│       │   └── TreeNode.swift           # Binary tree node (LeetCode standard)
│       ├── two-sum/               # Golden reference example
│       │   ├── TwoSum.swift       # Challenge namespace definitions & JSON parser
│       │   ├── TwoSum_v1.swift    # Solution V1: O(N) Hash Map
│       │   ├── TwoSum_v2.swift    # Solution V2: O(N²) Brute Force
│       │   ├── TwoSum+Benchmark.swift # Performance benchmark parameters
│       │   └── README.md          # Problem statement and complexity table
│       └── ...
└── Tests/                         # Unit tests matching problem directory structures
    └── leetcodesTests/
        ├── Shared/
        │   └── TestDataLoader.swift   # Utility to load raw test input files
        └── two-sum/
            ├── TwoSumTests.swift      # Parameterized unit tests (Swift Testing)
            └── input_large.txt        # Large local test inputs
```

---

## 🤝 Contributing & Forking

This repository is designed to be **forked as your own personal diary**. For structural improvements to the template itself (new shared utilities, CLI features, bug fixes), PRs are welcome!

1. Fork the template and start your own diary.
2. For structural improvements: open a PR against this repo following the [Conventional Commits](https://www.conventionalcommits.org/) format.
3. See [CONTRIBUTING.md](CONTRIBUTING.md) for full details.

### Keeping your fork up to date
When the template gets new features or fixes, pull them into your fork via the **GitHub Sync Fork** button or the upstream remote workflow — see [CONTRIBUTING.md § Updating Your Fork](CONTRIBUTING.md#-updating-your-fork-from-the-template) for step-by-step instructions.

Happy Coding! 🚀

---

*This project is not affiliated with or endorsed by LeetCode. LeetCode® is a registered trademark of LeetCode LLC.*
