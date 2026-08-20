# Health you can trust

A fleet — the set of agents you have added, the roster in `../AGENTS.md` plus whatever is actually
running — fails in one direction once it runs unattended: **quietly**. Not with an outage, but with
a member that stopped answering, a checker that stopped checking, and a dashboard that keeps showing
the same reassuring shape it showed last week.

Everything in this chapter answers one question about every check you own:

> **If this check died, how would its output differ?**

If the answer is "it wouldn't", the check is already dead and nobody has noticed. That is not a
hypothetical — it is the single most common failure in an agent fleet, because most checks report
"nothing wrong" and *broken* and *nothing wrong* are the same string.

The parts of this chapter you can actually run are `../scripts/roster-reconcile.sh` (is the right
*set* of members running?) and `../scripts/member-invariant-audit.sh` (do the members that are
running still carry what every member must have?). The rest is the reasoning that decides what such
a script should refuse to call healthy.

---

## 1. Enumerate members from the system, never from a list you maintain

The first dashboard loops over an array of member names, because at three members you know them
all. Then the fleet grows to nine and the array still has six.

It looks fine. Six green checkmarks is what a healthy fleet looked like when there were six
members, so the display keeps its reassuring shape while three members are invisible — including
whichever one dies.

**Ask whatever actually owns the set**: the process supervisor, the container runtime, the session
manager, the orchestrator. Keep a hardcoded list only as the *emergency* fallback, and make it
announce itself when it is used. An empty enumeration must read as **broken**, never as an empty
fleet — because "no members found" and "no members configured" produce identical output and only
one of them is fine.

## 2. Reconcile in both directions

The comparison people write is roster → reality: is everything in the file still running? That
catches a death.

The direction that gets skipped is reality → roster: **is something running that the file has never
heard of?** That is the expensive one — an unlisted member, holding valid credentials, answering in
a room somebody still watches, owned by nobody, remembered by no one.

```bash
ROSTER_CMD='<prints one running member per line>' ./scripts/roster-reconcile.sh AGENTS.md
```

The script fails closed: an empty roster command exits non-zero rather than reporting "0
mismatches", and `--self-test` proves both arms can go red before you rely on either.

## 3. Reconcile properties, not just presence

Both arms of §2 can be green while the fleet is quietly unprotected, because presence is not the
only thing that drifts. The other drift is *per-member*, and it arrives through the door nobody
watches: **the thing that creates new members.**

The pattern repeats exactly, in every fleet, on a schedule set by how often you add members:

1. Something breaks. You write a rule — a restart policy, a death alarm, a required setting.
2. You apply it, by hand, to the members that exist that day. This is correct and it works.
3. You do not touch the generator — the scaffold script, the template, the container image — because
   the generator was not what broke.
4. Every member created after that day is born without the rule.

Twelve days after one such rule was written, a fleet of fourteen was measured: **five members had no
death alarm at all**, and **eight were on a restart policy that does not restart a clean exit** — so
a member that exited with status `0` stayed dead, and the alarm stayed silent on purpose, because
the stop was "successful". Roster reconciliation was green the whole time. Nothing was missing.
Nothing was a ghost. Nobody had done anything wrong since the day the rule was written.

The reason this specific drift survives so long deserves naming, because it is not bad luck:

> **A missing alarm hides its own absence.** The only signal it would have produced is a member
> dying quietly — which is the thing it was there to report.

So the durable fix is never "add it to the five". It is a **pair**:

- the **generator** emits the property, so member N+1 is born correct;
- an **audit** walks the whole roster and fails loudly, so the claim has a denominator.

```bash
MEMBER_CMD='<prints one running member per line>' \
PROP_CMD='<prints key=value lines for the member named in $1>' \
REQUIRE='Restart=always,OnFailure=*,ExecStopPost=*crash-alert*' \
  ./scripts/member-invariant-audit.sh
```

Wire the same audit into the generator as its last step, so a member whose unit misses an invariant
is not reported as a successfully created member. A gate at the end of creation is worth more than
the same rule written in a comment above it: prose decays into "I hope somebody remembers", and the
whole failure above is what that decay looks like from the outside.

