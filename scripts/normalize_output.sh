#!/usr/bin/env bash
set -eu

if [ $# -ne 2 ]; then
  echo "Usage: $0 <clang_out.i> <mcpp_out.i>"
  exit 1
fi

clang_in="$1"
mcpp_in="$2"
clang_out="${clang_in}.normalized"
mcpp_out="${mcpp_in}.normalized"

normalize() {
  local input="$1"
  local output="$2"

  sed -E '
    # Remove all `#` or `#line` directives — even if they span quoted or angle-bracket paths
    /^#(line)?[[:space:]]*[0-9]+[[:space:]]*["<][^">]+[">]( [0-9]+)*$/d

    # Remove any remaining lines starting with `#` followed by line numbers and quoted paths
    /^#(line)?[[:space:]]*[0-9]+/d

    # Remove any lines containing only preprocessor directives
    /^#.*$/d

    # Normalize whitespace
    s/[[:space:]]+/ /g
    s/^[[:space:]]+//g
    s/[[:space:]]+$//g

    # Remove empty lines
    /^[[:space:]]*$/d

    # Normalize formatting artifacts
    s/\)\s+;/);/g
    s/\)\s+,/),/g
  ' "$input" |
  awk '
    {
      if ($0 == last) next;
      last = $0;
      print
    }
  ' > "$output"
}

normalize "$clang_in" "$clang_out"
normalize "$mcpp_in"  "$mcpp_out"

diff -U0 --label "$clang_out" --label "$mcpp_out" --color -u "$clang_out" "$mcpp_out"
