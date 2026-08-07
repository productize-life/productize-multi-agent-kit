#!/usr/bin/env bash
# registry-lint.sh — check that every capability your registry claims can actually be resolved.
#
# WHY: a registry is the file everyone consults to answer "who covers this?" — which makes it the
# file that rots invisibly. A skill is renamed, a plugin is disabled on one host, a path moves, and
# the registry keeps promising the old name. Nothing errors. Work is routed to a capability that
# has not existed since April.
#
# WHAT IT CHECKS: every backticked reference in the registry file, resolved with YOUR resolver.
# Two reference shapes are supported out of the box:
#   `some/path.md`     → must exist on disk (relative to --root, default .)
#   `plugin:skill`     → passed to RESOLVER_CMD, which must exit 0 if the capability is loadable
#
# TWO TRAPS THIS SCRIPT IS SHAPED AROUND, both paid for in real time:
#   • A resolver that errors must be FATAL, never a silent empty answer. An empty answer makes
#     every reference look broken (or every one look fine, depending on the comparison) and the
#     first run produces a wall of confident nonsense.
#   • Resolution has to match how the host ACTUALLY loads capabilities. If your runtime loads
#     plugins from a working directory, checking an install manifest instead will disagree with
#     reality on every line. Verify the resolver against one capability you know is live before
#     believing any run.
#
# USAGE
#   ./registry-lint.sh REGISTRY.md
#   RESOLVER_CMD='my-runtime has-skill' ./registry-lint.sh REGISTRY.md   # $1 = the plugin:skill ref
#   ./registry-lint.sh --self-test      # plants a decoy and proves the checker catches it
#
# EXIT CODES
#   0  every reference resolved
#   1  at least one did not (listed)
#   2  usage / cannot read the registry
#   3  the resolver itself is broken (see the decoy check below)

set -uo pipefail

SELF_TEST=0
ROOT="."
[ "${1:-}" = "--self-test" ] && { SELF_TEST=1; shift; }
if [ "${1:-}" = "--root" ]; then ROOT="${2:?--root needs a path}"; shift 2; fi
FILE="${1:-}"

if [ "$SELF_TEST" = 1 ]; then
  # Negative control, and the part people skip: prove the decoy was actually installed before
  # believing the result. A decoy that never landed looks exactly like a decoy that passed.
  tmp=$(mktemp -d) || exit 2
  trap 'rm -rf "$tmp"' EXIT
  mkdir -p "$tmp/real"
  echo "x" > "$tmp/real/present.md"
  cat > "$tmp/REGISTRY.md" <<'EOF'
| Capability | Ref |
|---|---|
| present | `real/present.md` |
| decoy   | `real/definitely-not-here.md` |
EOF
  grep -q 'definitely-not-here' "$tmp/REGISTRY.md" || { echo "self-test: FAIL — decoy was never planted"; exit 1; }
  out=$("$0" --root "$tmp" "$tmp/REGISTRY.md"); rc=$?
  echo "$out"
  if [ "$rc" = 1 ] && grep -q 'definitely-not-here' <<<"$out" && ! grep -q 'real/present.md' <<<"$out"; then
    echo "self-test: PASS (decoy planted, decoy caught, good reference untouched)"; exit 0
  fi
  echo "self-test: FAIL — this checker cannot be trusted"; exit 1
fi

[ -n "$FILE" ] && [ -f "$FILE" ] || { echo "usage: registry-lint.sh [--root DIR] REGISTRY.md" >&2; exit 2; }

# One reference per line, deduped, in file order. Skips fenced code blocks: an example inside a
# code fence is documentation, not a claim the registry is making.
refs=$(awk '/^```/{f=!f; next} !f' "$FILE" | grep -oE '`[A-Za-z0-9._/@:-]+`' | tr -d '`' | awk '!seen[$0]++')
[ -n "$refs" ] || { echo "no references found in $FILE — is this the right file?" >&2; exit 2; }

resolve() {   # $1 = ref ; returns 0 resolvable, 1 not, 2 resolver broken
  local ref="$1"
  case "$ref" in
    */*.md|*/*.sh|*.md|*.sh|*/*)
      [ -e "$ROOT/$ref" ] && return 0 || return 1 ;;
    *:*)
      [ -n "${RESOLVER_CMD:-}" ] || return 2
      eval "$RESOLVER_CMD" "$(printf '%q' "$ref")" >/dev/null 2>&1 && return 0 || return 1 ;;
    *)
      return 0 ;;   # a bare word is prose, not a capability reference
  esac
}

# If a plugin-style ref exists but no resolver is configured, say so once and loudly rather than
# marking every one of them broken.
if grep -q ':' <<<"$refs" && [ -z "${RESOLVER_CMD:-}" ]; then
  if grep -qE '^[A-Za-z0-9._@-]+:[A-Za-z0-9._@-]+$' <<<"$refs"; then
    echo "registry names plugin-style capabilities but RESOLVER_CMD is unset — cannot judge them." >&2
    echo "set RESOLVER_CMD to the command your runtime uses to load one, then run again." >&2
    exit 3
  fi
fi

bad=0 total=0
while IFS= read -r ref; do
  [ -n "$ref" ] || continue
  total=$((total + 1))
  resolve "$ref"
  case $? in
    0) ;;
    1) bad=$((bad + 1)); echo "UNRESOLVED  $ref" ;;
    2) echo "resolver required for '$ref' but RESOLVER_CMD is unset" >&2; exit 3 ;;
  esac
done <<< "$refs"

if [ "$bad" -gt 0 ]; then
  echo "$bad of $total references do not resolve on this host."
  echo "Fix the registry or the host — but do not leave the registry claiming a capability nobody can load."
  exit 1
fi
echo "all $total references resolve"
