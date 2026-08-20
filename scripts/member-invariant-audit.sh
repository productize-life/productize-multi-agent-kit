#!/usr/bin/env bash
# member-invariant-audit.sh — assert that EVERY running member still carries the properties
# your fleet decided every member must have.
#
# roster-reconcile.sh answers "is the right SET of members running?" — presence, both directions.
# This answers the next question, which presence-reconciliation is blind to:
#
#     every member is present, correctly listed, and eight of them are missing the thing
#     that was supposed to tell you when they die.
#
# That state reconciles clean. Both arms are green. Nothing is missing and nothing is a ghost.
#
# Why it happens, every time, the same way: a rule gets added after an incident, and it is applied
# by hand to the members that exist that day. The generator that mints NEW members is not touched,
# because it was not what broke. Every member created afterwards is born without the rule, and the
# gap is invisible by construction — the only signal a missing death-alarm produces is a member
# dying quietly, which is exactly what the missing alarm was there to report. An absent alarm hides
# its own absence.
#
# Measured, in one fleet, twelve days after such a rule was written: 5 of 14 members had no death
# alarm, and 8 of 14 were on a restart policy that does not restart a clean exit — so a member that
# exited with status 0 stayed dead and the alarm stayed deliberately silent, because the stop was
# "successful". Nobody had done anything wrong since the day the rule was written.
#
# So the fix is never "add it to the five". It is a PAIR:
#   1. the generator emits the property, so member N+1 is born correct;
#   2. this audit walks the whole roster and fails loudly, so the claim has a denominator.
#
# Two questions worth asking of any rule you add. If you cannot answer both, the rule will decay
# silently as the fleet grows, and there will be no day on which it looks wrong:
#   - "Will the N+1th member have this?"
#   - "Who counts, right now, how many members do not?"
#
# ---------------------------------------------------------------------------------------------
# Usage
#
#   MEMBER_CMD='<prints one running member name per line>' \
#   PROP_CMD='<prints key=value lines for the member named in $1>' \
#   REQUIRE='key=value[,key=value...]' \
#     ./member-invariant-audit.sh [member]
#
#   ./member-invariant-audit.sh --self-test    # prove the checker can go red, then restore
#
# Both hooks are yours because the supervisor is yours. Worked examples:
#
#   systemd
#     MEMBER_CMD="systemctl list-units '*-agent.service' --all --plain --no-legend \
#                   | awk '{sub(/-agent.service/,\"\",\$1); print \$1}'"
#     PROP_CMD='systemctl show "$1-agent.service" -p Restart -p OnFailure -p ExecStopPost'
#     REQUIRE='Restart=always,OnFailure=*,ExecStopPost=*crash-alert*'
#
#   docker
#     MEMBER_CMD="docker ps --format '{{.Names}}'"
#     PROP_CMD='docker inspect --format "RestartPolicy={{.HostConfig.RestartPolicy.Name}}
#               Healthcheck={{if .Config.Healthcheck}}yes{{else}}no{{end}}" "$1"'
#     REQUIRE='RestartPolicy=always,Healthcheck=yes'
#
#   tmux / any supervisor: same shape — one command lists members, one prints their properties.
#
# Matching: a REQUIRE value containing `*` is a glob (so `ExecStopPost=*crash-alert*` accepts
# whatever path your supervisor prints around the name). Everything else is exact.
#
# Exit: 0 all members satisfy every requirement · 1 at least one does not · 2 the check itself
# could not run. An empty roster is exit 2, never 0 — "no members found" and "no members
# configured" print the same nothing, and only one of them is fine.
set -uo pipefail

die() { echo "member-invariant-audit: $*" >&2; exit 2; }

SELF_TEST=0
[ "${1:-}" = "--self-test" ] && { SELF_TEST=1; shift; }
ONLY="${1:-}"

[ -n "${MEMBER_CMD:-}" ] || die "MEMBER_CMD is unset — refusing to report on a roster it cannot enumerate"
[ -n "${PROP_CMD:-}" ]   || die "PROP_CMD is unset — refusing to report properties it never read"
[ -n "${REQUIRE:-}" ]    || die "REQUIRE is unset — an audit with no requirements always passes, which is worse than no audit"

