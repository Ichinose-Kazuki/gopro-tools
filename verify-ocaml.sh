#!/usr/bin/env bash
# Verification script for the OCaml gopro rewrite (branch: ocaml-rewrite).
#
# Purpose: confirm whether THIS environment can enter the Nix devShell and
# build/test the OCaml project. Claude cannot run `nix develop` itself, so
# please exec this and paste the output back.
#
# Usage:   bash verify-ocaml.sh
# (or from the Claude prompt:  ! bash verify-ocaml.sh )

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO" || exit 2

line() { printf '\n=== %s ===\n' "$1"; }
ok()   { printf '  [OK]   %s\n' "$1"; }
fail() { printf '  [FAIL] %s\n' "$1"; }

# Nix needs these experimental features here (nix-command/flakes are off by default).
NIXFLAGS=(--extra-experimental-features 'nix-command flakes')

line "0. Context"
echo "  PWD=$REPO"
echo "  HOME=$HOME  USER=$(whoami)"
echo "  branch=$(git branch --show-current 2>/dev/null)"
echo "  head=$(git log --oneline -1 2>/dev/null)"

line "1. Is nix available at all?"
if command -v nix >/dev/null 2>&1; then
  ok "nix found: $(command -v nix) ($(nix --version 2>/dev/null))"
else
  fail "nix not on PATH — cannot enter devShell"
  exit 1
fi

# Everything below runs INSIDE the devShell. We pass one bash -c payload that
# does all the checks, so the shell is entered exactly once.
line "2. Enter devShell and run toolchain + build + tests"

nix "${NIXFLAGS[@]}" develop --command bash -c '
  set -uo pipefail
  status=0

  echo
  echo "--- 2a. toolchain versions ---"
  for tool in ocaml dune; do
    if command -v "$tool" >/dev/null 2>&1; then
      printf "  [OK]   %s -> %s (%s)\n" "$tool" "$(command -v $tool)" "$($tool --version 2>&1 | head -1)"
    else
      printf "  [FAIL] %s not found in devShell\n" "$tool"
      status=1
    fi
  done

  # If the toolchain is missing, no point trying to build.
  if [ "$status" -ne 0 ]; then
    echo
    echo "  Toolchain missing inside devShell — stopping before build."
    exit "$status"
  fi

  echo
  echo "--- 2b. dune build ---"
  if dune build 2>&1; then
    echo "  [OK]   dune build succeeded"
  else
    echo "  [FAIL] dune build failed (see output above)"
    status=1
  fi

  echo
  echo "--- 2c. dune runtest ---"
  if dune runtest 2>&1; then
    echo "  [OK]   dune runtest passed"
  else
    echo "  [FAIL] dune runtest failed (see output above)"
    status=1
  fi

  echo
  echo "--- 2d. run the CLI (try both exec names) ---"
  if dune exec gopro -- --help 2>&1 | head -20; then
    echo "  [OK]   ran via: dune exec gopro"
  elif dune exec main -- --help 2>&1 | head -20; then
    echo "  [OK]   ran via: dune exec main  (use this name in the plan)"
  else
    echo "  [INFO] CLI did not run (expected until subcommands are wired)"
  fi

  exit "$status"
'
rc=$?

line "3. Result"
if [ "$rc" -eq 0 ]; then
  echo "  ALL CHECKS PASSED — the environment can build & test OCaml."
  echo "  -> Reply to Claude: verification passed, resume the plan."
else
  echo "  SOMETHING FAILED (exit $rc) — see the [FAIL] lines above."
  echo "  -> Paste this whole output back to Claude."
fi
exit "$rc"