Two questions to ask of every rule you add. If you cannot answer both, the rule will rot as the
fleet grows, and there will be no day on which it looks wrong:

- **"Will the N+1th member have this?"**
- **"Who counts, right now, how many members do not?"**

And one more, for the moment you finish any fix: **"which sibling is the same kind?"** The five
missing alarms and the restart-policy drift were found on the same day as a third instance — a
notifier that swallowed its own delivery result, in a script whose sibling had been fixed for
exactly that, twelve days earlier, with a comment explaining why. The fix had been applied to the
file where the bug was found, not to the *kind* of bug. That is the same mistake as step 2 above,
one level up.

## 4. Staleness is a first-class alarm

Any file a checker writes carries two signals, and only one of them is usually read:

- its **content** — "OK: everything fine"
- its **age** — when that sentence was last true

Reading only the content is how a checker hides its own death. The checker stops running; the file
keeps its last cheerful line; the dashboard keeps printing it. Ten days can pass.

Threshold rule: alarm at a few missed cycles, not one. If the check runs every 5 minutes, treat a
file older than ~20 minutes as red. And phrase the alarm as what you **observed**, not what you
diagnosed — "data stale 42m" is true whether the checker died, the disk filled, or the notifier
failed. Naming the wrong cause sends people to the wrong place.

## 5. An alarm must prove delivery, not assume it

Silence has two meanings and they are opposite: nothing is wrong, or the path that would tell you
is broken. Distinguish them by **sending something on purpose**.

- Heartbeat the pipe itself: a scheduled message that says "the alarm path works", so its absence
  is itself an alarm.
- Record the transport's acknowledgement, not just your call to it. "Posted" is a claim; the
  message id it returned is evidence.
- Alarm on a **failed notification** the same way you alarm on a failed job. A notifier that swallows
  its own error is a fleet running blind and reporting green.

## 6. Make every check fail on purpose, once

A check that has never gone red is an assumption wearing a checkmark. Before you trust one:

- **Plant a decoy** the check must catch — a bogus entry, a wrong value, a file that should not
  parse — and confirm the red.
- **Prove the decoy landed.** A decoy that was never installed produces exactly the same output as
  a decoy that passed. Count what you planted before you read the result.
- **Keep the drill runnable.** Every audit script in this kit ships a `--self-test` for this
  reason: a drill you have to reconstruct by hand is a drill you will not repeat.

Two traps that make green meaningless, both worth checking by hand:

- **A syntax check is not a runtime check.** A script can parse cleanly and still never evaluate the
  branch you care about.
- **A check can be right for a reason that stopped being true.** Assert the *reason*, not just the
  value: pin what makes the answer correct, so a coincidence cannot keep the light green after the
  mechanism moves.

## 7. What the numbers must be able to tell you

During an incident there is exactly one question: **is work waiting, or was it lost?** Design the
output so it answers that without interpretation. Each member logs its own state, shown here as a
worker draining a queue:

```
worker finished in 130s (active 1, queued 2)
DEFERRED cooldown ~9m (2 pending)
deferred → running <id> (attempt 1, reason=cooldown)
```

`DEFERRED` means the request was accepted and parked, not refused; `cooldown` is the reason it is
parked and roughly how long is left. The third line is the same request starting for real, which is
what makes the pair readable as "waiting" rather than "lost".

Counts, and the *reason* for each state. Without them, "no errors in the log" covers both a healthy
idle fleet and one that has been dropping every request for an hour.

Round numbers deserve suspicion, not celebration: `0 dropped`, `all OK`, `100%` are the shapes a
broken instrument makes as readily as a healthy system. When a metric comes back perfectly clean,
spend one round doubting the instrument before you believe the world.

---

## The short version

- Enumerate members from the system; an empty answer is broken, not empty.
- Reconcile both directions — the ghost member is the expensive one.
- Reconcile *properties* too: presence can be perfect while half the roster is missing the rule you
  added last month, because the generator that mints members never learned it.
- Every rule you add needs a generator that emits it and an audit that counts who lacks it.
- Read a status file's age before its content.
- Prove the alarm path with traffic you sent on purpose.
- Make every check go red once, and prove the decoy was installed before believing the result.
