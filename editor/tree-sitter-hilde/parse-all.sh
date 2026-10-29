#!/usr/bin/env bash
#
# Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# SPDX-FileCopyrightText: 2026 Heiko Zimmermann
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
# Parses every .hih and .hiq file under standard/src and examples with the
# grammar in this directory.  Prints each file whose tree holds an ERROR or
# MISSING node, then the counts.  Exit 0 when every file parses cleanly,
# 1 when at least one does not, 9 when the check could not run.
#
#   editor/tree-sitter-hilde/parse-all.sh

if [ -z "${BASH_VERSION:-}" ]; then
  echo "ABORT: run with bash" >&2
  exit 9
fi

cd "$(dirname "$0")" || exit 9
command -v tree-sitter >/dev/null 2>&1 || { echo "ABORT: tree-sitter not on PATH" >&2; exit 9; }
test -e src/parser.c || { echo "ABORT: src/parser.c missing, run tree-sitter generate" >&2; exit 9; }

root=../..
total=0
clean=0
bad=0
errors=0
while IFS= read -r -d '' file; do
  total=$((total + 1))
  tree=$(tree-sitter parse "$file" 2>/dev/null)
  rc=$?
  n=$(printf '%s\n' "$tree" | grep -o -E '\((ERROR|MISSING)' | wc -l | tr -d ' ')
  if [ "$rc" -eq 0 ] && [ "$n" -eq 0 ]; then
    clean=$((clean + 1))
  else
    bad=$((bad + 1))
    errors=$((errors + n))
    echo "$n ${file#"$root"/}"
  fi
done < <(find "$root/standard/src" "$root/examples" -type f \( -name '*.hih' -o -name '*.hiq' \) -print0 | sort -z)

echo "files: $total, clean: $clean, with errors: $bad, error nodes: $errors"
if [ "$total" -eq 0 ]; then
  echo "ABORT: no files found" >&2
  exit 9
fi
if [ "$clean" -ne $((total - bad)) ]; then
  echo "ABORT: counts do not add up" >&2
  exit 9
fi
[ "$bad" -eq 0 ]
