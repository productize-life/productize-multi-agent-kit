# Brief — <one line: what changes in the world>

<!-- Copy this file per dispatch. Two sections, and the split is the whole point:
     MUST is binding — you may refuse the finished work if one is unmet. HINT is advice.
     A doer that satisfies every MUST has done the job, even if it ignored every HINT — and a
     reviewer may not bounce it for that. See docs/working-agreement.md -->

## MUST

**Acceptance:** `<the exact command someone will run>` → `<the exact output that means done>`

<!-- Adjectives get read the easiest-passing way. "Verified", "works", "secure", "done" are not
     acceptance criteria; a command and its expected output are. The brief's author is the only
     person who knows what production actually calls — name it here, not in the doer's imagination. -->

**Boundaries**

- may touch: `<paths / repos / rooms>`
- may not touch: `<everything outside, named explicitly>`
- autonomy: `act-then-report` | `ask first` | `never without a human`
- stop and escalate when: `<the condition, written now, before anyone is chasing>`

**Done when**

- [ ] the acceptance command above was run, by you, and printed the expected output
- [ ] `<any second observable outcome>`

## HINT

<!-- Everything you would suggest but would not fail the work over: an approach you would try
     first, a file you think is relevant, a prior solution. Advisory on purpose.
     The doer may discard any of it — and must say which HINT it dropped and on what evidence.
     That sentence is how a wrong hint gets corrected instead of quietly obeyed. -->

- <approach you would try first, and why>
- <where you would look>
- <what you suspect, flagged as a suspicion>

## Context the doer cannot see

<!-- A subagent does not have your conversation. Anything load-bearing must be IN the brief:
     paste it, or give a path that the doer can actually read from where it runs.
     A path the doer cannot open is worse than no context, because it looks like context. -->

- <facts, decisions already made, links to artefacts>

---

## Reporting back

- what was proved, and the command that proved it
- what was **not** proved, named explicitly — this part is the deliverable, not an apology
- any HINT dropped, and the evidence that justified dropping it
- anything found that was outside the boundaries: report it, do not fix it
