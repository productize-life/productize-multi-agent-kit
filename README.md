# multi-agent-kit

What changes when a second agent shows up.

One agent is a tool you drive. Several agents are a **system with a queue**, and almost everything
that breaks in that system breaks quietly: work that was accepted and never ran, an answer that
belongs to somebody else's question, a budget spent four times on the same job. None of it throws
an error. All of it looks like success.

This kit is the seam between agents: the contracts that keep dispatch honest, plus a reference
client that implements them.

## Who this is for

You already run one Claude Code agent (or any agent runtime) and it works. Now you want a second
one, or you want two people to be able to send work to the same one. Nothing here assumes a
particular framework — the contracts are transport-agnostic, and the example transport is a chat
room because that is what most people already have.

If you do not have agents yet, start with a pattern layer first. This kit picks up after that.

## What is in it

Six chapters covering the arc from "there is a second agent" to "the fleet runs unattended", plus
one runnable client. See `docs/README.md` for the full table and reading order.

| | |
|---|---|
| `docs/adding-an-agent.md` | onboarding one, end to end: purpose, charter, credentials, the scope defaults that are wrong out of the box, drills, and the retirement condition you can only write early |
| `docs/agent-dispatch.md` | how work reaches a busy agent and how the answer gets matched back to the right request |
| `docs/fleet-charter.md`, `skill-registry.md`, `working-agreement.md`, `fleet-health.md` | planned — charter enforcement, who-covers-what, decision tiers and briefs, and health you can trust |
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

## Boundary

Three layers, and only one of them is portable:

| Layer | Ships here |
|---|---|
| **contracts** — dispatch, scope, queueing, matching, retry etiquette | yes |
| **infra** — your hosts, daemons, schedulers, rooms, credentials | no, they are yours |
| **identity + memory** — who your agents are, what they have learned | no, and should not be |

Every warning in `docs/` is there because it cost real days of someone's work. The examples are
generalised; the scars are not.

## Credit

The practice this grew out of — running a fleet of agents as one team, tiered roles, dispatch
defining the role, the pre-action disciplines — belongs to **Nat** (P'Nat, laris-co). What is good
in the underlying approach starts with his work and teaching; the packaging of this particular
layer is ours.

MIT. Fork it, gut it, rename it.
