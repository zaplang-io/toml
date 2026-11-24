# toml package decisions

Design decisions for the Zap `toml` library, keyed to issues. Each records a
choice that could not be read straight off Python's
[tomllib](https://docs.python.org/3/library/tomllib.html) /
[tomli-w](https://pypi.org/project/tomli-w/) /
[tomlkit](https://tomlkit.readthedocs.io/), with the reference it follows or
departs from. Signature and surface ambiguities are resolved with the maintainer
(with Python examples) before being recorded here.

## Parity target: tomllib / tomli-w / tomlkit

The package tracks Python's [**tomllib**](https://docs.python.org/3/library/tomllib.html)
(parse) and [**tomli-w**](https://pypi.org/project/tomli-w/) (write) for the plain
path, and [**tomlkit**](https://tomlkit.readthedocs.io/) for the style-preserving
round-trip. [TOML 1.0.0](https://toml.io/en/v1.0.0) is the tie-breaker when the
libraries differ, and the upstream [`toml-lang/toml-test`](https://github.com/toml-lang/toml-test)
suite is the conformance oracle. Deviations are recorded below, keyed to the
issue that introduces them.

## Forced divergences from Python (static typing)

Zap is statically typed, so the surface cannot match Python 1:1. The following
are decided by the language and recorded now; a user-facing "differences from
tomllib/tomlkit" note lands with the surface ([#2](https://github.com/zaplang-io/toml/issues/2)):

- **No untyped `dict[str, Any]`.** TOML values are heterogeneous, so the document
  is modeled over a closed `Toml` value sum type (string / integer / float / bool
  / offset-datetime / local-datetime / local-date / local-time / array /
  inline-table / table / array-of-tables). Typed access returns `Toml`; there is
  no bare `Any`.
- **Date-time mapping.** TOML's four date-time forms map onto Zap's `time` stdlib
  types rather than Python's `datetime` module. The exact mapping is pinned in
  [#2](https://github.com/zaplang-io/toml/issues/2).
- **Numeric model.** TOML integers are 64-bit signed (spec minimum); floats are
  IEEE-754 binary64. Integer overflow and float rounding follow Zap's numeric
  model, recorded rather than hidden.
- **Deferred keyword-arg hooks.** `tomllib`'s `parse_float`/`parse_int` and
  `tomli-w`'s `multiline_strings`/`indent` are out of the first slice; whether
  they become keyword args later is a separate decision.

## Open decisions (owned by the surface sub-issue [#2](https://github.com/zaplang-io/toml/issues/2))

- **One document type, always style-preserving, vs. a lossy fast path plus a
  style path.** Python splits these (`tomllib.loads` → plain `dict`;
  `tomlkit.parse` → style-preserving `TOMLDocument`). Because the charter is
  style-preserving and the first consumer edits files in place, the **recommended**
  choice is a single always-style-preserving `TomlDocument` under the familiar
  `tomllib` names (`load`/`loads`). To be confirmed and recorded in #2.
- **Indexed get/set overload dependency.** The round-trip surface relies on
  `doc["k"]` / `doc["k"] = v` on a user-defined `TomlDocument`. #2 must confirm
  the language can express indexed get/set overloads today. If it cannot, that is
  a core language gap — it is filed in `zaplang-io/zap`, linked here, and the
  round-trip sub-issue ([#5](https://github.com/zaplang-io/toml/issues/5)) blocks
  on it. No workaround is built around the gap (language-first rule).

## Trust boundary ([#3](https://github.com/zaplang-io/toml/issues/3))

Parse input is attacker-controlled; the edited in-memory document is trusted.
Per the upstream
[official-package guidelines](https://github.com/zaplang-io/zap/blob/main/docs/OFFICIAL_PACKAGE_GUIDELINES.md),
the parser bounds nesting **depth**, input **breadth** (key/array/table counts),
and **total work** via a single monotonic budget, enforces an absolute input-size
cap, uses overflow-safe length arithmetic, and rejects malformed input early and
specifically rather than coercing liberally. `TomlDecodeError` carries 1-based
line/column and never echoes unbounded attacker input.
