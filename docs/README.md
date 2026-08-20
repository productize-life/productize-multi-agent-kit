# docs/ — running several agents as one team

Six chapters, in the order the problems actually arrive. Each one ships with the runnable piece it needs.

The first agent is a tool. The second one turns it into an organisation, and an organisation needs
three things a single agent never did: a written statement of who each member is and what they may
do, an agreed way for work to travel between them, and a way to answer "who covers this?" without
asking every member to self-report.

Throughout these chapters, **the fleet** means the set of agents you have added — the roster in
`../AGENTS.md` plus whatever is actually running.

Every shell block in these chapters is written to run **from the repository root**, which is why
they say `./scripts/…` while the surrounding prose points at `../scripts/…` (relative to this
`docs/` directory). Copy the block, not the sentence.

| Chapter | Read it when | State |
|---|---|---|
| `fleet-charter.md` | before the second agent exists — what a charter declares, what it must never contain, and how it gets enforced at runtime instead of admired in a file. Fill in `../AGENTS.md` as you read it | **written** |
| `adding-an-agent.md` | every time you add one — the onboarding path end to end, the settings that silently default wrong, and the drills that prove the new member is real | **written** |
| `agent-dispatch.md` | the day a request arrives while an agent is busy — queueing instead of dropping, who may trigger write scope (permission to change files, not merely read them), and why an answer must be matched to its request by id and never by time | **written** |
| `skill-registry.md` | when nobody can say which agent or skill covers which job — a registry that outranks self-claims, plus `../scripts/registry-lint.sh` to keep it from rotting | **written** |
| `working-agreement.md` | when work has to be described for someone who was not in the conversation — MUST vs HINT (MUST is binding, HINT is advice you may drop with a reason), runnable acceptance (a command plus the output you expect back, not a description of success), and what must come back. Template: `../templates/brief.md` | **written** |
| `fleet-health.md` | once the fleet runs unattended — enumerate members from the system, reconcile both directions with `../scripts/roster-reconcile.sh`, reconcile per-member properties with `../scripts/member-invariant-audit.sh`, and alarms that prove delivery instead of assuming silence | **written** |

## Why prose and not a framework

Everything portable here is a **contract**. The code that enforces it is short and belongs to your
runtime; the contract is the part that takes months to learn, because every one of these failures
looks like success from the outside: work accepted and never run, an answer to somebody else's
question, an agent that has been "busy" for fourteen minutes with nothing running, a registry that
lists a skill nobody has been able to load since April.

Three pieces are runnable, because prose converts to a correct implementation poorly and each of
these is somewhere the failure is silent:

| Piece | Proves |
|---|---|
| `../scripts/dispatch-client.sh` | the sender side: matches an answer to its request by id, waits instead of reposting |
| `../scripts/roster-reconcile.sh` | running members and the roster agree, in both directions. `--self-test` makes it go red |
| `../scripts/member-invariant-audit.sh` | every running member still carries the properties every member must have — the drift roster-reconcile is blind to. `--self-test` proves it can go red |
| `../scripts/registry-lint.sh` | every capability the registry claims can actually be loaded here. `--self-test` plants a decoy and catches it |

Two of them need a file you fill in first, and the kit ships both starting points:
`../templates/brief.md` for a dispatch, `../templates/REGISTRY.md` for the registry the linter
checks. A chapter whose runnable half has no file to run against is prose with a shell block in it.

The two `--self-test` flags are not decoration. A check nobody has watched fail is an assumption
wearing a checkmark.

## Suggested order

1. `fleet-charter.md` — write one before you need it. Retrofitting a charter onto three agents that
   already have habits is a much worse afternoon.
2. `adding-an-agent.md` — use it as a checklist the first time, then keep it as the retirement path:
   the same drill run backwards tells you which member no longer earns its place, so look here when
   you want an agent *out*, not only when you want one in.
3. `agent-dispatch.md` — the day the second sender appears, whether that is a second person or a
   scheduled job.
4. `working-agreement.md` before you delegate anything you cannot check by eye — MUST vs HINT and
   runnable acceptance are what make delegated work verifiable.
5. `skill-registry.md` and `fleet-health.md` once the fleet runs without you watching. Both ship a
   checker; run each one's `--self-test` before trusting its green.
