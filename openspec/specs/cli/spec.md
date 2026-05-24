# CLI Tool Specification

## Purpose
The CLI Tool (`leetswift`) serves as the user-facing entry point. It parses input commands, resolves file paths or slugs dynamically, runs solutions with specific JSON arguments, triggers subprocess test runners, and invokes performance benchmarking parameters.

## Requirements

### Requirement: List Registered Challenges
The tool MUST list all challenges currently registered in the core system's challenge registry.

#### Scenario: Running the list command
- **WHEN** the user executes the `list` command (or runs the tool with no subcommands)
- **THEN** it MUST render a formatted header displaying all available LeetCode problems
- **AND** it MUST print instructions on how to run, test, benchmark, and create challenges

### Requirement: Execute Solution with Input Constraints
The `run` command MUST execute a specific challenge solution using input JSON provided inline or via a file, and enforce strict input validation.

#### Scenario: Running with valid inline JSON
- **WHEN** the user executes `run` with a valid slug, solution variant, and inline JSON input via `--input`
- **THEN** it MUST parse the JSON, execute the specified solution variant, and return the output string representation
- **AND** it MUST print a summary of the running challenge, solution variant, execution time, and outcome

#### Scenario: Input validation failures
- **WHEN** the user executes `run` supplying both `--input` and `--file`, or supplying neither
- **THEN** it MUST throw a validation error instructing the user to supply exactly one source of input

### Requirement: Subprocess Streaming Test Runner
The `test` command MUST execute target tests in a subprocess and stream compilation and test logs in real-time.

#### Scenario: Running tests for a challenge
- **WHEN** the user triggers the `test` command for a challenge slug
- **THEN** it MUST convert the slug into PascalCase (e.g. `two-sum` to `TwoSum`) to locate the corresponding test suite
- **AND** it MUST spawn a subprocess running `swift test --filter <PascalCaseSuite>` and stream all logs to the terminal

### Requirement: Benchmark Execution Overrides
The `benchmark` command MUST execute benchmarks for the target challenge and support dynamic overrides.

#### Scenario: Benchmarking with custom parameters
- **WHEN** the user runs `benchmark` with `--iterations 5 --warmup 1`
- **THEN** it MUST set the static overrides in `BenchmarkConfig` before calling the benchmarks
- **AND** the benchmark runner MUST respect those overrides during execution

### Requirement: Smart Path Resolution
The tool MUST dynamically resolve inputs, allowing the user to pass either a raw slug or a directory path.

#### Scenario: Resolving path inputs to slugs
- **WHEN** the user inputs a directory path (e.g., `./Sources/leetcodes/two-sum`) to a command
- **THEN** the resolver MUST expand the path, verify it is a valid directory, and extract its last component as the lowercase slug (e.g., `two-sum`)
- **AND** if the input does not represent a valid directory, it MUST fall back to treating it as a raw lowercase slug representation
