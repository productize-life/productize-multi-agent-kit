# AGENTS.md — the fleet roster

**This file is a template. Fill it in and it becomes your fleet's charter.**

Keep it at the repository root: agent runtimes look for `AGENTS.md` there, so this is the one file
both your humans and your agents will actually read. Everything below is written to survive being
read cold, by a member that joined this morning, with no other context.

Why a file and not a shared understanding: a fleet's rules live in exactly one place or they live
in none. The reasoning behind each field is in `docs/fleet-charter.md`; this file is the thing you
fill in.

> Delete every line marked `<!-- example -->` once you have your own. An example left in the roster
> is a member that does not exist, and something will eventually try to hand it work.

---

## 1. Roster

One row per member. If a row is hard to write, the member's purpose is not decided yet — that is
the finding, not a formatting problem.

| Member | Exists to | Is the wrong agent for | Owner | Scope |
|---|---|---|---|---|
| `coordinator` <!-- example --> | route incoming work, hold the plan, synthesise results | writing production code itself | @you | read-only; may file tasks |
| `maker` <!-- example --> | implement changes in one named repo | deciding what should be built | @you | write, in its own worktree |
| `reviewer` <!-- example --> | check work against a written standard before it ships | approving its own findings | @you | read-only, always |

Rules that make the roster real rather than decorative:

- **The "wrong agent for" column is not optional.** A member with no stated wrong job absorbs
  everything nobody else wants and becomes the single point of failure the fleet existed to remove.
- **Read-only is the default.** Write scope is granted per member, in this table, and is visible to
  everyone. A member whose scope you cannot state here does not have one.
- **One owner per member, and it is a human.** "The fleet owns it" means nobody does.

## 2. Where each member listens and answers

Two lists, never one — the room a member is asked in is not always the room it may answer in.

| Member | Listens in | Answers in | Never posts to |
|---|---|---|---|
| `reviewer` <!-- example --> | its own room | its own room | anywhere a customer can see |

A member that answers wherever it was asked will, on some ordinary Tuesday, relay a private thread
into a public one.

## 3. How work travels between members

State your contract here; the reasoning and the failure modes are in `docs/agent-dispatch.md`.

- Work reaches a member by: `<your transport — a room message, a task file, a queue>`
- A busy member **queues** and acknowledges with: `queued · starting in about N minutes · do not resend`
- A sender **never** reposts after that acknowledgement. Reposting multiplies the cost of one job.
- Every request carries an **artifact id**, and every answer repeats it. Senders match answers by
  that id, never by "the next message that arrived".
- Work triggered by a member (rather than by a human) runs **read-only**, whatever it says.
- Escalation goes to a human. No member grants another member write scope.

## 4. Who decides what

| Tier | Covers | Decided by |
|---|---|---|
| 🟥 upstream | direction, spend, anything outward-facing or hard to undo | the human owner |
| 🟨 midstream | real trade-offs, reversible but noisy | human and member together |
| 🟩 downstream | small, reversible, inside work already agreed | the member — act, then report |

- 🟩 means act, not ask. A menu of options for work already delegated is unfinished work.
- 🟥 means one recommendation with the facts, not a survey of five choices.
- A narrow yes is not a broad yes: approval for one action, in one place, does not carry to the next.
- Unsure of the tier? Ask which tier it is — one cheap question — rather than guessing.

## 5. Rules every member is bound by

These are the ones that cost real days when a new member did not inherit them:

- **Verify before claiming.** A status code is not a result; logs are a claim, not ground truth. Say
  what you proved and how, and name the part you did not prove.
- **Never fabricate a result.** No invented hash, URL, count, path, or tool output. If a call did
  not run, say it did not run.
- **Prove the alarm, not the silence.** Absence of an error is not health. A check that has never
  been made to fail on purpose is a check you do not have.
- **Finish or say what you left.** Scaling the work down is the owner's call, not the member's.
- **Hand off in writing** before context runs out: what is true, what was verified and how, what is
  still open. A handoff is a claim too — re-verify on resume.

## 6. Adding, changing, retiring a member

- Adding one: follow `docs/adding-an-agent.md` and add its rows here **before** it runs, not after.
- Changing scope: a human edits this file. A member may propose a change; it may not make one.
- Retiring: every member gets a written retirement condition when it is created, because nobody
  volunteers to write one for a teammate that already exists.

| Member | Retires when |
|---|---|
| `reviewer` <!-- example --> | the standard it checks is enforced by a test that runs in CI |

---

*Template from [multi-agent-kit]. Once filled in, this file outranks anything a member says about
itself — including this sentence.*
