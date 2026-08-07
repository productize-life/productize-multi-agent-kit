#!/usr/bin/env bash
# dispatch-client.sh — send a file to an agent for review, and get back the answer to YOUR request.
#
# WHY THIS EXISTS AS A SCRIPT: the agent side of multi-agent dispatch is easy. The sender side is
# where the silent failures live, and every one of them is a branch in this file:
#
#   1. the answer is matched to the request by an ARTIFACT ID, never by "the next message"
#      (§6 of docs/agent-dispatch.md — a time-matched client reports another job's verdict as
#       yours, with a straight face, and you cannot tell by reading it)
#   2. a "queued, do not resend" acknowledgement makes it WAIT, not repost
#      (§5 — a reposting client multiplies the cost of the same job by however many times it tried)
#   3. no answer is a NON-ZERO exit, never a zero with an empty result
#      (waiting is cheap; believing the wrong answer is not)
#
# TRANSPORT: the two functions at the top are the only Discord-specific parts. Swap them for your
# own transport (Slack, a queue, a REST endpoint, a shared directory) and the rest holds.
#
# USAGE
#   DISPATCH_TOKEN=...  DISPATCH_ROOM=...  ./dispatch-client.sh <file> "<what to do with it>"
#
# EXIT CODES
#   0  a verdict carrying our artifact id came back (printed to stdout)
#   1  could not dispatch at all
#   2  timed out without OUR verdict — go look in the room yourself, do not assume anything

set -uo pipefail

FILE="${1:?usage: dispatch-client.sh <file> [instruction]}"
INSTRUCTION="${2:-review this and reply with pass or a list of fixes}"
[ -f "$FILE" ] || { echo "no such file: $FILE" >&2; exit 1; }

: "${DISPATCH_TOKEN:?set DISPATCH_TOKEN (bot token for the room)}"
: "${DISPATCH_ROOM:?set DISPATCH_ROOM (room/channel id the agent listens in)}"

# How the agent gets at the file. Two honest options, pick one for your setup:
#   • a shared path both sides can read (what this script assumes: AGENT_INBOX)
#   • an upload step here, and a URL in the message
# Sending long text inline is the option that looks easiest and is not: chat transports truncate
# history, and a truncated instruction reads as a complete one.
AGENT_INBOX="${AGENT_INBOX:-./agent-inbox}"

POLL_SECONDS="${POLL_SECONDS:-30}"
MAX_POLLS="${MAX_POLLS:-60}"

API="https://discord.com/api/v10"
UA="DispatchClient (multi-agent-kit, 1.0)"   # a default UA gets 403'd by the CDN in front of many APIs

# ---- transport: replace these two for a different backend --------------------------------------
post_message() {   # stdin = message body; prints the created message id
  python3 - "$DISPATCH_ROOM" <<'PY'
import json, os, sys, urllib.request
body = sys.stdin.read()
req = urllib.request.Request(
    f"{os.environ['API']}/channels/{sys.argv[1]}/messages",
    data=json.dumps({"content": body}).encode(),
    headers={"Authorization": "Bot " + os.environ["DISPATCH_TOKEN"],
             "Content-Type": "application/json",
             "User-Agent": os.environ["UA"]})
print(json.load(urllib.request.urlopen(req)).get("id", ""))
PY
}

fetch_since() {   # $1 = message id; prints the raw message list, newest first
  curl -s -H "Authorization: Bot $DISPATCH_TOKEN" -H "User-Agent: $UA" \
    "$API/channels/$DISPATCH_ROOM/messages?after=$1&limit=50"
}
export API UA DISPATCH_TOKEN
# ------------------------------------------------------------------------------------------------

# The artifact id is the whole trick. It must be unique per dispatch and it must appear BOTH in the
# instruction (so the agent echoes it) and in the answer we accept.
ARTIFACT_ID="job-$(date +%Y%m%d-%H%M%S)-$$"
DEST="$AGENT_INBOX/$ARTIFACT_ID.md"
mkdir -p "$AGENT_INBOX" || { echo "cannot create $AGENT_INBOX" >&2; exit 1; }
cp "$FILE" "$DEST" || { echo "cannot place artifact at $DEST" >&2; exit 1; }
echo "artifact → $DEST" >&2

read -r -d '' MSG <<EOF || true
$INSTRUCTION

file: $DEST
Start your reply with this id so I know the answer is mine: $ARTIFACT_ID
EOF

POST_ID=$(printf '%s' "$MSG" | post_message)
[ -n "$POST_ID" ] || { echo "dispatch failed (no message id back)" >&2; exit 1; }
echo "dispatched $ARTIFACT_ID (message $POST_ID) — waiting" >&2

# Classify one poll's worth of messages. Prints one of:
#   MINE / <the verdict text>   ← carries our artifact id
#   OTHER <id>                  ← someone else's answer; keep waiting, do NOT take it
#   QUEUED <minutes>            ← accepted into a queue; wait, do NOT repost
#   NOTHING
classify() {
  ARTIFACT_ID="$ARTIFACT_ID" python3 - <<'PY'
import json, os, re, sys
try:
    msgs = json.load(sys.stdin)
except Exception:
    msgs = []
if not isinstance(msgs, list):
    msgs = []
mine = os.environ["ARTIFACT_ID"]
queued = None
other = None
for m in reversed(msgs):                      # oldest first
    c = m.get("content") or ""
    if mine in c and len(c) > 120:            # our id + substantial body = our verdict
        print("MINE"); print(c); sys.exit()
    # An acknowledgement that promises to run it later. Match on MEANING the agent committed to,
    # and keep this wording stable on both sides — it is a wire format, not prose.
    if re.search(r"queued|do not (send|post) again|ไม่ต้องส่งซ้ำ", c, re.I):
        mm = re.search(r"(\d+)\s*(?:min|นาที)", c)
        queued = mm.group(1) if mm else "?"
        continue
    hit = re.search(r"\bjob-\d{8}-\d{6}-\d+\b", c)
    if hit and hit.group(0) != mine:
        other = hit.group(0)
print(f"OTHER {other}" if other else (f"QUEUED {queued}" if queued else "NOTHING"))
PY
}

for i in $(seq 1 "$MAX_POLLS"); do
  sleep "$POLL_SECONDS"
  STATE=$(fetch_since "$POST_ID" | classify)
  case "$(head -1 <<<"$STATE")" in
    MINE)
      tail -n +2 <<<"$STATE"
      exit 0 ;;
    OTHER*)
      # Someone else's answer arrived first. This is the exact moment a time-matching client
      # reports the wrong verdict as yours. Say so out loud and keep waiting.
      echo "skipping an answer for $(awk '{print $2}' <<<"$STATE") — not ours, still waiting ($i)" >&2 ;;
    QUEUED*)
      echo "queued (about $(awk '{print $2}' <<<"$STATE") min) — waiting, not resending ($i)" >&2 ;;
    *)
      [ $((i % 4)) -eq 0 ] && echo "…still waiting (${i}×${POLL_SECONDS}s)" >&2 ;;
  esac
done

echo "no verdict carrying $ARTIFACT_ID after $((MAX_POLLS * POLL_SECONDS))s." >&2
echo "Go read the room before assuming anything: an answer may exist that is not yours." >&2
exit 2
