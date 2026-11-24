# toml

Style-preserving TOML read/write for [Zap](https://github.com/zaplang-io/zap) — an official **non-core** package.

- Tracking issue: [zaplang-io/zap#321](https://github.com/zaplang-io/zap/issues/321)
- Contributor & agent conventions: [AGENTS.md](AGENTS.md)
- Design decisions: [DECISIONS.md](DECISIONS.md)

This repository is at the scaffolding stage: the public surface and model are pinned in the [Tier-1 epic](https://github.com/zaplang-io/toml/issues/1) and its first-slice sub-issues; library code lands through those issues.

## Goals

A pure-Zap TOML 1.0.0 library whose public API mirrors Python's [**tomllib**](https://docs.python.org/3/library/tomllib.html) (parse) and [**tomli-w**](https://pypi.org/project/tomli-w/) (write) for the plain path, and [**tomlkit**](https://tomlkit.readthedocs.io/) for the comment/format-preserving round-trip. API-parity with the popular Python libraries is a project rule — see [AGENTS.md](AGENTS.md).

The differentiator is **lossless round-trip**: parse → mutate a value → emit preserves comments, key order, indentation, and whitespace for everything the edit did not touch. The Zap package manager will edit `zap.toml`/`zap.lock` in place and must not reformat the user's file.

Planned scope (first cut — TOML 1.0.0):

- **Parser** — `toml.load`/`toml.loads` → a typed `TomlDocument`; all TOML 1.0.0 types; `TomlDecodeError` with line/column. ([#3](https://github.com/zaplang-io/toml/issues/3))
- **Writer** — `toml.dump`/`toml.dumps` emitting spec-valid TOML. ([#4](https://github.com/zaplang-io/toml/issues/4))
- **Style-preserving round-trip** — parse → mutate → emit preserving comments/order/whitespace. ([#5](https://github.com/zaplang-io/toml/issues/5))
- **Public surface + model** — pinned docs-first. ([#2](https://github.com/zaplang-io/toml/issues/2))

Breadth (full date-time edge cases, pinned `toml-test` conformance, number-format fidelity on emit, richer tomlkit-style construction, streaming, schema decode) is named in the [epic](https://github.com/zaplang-io/toml/issues/1) and filed later.

## Public surface (proposed — pinned in [#2](https://github.com/zaplang-io/toml/issues/2))

```zap
import toml

# Parse (always a style-preserving document)
doc = toml.loads(text)          # TomlDocument   (cf. tomllib.loads / tomlkit.parse)
doc = toml.load("zap.toml")     # TomlDocument   (cf. tomllib.load)

# Read (typed, via the Toml value model)
name = doc["package"]["name"]   # Toml

# Emit
out = toml.dumps(doc)           # str            (cf. tomli_w.dumps / tomlkit.dumps)
toml.dump(doc, "zap.toml")      #                (cf. tomli_w.dump)
```

Style-preserving edit:

```zap
import toml

src = """
# Project manifest
[package]
name    = "demo"     # the crate name
version = "1.0.0"
"""

doc = toml.loads(src)
doc["package"]["version"] = "2.0.0"   # indexed set
print(toml.dumps(doc))
# Only the value changes — the comment, the `name` alignment, the blank line,
# and key order are all preserved.
```

Parse errors carry position:

```zap
try:
    toml.loads("x = ")
except TomlDecodeError as e:
    print(e.line, e.column, e.message)
```

### Model and divergences from Python

TOML values are modeled over a closed `Toml` value sum type (string / integer / float / bool / the four date-time forms / array / inline-table / table / array-of-tables), analogous to the `JsonValue` model used by other Zap packages — there is no untyped `dict[str, Any]`. Date-time forms map onto Zap's `time` stdlib types; integers are 64-bit signed, floats IEEE-754 binary64. `tomllib`'s `parse_float`/`parse_int` hooks and `tomli-w`'s `multiline_strings`/`indent` options are deferred. Divergences are recorded in [DECISIONS.md](DECISIONS.md) and summarized in a "differences from tomllib/tomlkit" note once the surface lands.

### Trust boundary

The TOML **text being parsed is untrusted**; the in-memory document a caller then edits is trusted. The parser bounds nesting depth, input breadth (key/array/table counts), and total work, enforces an absolute input-size cap, and rejects malformed input early. See [DECISIONS.md](DECISIONS.md) and the upstream [official-package guidelines](https://github.com/zaplang-io/zap/blob/main/docs/OFFICIAL_PACKAGE_GUIDELINES.md).

## Build and test

Run the native `zap test` suite against a temporary consumer that installs this
checkout as a package:

```
sh tools/test.sh
```

GitHub Actions runs the suite on pull requests and pushes inside the
`ghcr.io/zaplang-io/zap:latest` container. CI stays pinned to `zap:latest`
until this module reaches a 1.0 release. (Until the first implementation PR adds
sources, the harness reports that there is nothing to check yet and stays green.)

## Development

Read **[AGENTS.md](AGENTS.md)** before contributing — it covers the tomllib/tomli-w/tomlkit-parity rule, the one-issue-one-PR flow, how design decisions are recorded in **[DECISIONS.md](DECISIONS.md)**, and the rule for reporting core Zap language/stdlib defects upstream in `zaplang-io/zap` (rather than working around them here).
