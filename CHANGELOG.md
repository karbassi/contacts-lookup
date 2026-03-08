# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [0.3.0] - 2026-03-08

### Added

- `--format ndjson`: one JSON object per line, ideal for streaming and piping to other tools
- Lookup results now include `birthday`, `city`, `organization`, `gender`, and `pronouns` fields
- Gender inferred from macOS Contacts `X-GENDER` field and pronoun entries

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

[Unreleased]: https://github.com/karbassi/apple-contacts-cli/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/karbassi/apple-contacts-cli/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/karbassi/apple-contacts-cli/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/karbassi/apple-contacts-cli/commits/v0.1.0
