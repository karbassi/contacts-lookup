# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [0.1.0] - 2026-02-28

Initial release.

### Added

- Lookup mode: resolve one or more phone numbers to contact names via `CNContactStore`
- `--format json` (default): pretty-printed JSON array
- `--format text`: tab-separated `phone\tname` output
- `--enrich` mode: pipe NDJSON from `imsg history --json`, replace `sender` / `participants` with display names
- Resolver cache: amortizes repeated CNContactStore lookups in enrich mode
- ArgumentParser integration: proper `--help`, `validate()` for mutual exclusion
- Universal binary (arm64 + x86_64) via GitHub Actions release workflow
- Homebrew formula in karbassi/homebrew-tap
- MIT license
