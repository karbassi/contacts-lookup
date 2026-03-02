<div align="center">
	<br>
	<img width="240" src="media/logo.svg" alt="contacts-lookup">
	<br>
	<br>
</div>

> Look up contacts by phone number, name, or email from macOS Contacts

Works with any phone number format. Pipe-friendly — enriches [`imsg`](https://github.com/nicholasgetz/imsg) history in place.

## Install

### Homebrew

```sh
brew install karbassi/tap/contacts-lookup
```

### From release

```sh
curl -L https://github.com/karbassi/contacts-lookup/releases/latest/download/contacts-lookup-v0.1.0-macos-universal.tar.gz | tar xz
mv contacts-lookup /usr/local/bin/
```

### From source

```sh
git clone https://github.com/karbassi/contacts-lookup
cd contacts-lookup
swift build -c release
cp .build/release/contacts-lookup /usr/local/bin/
```

## Usage

```
$ contacts-lookup --help

OVERVIEW: Look up contacts by phone number, name, or email from macOS Contacts.

Phone lookup is the default. Use --name or --email to search by other fields.
Use --enrich to pipe NDJSON from `imsg history --json` via stdin.

USAGE: contacts-lookup [<queries> ...] [--name] [--email] [--enrich] [--format <format>]

ARGUMENTS:
  <queries>               Queries to look up. Phone numbers by default; use
                          --name or --email to change.

OPTIONS:
  --name                  Search by contact name.
  --email                 Search by email address.
  --enrich                Read NDJSON from stdin and enrich sender/participants
                          with contact names.
  --format <format>       Output format: json (default) or text
                          (tab-separated). (default: json)
  -h, --help              Show help information.
```

### Examples

```sh
contacts-lookup +14155551212 +16505551234
contacts-lookup --format text +14155551212
contacts-lookup --name "Jane Doe"
contacts-lookup --email jane@example.com
imsg history --chat-id 215 --json | contacts-lookup --enrich
imsg history --chat-id 215 --json | contacts-lookup --enrich --format text
```

## Phone number formats

All of the following resolve to the same contact:

```
+16085551212
16085551212
6085551212
+1 (608) 555-1212
(608) 555-1212
608-555-1212
608.555.1212
```

Matching is done via `CNPhoneNumber` suffix matching. Partial suffixes work — `555-1212` will match if unambiguous. Prefix-only fragments (e.g. just an area code) do not match.

## Output formats

| Mode | Flag | Output |
|------|------|--------|
| Lookup | `--format json` (default) | Pretty-printed JSON array of `{query, name, phones, emails}` |
| Lookup | `--format text` | `query\tname` one line per result (tab-separated) |
| Enrich | `--enrich` | NDJSON passthrough with `sender`/`participants` replaced by names |
| Enrich | `--enrich --format text` | `sender\ttext` tab-separated lines |

## Permissions

On first run, macOS prompts for Contacts access. Grant it via:

**System Settings → Privacy & Security → Contacts → contacts-lookup ✓**

If the prompt never appears (SSH session, cron, etc.) and you see:

```
error: contacts access denied.
```

Run the binary once interactively from Terminal to register it with TCC, then grant access in Settings.

## Related

- [imsg](https://github.com/nicholasgetz/imsg) - Read iMessage history from the terminal
