# toml workspace conventions (zaplang-io/toml)

This is an official non-core Zap module. Target: parity with the popular Python
equivalents — [tomllib](https://docs.python.org/3/library/tomllib.html) (parse),
[tomli-w](https://pypi.org/project/tomli-w/) (write), and
[tomlkit](https://tomlkit.readthedocs.io/) (style-preserving round-trip), with
[TOML 1.0.0](https://toml.io/en/v1.0.0) as the normative spec.

## Language-first (non-negotiable)
- All language or stdlib bugs discovered while building this module MUST be reported in `zaplang-io/zap` FIRST, and no workaround is permitted. Keep the dependent work blocked or draft and report the dependency; never build the library around a core defect.

## Python parity & signatures
- Match the equivalent `tomllib`/`tomli-w`/`tomlkit` API surface and naming as closely as the language allows; TOML 1.0.0 is the tie-breaker when the libraries differ.
- Where a function/method signature is ambiguous or there is any confusion about argument shape, defaults, or keyword-vs-positional, do NOT just pick one: present the options to the maintainer with concrete examples of what the Python libraries do, and let the maintainer decide. Record the chosen design in `DECISIONS.md`.

## Trust boundary & resource bounds
- Parse input is untrusted; the edited in-memory document is trusted. Follow the upstream [official-package guidelines](https://github.com/zaplang-io/zap/blob/main/docs/OFFICIAL_PACKAGE_GUIDELINES.md): bound nesting depth AND input breadth AND total work (not depth alone), cap input size, use overflow-safe length arithmetic, and reject malformed input early. Never echo unbounded attacker input in an error message.

## Tests
- All test cases live in the `tests/` folder and use the `zap test` methodology (`zap test tests/`).
- Every PR MUST include extensive positive AND negative test cases — treat tests as a walled garden and as intent documentation, not a minimal smoke check. Cover every value type, error paths, malformed input, and the resource bounds (including a large-breadth input, not just deep nesting).
- When fixing a bug, write the failing test first, then fix.
- Prefer test vectors with provenance — draw from `toml-lang/toml-test` where practical and record the pinned source.

## CI
- CI runs against `ghcr.io/zaplang-io/zap:latest` and MUST continue to pin `zap:latest` until this module reaches a proper major (1.0) version release; only then pin a released toolchain version.

## Issues & PRs
- Keep issues concrete and testable with detailed bodies (repro or intended syntax, Python equivalent, references).
- Multi-issue features get an Epic with trackable sub-issues. Individual issues are 'M' sized.
- One issue, one PR. Rebase onto the latest default branch before raising or updating a PR.
- Documentation (README, DECISIONS.md, CHANGELOG) stays current with every PR.

## Attribution
- No agent/model attribution in commits, PR titles/bodies, or issue bodies/titles — maintainer's name only. PR and issue comments may carry a "Reviewed by …" / "… input on …" attribution; nothing else does.
