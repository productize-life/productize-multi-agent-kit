# multi-agent-kit

What changes when a second agent shows up.

One agent is a tool you drive. Several agents are a **system with a queue**, and almost everything
that breaks in that system breaks quietly: work that was accepted and never ran, an answer that
belongs to somebody else's question, a budget spent four times on the same job. None of it throws
an error. All of it looks like success.

This kit is the seam between agents: the contracts that keep dispatch honest, plus a reference
client that implements them.

**It is a bridge, not a destination.** If you control the transport and a real queue is available to
you, use the queue: leases, acks and dead-letters are better solved there than in prose two agents
agree to honour. This kit is for the very common case where the transport is a chat product you do
not own, and the guarantee has to live in the contract instead.

## If you only do one thing

Give every request an id, make the agent echo it back, and accept an answer only if it carries
your id. That single rule removes the failure that costs the most: reading somebody else's answer
as your own. Everything else here is what you need once the second sender, the retry, and the
unattended night arrive.

## Threat model — read before trusting the id

**This assumes a room where every participant is trusted.** The correlation id is a *routing token,
not an authenticator*: `scripts/dispatch-client.sh` mints `job-<timestamp>-<pid>` and accepts any
message containing that string. It is guessable, and matching is by substring. That is a deliberate
trade — it makes the contract implementable over any transport — and it is only safe while everyone
who can post in the room is somebody you would let run the job.

Two consequences that follow directly, and are load-bearing:

- **Never auto-resend on timeout.** A resend path plus a guessable id is a forgery window: the
  duplicate is indistinguishable from the original, and whoever answers first wins. The client
  deliberately exits non-zero and tells a human to go read the room (`exit 2`) instead.
- **"Write scope belongs to work a human triggered" is unenforceable without this boundary.** If
  attacker-controlled content can reach an agent that can post, the id proves nothing and the write
  rule is a wish. Decide which world you are in and write it down; the contracts below assume the
  trusted one.

## Who this is for

You already run one Claude Code agent (or any agent runtime) and it works. Now you want a second
one, or you want two people to be able to send work to the same one. Nothing here assumes a
particular framework — the contracts are transport-agnostic, and the example transport is a chat
room because that is what most people already have.

