# The working agreement

The charter says who each member is. Dispatch says how work travels. This chapter is what happens
in between: how a piece of work is described so that someone who was not in the conversation can do
it, and what has to come back.

The runnable half is `../templates/brief.md`.

---

## 1. A brief has two sections, and the split is the point

Every instruction you give a member is one of two things, and merging them costs you both:

- **MUST** — refusable. The doer's work is judged against these and nothing else.
- **HINT** — advisory. Your best guess about approach, worth saying, wrong sometimes.

Why the separation earns its ceremony: a brief that is one undifferentiated wall of instructions
turns every suggestion into a requirement. The doer follows your hunch past the point where the
evidence contradicts it, because it was written in the same voice as the acceptance criteria — and
you lose exactly the thing you delegated for, which is a second pair of eyes.

The rule that makes it real: **a doer that satisfies every MUST has done the job**, even if it
ignored every HINT. A reviewer may not bounce work for departing from a HINT. What the doer owes in
exchange is one sentence: which hint it dropped, and on what evidence.

## 2. Runnable acceptance, or it is not acceptance

Any brief that says *prove*, *verify*, or *confirm* carries:

```
Acceptance: <command> → <expected output>
```

Adjectives get read the easiest-passing way. "Verified" means whatever check was cheapest to pass.
And the brief's author is the only person who knows what production actually calls — so the command
belongs in the brief, not in the doer's imagination.

Sign-off means: *you ran that command and saw that output.* Not a substitute check, not a
lower-level unit test that happened to be green, not the doer's summary of what it believes.

The same bar applies to your own claims when you report upward. A claim of "done" with no command
behind it is a claim, and it will be treated as one by anyone who has been burned.

If the claim is that a **check** works — an alarm, a gate, a test — acceptance must also include how
to make it go **red**. `0 failures` reads identically for "nothing is wrong" and "the check is
dead", and nothing distinguishes them except having watched it fail once on purpose.

## 3. The doer cannot see your conversation

A subagent starts cold. Anything load-bearing has to be *in* the brief — pasted, or at a path the
doer can actually open **from where it runs**. A path that resolves on your machine and not on the
member's host is worse than no context at all, because it looks like context and produces confident
work built on nothing.

Two failure modes worth naming, both common:

- **Frame as input, not as constraint.** Whatever you put in the brief becomes the doer's world. If
  you frame the task as "fix the caching bug", it will find a caching bug whether or not one exists.
  State the symptom and the evidence; let the diagnosis be the work.
- **Long context gets truncated in transit.** Chat transports cut messages; history windows have
  caps. A truncated instruction reads as a complete one. Send long material as an attachment or a
  path, never as several chat messages that you assume will be reassembled.

## 4. What must come back

Three things, and the second is the one that gets dropped:

1. **What was proved, and with what command.**
2. **What was not proved, named.** This is a deliverable, not an apology. A report that only lists
   successes forces the reader to guess the shape of the gap, and they will guess it smaller than it
   is.
3. **What was found outside the boundaries.** Report it; do not fix it. A doer that quietly widens
   its own scope is a doer whose next report you cannot size.

## 5. Disagreement between members

Two members will eventually produce contradictory answers. Rules that keep that useful:

- **A reviewer is not a gate.** It reports findings; it does not hold a veto and it does not approve
  its own findings. Gates are named in the charter and belong to a human or to a check that can be
  run.
- **A gate's authority is negative and bounded.** It may block within its stated jurisdiction, with a
  reason it can cite, and there must be an escalation path for anything outside that. A gate that
  invents new norms through its verdicts has stopped being a gate.
- **Reconcile numbers before arguing about them.** When two members report different counts, the
  useful question is not "who is right" but "what is each one counting?" — the difference is almost
  always a denominator, and finding it is faster than re-running either side.

## 6. Handoffs

Written before context runs out, not after. A handoff records **state and proof**: what is true,
what was verified and how, what is still open and why. Not a narrative of the session and not a
TODO list.

- Commit it immediately. An uncommitted handoff does not exist.
- On resume, **re-verify anything it calls done.** A handoff is a claim like any other, and the
  world moved while nobody was reading.
- Wrapping up twice in one day: append a delta to the existing handoff, do not write a second file.
  Five documents each claiming to be current state is worse than one that grew.

---

## The short version

- MUST is refusable, HINT is advice, and the doer says which hints it dropped.
- Acceptance is a command and its expected output — including how to make a checker go red.
- Put the context in the brief; a path the doer cannot open is not context.
- Report the unproven part; it is the deliverable.
- A reviewer reports, a gate blocks within a stated jurisdiction, and a human decides.
