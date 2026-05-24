# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [v1.0.0] - 2026-05-23

### ✨ Features
- Integrated `leetswift` CLI with `run`, `test`, `benchmark`, and `list` commands
- Smart path resolver: accepts a slug (`two-sum`) or a directory path interchangeably
- High-fidelity benchmarks using `ContinuousClock` and `task_vm_info` / `/proc/self/status`
- Cross-platform support: macOS (Darwin) and Linux via GitHub Actions CI matrix
- Swift 6.0 strict concurrency compliance (`Sendable`, `nonisolated(unsafe)`, `final`)
- Parameterized unit tests via Swift Testing framework (`@Suite`, `@Test`, `arguments:`)
- `create.swift` automation script for generating templates and auto-registering problems
- `TestDataLoader` for loading raw test input files relative to the calling test file
- `Two Sum` as fully-documented golden reference example (V1: O(N), V2: O(N²))
- Dynamic `Package.swift` exclusions for 100% warning-free builds
- `Makefile` for global CLI installation
- MIT License

### 👷 CI
- GitHub Actions matrix: macOS + Ubuntu
- `commitlint` blocking PR check for Conventional Commits enforcement
- `bump-version` workflow dispatch for one-click semver tagging
- Tag-triggered release pipeline with `git-cliff` changelog generation

[v1.0.0]: https://github.com/GioBar00/swift-leetcode-diary/releases/tag/v1.0.0