If you do not have agents running yet, start with the patterns for building them — the
[field guide](https://github.com/Soul-Brews-Studio/multi-agent-orchestration-book) below covers
that ground. This kit picks up after you have something running.

## What is in it

Six chapters covering the arc from "there is a second agent" to "the fleet runs unattended", plus
one runnable client. See `docs/README.md` for the full table and reading order.

| | |
|---|---|
| `AGENTS.md` | **the template you fill in** — the roster, each member's lane and boundaries, rooms in and out, how work travels, who decides what, and the retirement condition. Lives at the root because that is where agent runtimes look |
| `docs/fleet-charter.md` | why each field in that template exists, what must never go in it, and the three checks that make a charter binding instead of decorative |
| `docs/adding-an-agent.md` | onboarding one, end to end: purpose, credentials, the scope defaults that are wrong out of the box, drills, and the retirement condition you can only write early |
| `docs/agent-dispatch.md` | how work reaches a busy agent and how the answer gets matched back to the right request |
| `docs/working-agreement.md` + `templates/brief.md` | describing work for someone who was not in the conversation: MUST vs HINT (what the doer may be failed for, versus advice it may discard), runnable acceptance, and what must come back |
| `docs/skill-registry.md` + `scripts/registry-lint.sh` | answering "who covers this?" from a file that outranks self-report — and proving every capability it claims can still be loaded |
| `docs/fleet-health.md` + `scripts/roster-reconcile.sh` + `scripts/member-invariant-audit.sh` | health you can trust: enumerate from the system, reconcile both presence *and* per-member properties, and make every check go red once on purpose before trusting its green |
| `scripts/dispatch-client.sh` | a reference sender: matches the answer to the request by id, honours a queue acknowledgement instead of reposting, and fails loudly rather than accepting the wrong answer |

This is not a framework and there is no runtime to install — the agent side of all of it is short
code in whatever you already run, and the short code is not the hard part.

## The one-paragraph version

An agent that is already busy can drop your request, run it anyway, or queue it. Only the third is
a system, and it only works if the acknowledgement says *queued, starting in about N minutes, do
not resend* in words a script can parse. Write scope belongs to work a human triggered, never to
work another agent relayed. And when the answer comes back, match it to your request by an id you
put in the artifact — never by "the next message after mine", because on a busy day that message
is someone else's verdict about someone else's file, and it will read exactly like yours.

None of that is new as theory. The id is a **correlation id**, "do not resend" is asking the queue
for an **idempotency key** instead of a retry, and "starting in about N minutes" is a **lease** with
a visibility timeout stated in words. Message brokers solved all three decades ago. The reason this
kit exists is that your transport is a chat room and there is no broker in it, so the guarantees
have to live in the etiquette between the two ends.

## Boundary

Three layers, and only one of them is portable:

| Layer | Ships here |
|---|---|
| **contracts** — dispatch, scope, queueing, matching, retry etiquette | yes |
| **infra** — your hosts, daemons, schedulers, rooms, credentials | no, they are yours |
| **identity + memory** — who your agents are, what they have learned | no, and should not be |

Every warning in `docs/` is there because it cost real days of someone's work. The examples are
generalised; the scars are not.

## Where this sits, and what it is not

This kit is the **contract** layer. Two other layers already exist in public and this one does not
replace either:

| | |
|---|---|
| **Tooling** — [`maw-js`](https://github.com/Soul-Brews-Studio/maw-js) and its Rust successor [`maw-rs`](https://github.com/Soul-Brews-Studio/maw-rs) | drives many agents across tmux panes, git worktrees, and machines: wake one, talk to it, watch it, track cost. If you need the mechanism rather than the agreement, start there. |
| **Field guide** — [multi-agent-orchestration-book](https://github.com/Soul-Brews-Studio/multi-agent-orchestration-book) | patterns from subagents through federation, written while building the tooling above. Broader and earlier than this kit. |
| **This kit** | the agreements that hold once several agents are running: who may trigger write scope, what a busy agent owes a sender, how an answer is matched to its request. Transport-agnostic and tool-agnostic on purpose. |

Two implementation traps worth knowing before you pick tooling, because both cost real time:

- **Two implementations exist** (`maw-js`, `maw-rs`) and they move independently. Pin the one you
  installed, and check which one a given instruction was written for before following it.
- **A green test suite is not a working client.** A rewrite can pass every check it ships with and
  still fail the caller that matters, because the caller exercises a path the suite does not. Run
  the real client against the new version once before switching anything that runs unattended.

## One incident, concretely

If you have not been burned yet, the warnings above read as reasonable advice rather than rules.
Here is the shape of the day that turns one into the other.

A sender posts a file for review and waits for the verdict. The reviewer is busy, so it replies
with a short acknowledgement, then goes quiet. Twelve minutes later a long, detailed verdict
appears in the room. The sender takes it, applies the fixes, and ships.

The verdict was about a different file. A second sender had queued work a minute earlier, and the
reviewer answered that one first. Both messages are long, both are in the same room, both begin the
same way. Nothing errored. The sender's own tooling reported success, because its rule was *the
next long message after mine*.

The fix is two lines of etiquette, and they are the whole kit in miniature: put an id in the
artifact and require the verdict to carry it back, and treat an acknowledgement as a queue position
rather than a result. What made the incident expensive was not the missing id, it was that the
failure looked exactly like success from the inside.

## Known gap

`AGENTS.md` is the file everything else points at, and it is the least defended thing here. Two
chapters ship a checker that re-derives reality from the running system (`registry-lint.sh`,
`roster-reconcile.sh`, `member-invariant-audit.sh`); the roster in `AGENTS.md` has no equivalent. It is hand-maintained prose,
and when it drifts out of step with the agents actually running, nothing in this kit will notice.
Treat it as a file to re-read on a schedule until someone writes that check.

## Credit

The practice this grew out of — running a fleet of agents as one team, tiered roles, dispatch
defining the role, the pre-action disciplines — belongs to **Nat** (P'Nat, laris-co). What is good
in the underlying approach starts with his work and teaching; the packaging of this particular
layer is ours.

MIT. Fork it, gut it, rename it.
