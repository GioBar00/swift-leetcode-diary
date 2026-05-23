# Core Library Engine Specification

## Purpose
The Core Library Engine provides the fundamental protocols, shared structures, registry mappings, and performance benchmarking mechanics required to implement, compile, and analyze LeetCode challenges in a clean, unified local environment.

## Requirements

### Requirement: Challenge Protocol Interface
All LeetCode challenges MUST conform to a standard `LeetCodeChallenge` protocol to allow modular and polymorphic execution by CLI tools.

#### Scenario: Running solution variant via protocol
- **WHEN** a challenge is executed via its protocol interface with a valid solution variant and input JSON string
- **THEN** it MUST return the calculated solution output as a string representation
- **AND** it MUST throw a standard `LeetCodeError` if the variant is unknown or input parsing fails

### Requirement: Central Challenge Registry
The engine MUST maintain a central, statically declared `ChallengeRegistry` that registers every active challenge by mapping its unique lowercase slug to its corresponding type.

#### Scenario: Querying challenge type by slug
- **WHEN** the CLI queries the registry using a valid lowercase slug
- **THEN** the registry MUST resolve and return the corresponding challenge type
- **AND** it MUST return nil or throw an error if the slug is not registered

### Requirement: Cold Start Dry-Run Elimination
To eliminate memory allocating page spikes and ensure high-fidelity steady-state benchmarks, the benchmarking suite MUST execute a global dry-run warmup block of 500 iterations before starting any real measurements.

#### Scenario: Eliminating cold start timing and memory distortion
- **WHEN** benchmarks are initialized for a specific challenge
- **THEN** the benchmark runner MUST trigger 500 dry-run iterations of the first input dataset to prime the heap allocator and populate CPU caches
- **AND** no time or memory measurements SHALL be recorded during this phase

### Requirement: Steady-State Local Warmups
The benchmark runner MUST run a local warm-up loop before measuring active memory or time values.

#### Scenario: Steady-state warming of solution code
- **WHEN** benchmarking starts for a specific input size
- **THEN** the runner MUST invoke the solution code 20 times (or a count overridden by configurations) to populate steady-state heap segments
- **AND** these iterations SHALL NOT be included in the timed average calculations

### Requirement: physical Memory Tracking
The benchmark runner MUST track absolute physical memory footprint, leveraging platform-specific resident segment metrics.

#### Scenario: Measuring physical footprints on macOS and Linux
- **WHEN** memory is measured during active steady-state running
- **THEN** it MUST return the exact Darwin physical resident footprint (`task_vm_info.phys_footprint`) on macOS platforms
- **AND** it MUST return the RSS resident segment (`VmRSS` from `/proc/self/status`) on Linux platforms

### Requirement: ContinuousClock Performance Benchmarking
The engine MUST calculate precise solution execution speeds using modern continuous timing.

#### Scenario: Timing iterations with high-fidelity clocks
- **WHEN** timing execution across configured iterations (1000 for small sizes, 50 for large sizes)
- **THEN** the runner MUST use `ContinuousClock` to record average execution speed in microseconds
- **AND** it MUST format durations using appropriate units (nanoseconds, microseconds, milliseconds, or seconds)

### Requirement: ASCII Complexity Analysis Charting
The runner MUST render horizontal visual bars of execution timing to allow immediate visual analysis of asymptotic time complexity.

#### Scenario: Charting timing complexity
- **WHEN** execution completes for all input sizes in a suite
- **THEN** the runner MUST draw a horizontal ASCII bar chart scaled relative to the maximum execution duration
- **AND** it MUST print the raw average execution speed next to each bar

### Requirement: JSON Metrics Persistence
The engine MUST serialize and persist the measured benchmarks locally to preserve historical execution records.

#### Scenario: Saving benchmark results to JSON
- **WHEN** all benchmarking loops are successfully finished
- **THEN** the runner MUST write a `benchmark_results.json` file inside the calling challenge's source folder
- **AND** the file MUST conform to the `BenchmarkReport` structure, containing input sizes, average times, and memory bytes used