members() {
  # A supervisor that errors must not read as an empty fleet.
  local out rc
  out="$(eval "$MEMBER_CMD" 2>/dev/null)"; rc=$?
  [ $rc -eq 0 ] || die "MEMBER_CMD exited $rc — treating that as a broken enumerator, not an empty fleet"
  printf '%s\n' "$out" | sed '/^[[:space:]]*$/d'
}

# PROP_CMD refers to the member as "$1", so set the positional parameters before evaluating it —
# appending the name to the command string instead would only work for commands that happen to
# take it last, and would silently produce the wrong properties for the ones that do not.
props_of() { local m="$1"; eval "set -- \"\$m\"; $PROP_CMD" 2>/dev/null; }

matches() { # matches <actual> <expected>
  case "$2" in
    *'*'*) case "$1" in $2) return 0;; *) return 1;; esac ;;
    *)     [ "$1" = "$2" ] ;;
  esac
}

audit_one() { # audit_one <member> -> 0 pass / 1 fail
  local m="$1" props fail=0 line out=""
  props="$(props_of "$m")"
  [ -n "$props" ] || { printf '%-28s %s\n' "$m" "PROP_CMD returned nothing <-- FAIL"; return 1; }
  local IFS_SAVE=$IFS
  IFS=','
  for req in $REQUIRE; do
    IFS=$IFS_SAVE
    local key="${req%%=*}" want="${req#*=}" got
    got="$(printf '%s\n' "$props" | sed -n "s/^${key}=//p" | head -1)"
    if [ -z "$got" ]; then out="$out ${key}=MISSING"; fail=1
    elif matches "$got" "$want"; then out="$out ${key}=ok"
    else out="$out ${key}=FAIL($got)"; fail=1
    fi
    IFS=','
  done
  IFS=$IFS_SAVE
  printf '%-28s%s %s\n' "$m" "$out" "$([ $fail -eq 0 ] && echo PASS || echo '<-- FAIL')"
  return $fail
}

if [ "$SELF_TEST" = "1" ]; then
  # Negative control. Keep the real enumerator, swap in a member whose properties are guaranteed
  # to violate the first requirement, and demand a red. A drill you have to reconstruct by hand
  # is a drill you will not repeat, so it ships with the tool.
  first_req="${REQUIRE%%,*}"; key="${first_req%%=*}"
  DECOY_PROPS="${key}=__selftest_decoy_value__"
  echo "[self-test] requirement under test: $first_req"
  echo "[self-test] decoy properties:       $DECOY_PROPS"
  # Prove the decoy is actually what the checker will read. A negative control that never
  # installed produces exactly the same output as one that passed.
  if PROP_CMD='printf "%s\n" "$DECOY_PROPS"' DECOY_PROPS="$DECOY_PROPS" \
     bash -c 'eval "$PROP_CMD"' | grep -q '__selftest_decoy_value__'; then
    echo "[self-test] decoy installed and readable"
  else
    die "self-test decoy did not install — not proving anything"
  fi
  if PROP_CMD='printf "%s\n" "'"$DECOY_PROPS"'"' REQUIRE="$REQUIRE" MEMBER_CMD="$MEMBER_CMD" \
       "$0" "__selftest__" >/dev/null 2>&1; then
    echo "[self-test] FAIL — checker stayed green on a member that violates $first_req."
    echo "            The checker is dead. Do not trust its green."
    exit 1
  fi
  echo "[self-test] PASS — the checker goes red when the invariant is broken"
  exit 0
fi

if [ -n "$ONLY" ]; then audit_one "$ONLY"; exit $?; fi

rc=0; total=0; bad=0
while IFS= read -r m; do
  [ -n "$m" ] || continue
  total=$((total + 1))
  audit_one "$m" || { rc=1; bad=$((bad + 1)); }
done <<EOF
$(members)
EOF

# Order matters: die BEFORE printing a summary. `members=0 pass=0 fail=0` reads like a clean
# result to anything scraping the last lines, which is the exact shape this tool exists to refuse.
[ "$total" -gt 0 ] || die "enumerated ZERO members — that is a broken enumerator, not a clean fleet"
echo "---"
echo "members=$total pass=$((total - bad)) fail=$bad"
exit $rc
