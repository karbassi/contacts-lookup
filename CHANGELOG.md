# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [0.2.0] - 2026-03-01

### Added

- `--name` flag: search contacts by name via `CNContact.predicateForContacts(matchingName:)`
- `--email` flag: search contacts by email address via `CNContact.predicateForContacts(matchingEmailAddress:)`
- Name and email lookups return phone numbers and email addresses in results

## [0.1.0] - 2026-02-28

Initial release.

### Added

- Lookup mode: resolve one or more phone numbers to contact names via `CNContactStore`
- `--format json` (default): pretty-printed JSON array
- `--format text`: tab-separated `phone\tname` output
- `--enrich` mode: pipe NDJSON from `imsg history --json`, replace `sender` / `participants` with display names
- Resolver cache: amortizes repeated `CNContactStore` lookups in enrich mode
- Flexible phone number input: `+16085551212`, `608-555-1212`, `(608) 555-1212`, `608.555.1212`, bare digits — all resolve via `CNPhoneNumber` suffix matching
- ArgumentParser integration: `--help`, `validate()` for mutual exclusion of lookup and enrich modes
- Swift 6 strict concurrency compliance
- Universal binary (arm64 + x86_64) via GitHub Actions release workflow
- CI: SwiftLint + swiftformat + `swift test` via mise on every push
- Homebrew formula auto-updated in `karbassi/homebrew-tap` on tag push
- MIT license
