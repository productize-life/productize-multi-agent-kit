#!/usr/bin/env bash
# roster-reconcile.sh — compare the members that are RUNNING against the roster in AGENTS.md,
# in BOTH directions, and fail if they disagree.
#
# WHY BOTH DIRECTIONS: the check people write compares the file against reality and stops there,
# which catches a member that died. It misses the case that actually hurts — a member running that
# nobody remembers starting, holding valid credentials, answering in a room somebody watches.
#
# WHY IT FAILS CLOSED: if the command that lists running members returns nothing, this exits 3
# rather than reporting "0 mismatches". A checker that reports clean when its input is empty is a
# checker that does not exist. (Ask yourself of any check: "if this died, how would the output
# differ?" If the answer is "it wouldn't", it is already dead.)
#
# USAGE
#   ROSTER_CMD='<command printing one running member name per line>' ./roster-reconcile.sh [AGENTS.md]
#
#   # systemd example
#   ROSTER_CMD="systemctl list-units '*-agent.service' --plain --no-legend | awk '{sub(/-agent.service/,\"\",\$1); print \$1}'"
#   # tmux example
#   ROSTER_CMD="tmux list-sessions -F '#S'"
#   # docker example
#   ROSTER_CMD="docker ps --format '{{.Names}}'"
#
#   ./roster-reconcile.sh --self-test    # proves the checker can go red (see below)
#
# EXIT CODES
#   0  roster and reality agree
#   1  they disagree (details on stdout)
#   2  usage / cannot read the roster file
#   3  the roster command produced nothing — refusing to call that "clean"

set -uo pipefail

SELF_TEST=0
[ "${1:-}" = "--self-test" ] && { SELF_TEST=1; shift; }
FILE="${1:-AGENTS.md}"

# Members are the first backticked cell of each roster row. Rows carrying an example marker are
# skipped: a template row is not a member, and treating it as one makes every fresh copy fail.
parse_roster() {
  grep -E '^\|\s*`[a-z0-9][a-z0-9_-]*`' "$1" \
    | grep -v '<!-- example -->' \
    | sed -E 's/^\|[[:space:]]*`([^`]+)`.*/\1/' \
    | sort -u
}

if [ "$SELF_TEST" = 1 ]; then
  # Positive control. A checker nobody has watched fail is an assumption.
  # Plant a roster with one member and a reality with a different one; both arms must be reported.
  tmp=$(mktemp -d) || exit 2
  trap 'rm -rf "$tmp"' EXIT
  printf '| Member | Exists to |\n|---|---|\n| `in-file-only` | x |\n' > "$tmp/AGENTS.md"
  out=$(ROSTER_CMD="printf 'running-only\\n'" "$0" "$tmp/AGENTS.md")
  rc=$?
  echo "$out"
  ok=0
  grep -q 'in-file-only' <<<"$out" && grep -q 'running-only' <<<"$out" && [ "$rc" = 1 ] && ok=1
  # And the fail-closed arm: an empty roster command must be exit 3, never a clean pass.
  ROSTER_CMD="true" "$0" "$tmp/AGENTS.md" >/dev/null 2>&1
  [ $? = 3 ] || ok=0
  if [ "$ok" = 1 ]; then echo "self-test: PASS (both directions reported, empty input refused)"; exit 0
  else echo "self-test: FAIL — this checker cannot be trusted"; exit 1; fi
fi

[ -f "$FILE" ] || { echo "cannot read roster: $FILE" >&2; exit 2; }
: "${ROSTER_CMD:?set ROSTER_CMD to a command that prints one running member per line}"

IN_FILE=$(parse_roster "$FILE")
RUNNING=$(eval "$ROSTER_CMD" 2>/dev/null | sed -E 's/[[:space:]]+$//' | grep -v '^$' | sort -u)

if [ -z "$RUNNING" ]; then
  echo "roster command produced no members — treating as BROKEN, not as an empty fleet" >&2
  echo "  command: $ROSTER_CMD" >&2
  exit 3
fi

MISSING=$(comm -23 <(printf '%s\n' "$IN_FILE") <(printf '%s\n' "$RUNNING"))
GHOSTS=$(comm -13 <(printf '%s\n' "$IN_FILE") <(printf '%s\n' "$RUNNING"))

status=0
if [ -n "$MISSING" ]; then
  status=1
  echo "in the roster but NOT running:"
  printf '  %s\n' $MISSING
  echo "  → either it died, or it was retired without removing its row (and its credentials)"
fi
if [ -n "$GHOSTS" ]; then
  status=1
  echo "running but NOT in the roster:"
  printf '  %s\n' $GHOSTS
  echo "  → an unlisted member with real credentials. Charter it or stop it; do not leave it."
fi
[ "$status" = 0 ] && echo "roster and reality agree ($(printf '%s\n' "$IN_FILE" | grep -c . ) members)"
exit "$status"
