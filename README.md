<div align="center">

# contacts-lookup

**Resolve phone numbers to contact names — fast, scriptable, `imsg`-aware.**

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange?style=flat-square&logo=swift)](https://swift.org)
[![macOS](https://img.shields.io/badge/macOS-12+-000000?style=flat-square&logo=apple)](https://www.apple.com/macos/)
[![License](https://img.shields.io/github/license/karbassi/contacts-lookup?style=flat-square)](LICENSE)

A macOS CLI that resolves phone numbers to display names using `CNContactStore`.<br>
Works standalone or as a post-processor for [`imsg`](https://github.com/nicholasgetz/imsg).

</div>

---

## Install

### Homebrew

```bash
brew tap karbassi/tap
brew install contacts-lookup
```

### From release

```bash
curl -L https://github.com/karbassi/contacts-lookup/releases/latest/download/contacts-lookup-<version>-macos-universal.tar.gz | tar xz
mv contacts-lookup /usr/local/bin/
```

### From source

```bash
git clone https://github.com/karbassi/contacts-lookup
cd contacts-lookup
swift build -c release
cp .build/release/contacts-lookup /usr/local/bin/
```

## Quick Start

```bash
# Resolve phone numbers → JSON (default)
contacts-lookup +14155551212 +16505551234

# Tab-separated text
contacts-lookup --format text +14155551212

# Pipe imsg history — enrich sender + participants
imsg history --chat-id 215 --json | contacts-lookup --enrich

# Enrich + text output (sender<tab>message)
imsg history --chat-id 215 --limit 20 --json | contacts-lookup --enrich --format text
```

## Output formats

| Mode | Flag | Output |
|------|------|--------|
| Lookup | `--format json` (default) | Pretty-printed JSON array of `{phone, name}` |
| Lookup | `--format text` | `phone\tname` one line per number |
| Enrich | `--enrich` | NDJSON passthrough with `sender`/`participants` replaced by names |
| Enrich | `--enrich --format text` | `sender\ttext` tab-separated lines |

### Lookup — JSON

```json
[
  {
    "name": "Jane Doe",
    "phone": "+14155551212"
  },
  {
    "name": "",
    "phone": "+16505551234"
  }
]
```

### Lookup — text

```
+14155551212	Jane Doe
+16505551234
```

### Enrich

Reads one JSON object per line from stdin, enriches in place:

```jsonl
{"sender":"Jane Doe","text":"hey","participants":["Jane Doe","+16505551234"],...}
```

## Usage

```
USAGE: contacts-lookup [<phones> ...] [--enrich] [--format <format>]

ARGUMENTS:
  <phones>        Phone numbers to resolve (e.g. +14155551212).
                  Ignored when --enrich is used.

OPTIONS:
  --enrich        Read NDJSON from stdin, enrich sender/participants.
  --format        Output format: json (default) or text.
  -h, --help      Show help information.
```

## Permissions

On first run, macOS prompts for Contacts access. Grant it via:

**System Settings → Privacy & Security → Contacts → contacts-lookup ✓**

If the prompt never appears (SSH session, cron, etc.) and you see:

```
error: contacts access denied.
Grant access in System Settings → Privacy & Security → Contacts.
```

Run the binary once interactively from Terminal to register it with TCC, then grant access in Settings.

## License

[MIT](LICENSE)
