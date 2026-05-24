# Build System Specification

## Purpose
The Build System (defined in `Package.swift`) configures the Swift Package Manager (SPM) architecture, platform support, dependencies, products, targets, and custom file exclusions. To maintain a modern, warnings-free development experience, it dynamically excludes non-source code resource files (such as markdown documentation, JSON benchmarks, and raw test inputs) from the compilation graph.

## Requirements

### Requirement: SPM Target Architecture Compilation
The package configuration MUST build a structured collection of library and executable targets targeting modern platform configurations.

#### Scenario: Compiling targets under Package Description
- **WHEN** building the package via SPM (`swift build`)
- **THEN** it MUST compile the library target `leetcodes` containing the core logic
- **AND** it MUST compile the executable product `leetswift` linked against the library and the `swift-argument-parser` dependency
- **AND** it MUST compile unit test targets under `leetcodesTests` to verify solution correctness

### Requirement: Dynamic Compilation Exclusions
To keep builds 100% warning-free as developers add challenges, the build configuration MUST dynamically discover and exclude all non-compiled asset files from target compilation.

#### Scenario: Dynamically excluding documentation and metrics
- **WHEN** the package targets are planned and initialized
- **THEN** the core library target `leetcodes` MUST dynamically scan the `Sources/leetcodes` directory and exclude all `.md` and `.json` files from being compiled
- **AND** the test target `leetcodesTests` MUST dynamically scan the `Tests/leetcodesTests` directory and exclude all `.txt` and `.json` resource files from being compiled
- **AND** the compilation process SHALL execute successfully with zero warnings regarding unprocessed resources
