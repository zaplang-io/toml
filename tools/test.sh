#!/bin/sh
set -eu

root=$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)
zap=${ZAP:-zap}
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
trap 'exit 1' HUP INT TERM
export ZAP_CACHE="$scratch/cache"
unset ZAP_ZENV

# This package is at the scaffolding stage: the parser/writer/round-trip land
# through the tracked issues. Until the first implementation PR adds .zap
# sources, there is nothing to format-check or test, so the harness reports that
# and exits green. Once src/ and tests/ contain .zap files, the full flow below
# runs automatically.
fmt_dirs=""
[ -d "$root/src" ] && [ -n "$(find "$root/src" -name '*.zap' -print -quit)" ] && fmt_dirs="$fmt_dirs $root/src"
[ -d "$root/tests" ] && [ -n "$(find "$root/tests" -name '*.zap' -print -quit)" ] && fmt_dirs="$fmt_dirs $root/tests"

if [ -z "$fmt_dirs" ]; then
  echo "test.sh: no .zap sources yet (package scaffold) — nothing to check."
  exit 0
fi

# shellcheck disable=SC2086
"$zap" fmt --check $fmt_dirs

if [ -z "$(find "$root/tests" -name '*.zap' -print -quit 2>/dev/null)" ]; then
  echo "test.sh: sources present but no tests yet — skipping consumer test."
  exit 0
fi

# Exercise the public API from a consumer with toml installed as a dependency.
cd "$scratch"
ln -s "$root" toml
cat > zap.toml <<'MANIFEST'
[package]
name = "toml_tests"
version = "0.0.0"

[dependencies]
toml = { path = "toml" }
MANIFEST
"$zap" zenv create --no-venv
cp -R "$root/tests" tests
ZAP_ZENV="$scratch/zenv" "$zap" test tests/
