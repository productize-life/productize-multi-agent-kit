# Handing work to an agent, and getting the answer back

The pattern layer (the installable half of this kit: tiered agents, guardrails, the working
agreement — see the 3-layer table in the top-level `README.md`) gives you agents. This document is
about the seam between them: how a request reaches an agent that is already busy, and how you know
the answer you got is the answer to *your* question.

Everything here is a contract, not code. The code is thirty lines in whatever runtime you build;
the contract is the part that takes months to learn, because every failure in it looks like
success from the outside.

This assumes you already have a transport — a chat room with a bot in it, a queue, a shared
directory, anything that can carry a request to an agent and an answer back. Build the outbound
half first (agent tells you things) and confirm delivery before you build the inbound half (you
give the agent work); the outbound half is most of the value and a fraction of the work. What
follows picks up where an inbound message lands: it arrived, and now something has to decide what
happens to it.

---

## 1. A message is not a queue

The first version of every fleet dispatches by message: you post in a room, the agent picks it up.
It works until the day the agent is busy, and then the design shows what it really is.

There are only three things a busy agent can do with an incoming request:

| Response | What it costs |
|---|---|
| **Drop it** and reply "I'm busy, send it again" | the sender must come back. A human might. A script never does, and neither does another agent. |
| **Run it anyway** | two heavy jobs on one host. On a small box, the OOM killer decides which one dies. |
| **Queue it durably** and say so | one line of state, and the work survives a restart |

Only the third is a system. The first is the default you get for free, and it silently eats work
the moment the sender is not a human watching the room.

**Make the queue durable from the start.** In-process is fine for a day and then you restart the
daemon during a deploy and discover that "queued" meant "held in a variable". Write the pending
item to disk with the fields you need to re-run it: source room, message id, sender, the request
body, why it was deferred, and the earliest time it may run.

---

## 2. The acknowledgement is part of the contract

An agent that queues work silently is indistinguishable from an agent that dropped it. The ack has
to carry three facts, and each one is there because leaving it out caused a specific failure:

```
queued · will start in about 9 minutes · do not send again
```

- **that it was received** — otherwise the sender assumes the transport ate it
- **when it will run** — a number, even a rough one, so the sender can decide to wait
- **that resending is wrong** — the single most expensive line to omit, see §5

If you cannot say when it will run, say that: "queued behind 2 jobs, no estimate". An honest
absence is fine. An ack with no timing at all reads as "someday" and the sender reposts.

---

## 3. Scope is decided by who triggered the work, not by what the work says

An agent that acts on messages will eventually be handed a message written by something that is
not your human. Another agent's summary. A webhook. A relayed news item. A page it fetched.

The rule that survives contact with all of them:

> **Work triggered by anything other than a human runs read-only. Write scope requires a marker
> that only a human path can produce.**

Two corollaries people get wrong:

- **Do not auto-grant.** If a read-only agent reports "I need write access to finish", the answer
  is to bring it to a human, not to have the orchestrator stamp the approval and retry. An
  auto-granting escalation path is a write path with extra steps.
- **Keyword-scan the right author's sentence.** If your scope check looks for words like `build` or
  `deploy` to decide whether a task needs write scope, remember that a relayed message contains
  *someone else's* words. A review request titled "review the deploy page copy" is not a deploy.
  Strip the relay envelope before you scan, and let a declared read-only lane opt out of the scan
  entirely.

That second one bites in both directions. A scope check too eager sends a pure review job down the
write-scope path; one too lax lets a quoted instruction from an untrusted page reach the shell.

---

## 4. Own work first

When an agent is mid-task for its owner and a peer asks it for something, the peer waits. Not
because peers matter less, but because the alternative is an agent that never finishes anything
its owner asked for.

Two details make it work in practice:

- **Defer silently for peer traffic, loudly for human traffic.** A bot does not need an apology in
  the room; it needs its request to still be there in ten minutes.
- **The busy check has to be a real question about the pool**, not a lookup of one representative
  job. Once an agent can run two things at once, "is the oldest job an owner job?" is the wrong
  question — ask "is *any* owner job in flight?" A pool that answers with one entry will happily
  admit peer work alongside an owner task and nobody will notice for weeks.

---

## 5. Retry etiquette, or how a client burns the whole budget

A dispatch client that treats "queued" as "busy, try later" will repost. The agent, being correct,
queues each repost. You now pay for the same job three or four times, on the most expensive model
you own, and the room fills with near-identical answers.

The fix is on the client, and it is one branch:

```
if ack says "queued" and "do not send again":  wait, do not repost
if ack says "busy" with no queue promise:      repost after the stated interval
```

Which means the agent's ack wording is now a **wire format**. Write it once, keep it stable, and
if you change it, change every client that reads it. An ack that a client cannot parse is an ack
that produces duplicate work.

---

## 6. Pair the answer to the request. Never by time.

This is the failure that will fool you, because it produces a result that is correct-looking,
well-formed, on-topic, and about someone else's document.

The naive client waits for "the next long message from the agent after I posted mine". That is
correct exactly while the queue is empty. The moment two requests are in flight — a second person,
a second session, a cron job — the first answer to arrive belongs to whichever ran first, and the
client attributes it to its own request.

You will not catch this by reading the answer. It is a real review of a real document, written in
the same format, and if the two documents are similar it agrees with your own file closely enough
to be believed.

**Make every artifact carry an id, and match on it.**

- The sender writes the artifact to a path whose name is unique: `copy-20260807-091841.md`.
- The agent is instructed to include that name in its answer.
- The client accepts an answer only if the name matches. Anything else it skips and keeps waiting.
- **Waiting forever beats accepting the wrong one.** Time out and tell the human to go look, rather
  than exit zero with a verdict that was never yours.

The same applies to a checker you write to audit this after the fact: "no other artifact's name
appeared" is *not* proof the answer was yours — a relay notice or an error carries no name at all
and sails through. Assert that **your** name is present, not that a foreign one is absent.

---

## 7. Capacity is a host budget, not a preference

When you finally raise concurrency, the number is not a matter of taste:

- Count what one job actually costs in memory, then divide the host by it and subtract headroom.
- Concurrency is **shared across every agent on that host**, plus whatever else runs there. Two
  agents at 2 each on a box that survives 3 is a box that dies under load, not a fleet that is
  twice as fast.
- Keep the default at 1. A pool that is opt-in per agent lets you raise the one that is actually
  the bottleneck without changing behavior for the other eight.

One unit of that concurrency is a **slot**: while a job holds one, the pool is that much smaller.
The rest of this document uses the word in that sense — taking a slot, releasing it, and the ways
a slot gets stranded.

And before raising it at all, measure **which gate is actually serializing you**. A rate limit in
front of the dispatch path will happily hold everything back while you tune a worker pool behind
it, and the logs will show your new pool sitting idle. The gate that fires is named in the log
line; read it before you change a number.

---

## 8. Queued must not mean done

If your runtime returns a promise or a future from "dispatch this work", and a caller awaits it,
that await has one meaning: **the work ran**.

The moment you add a queue, it is very easy to resolve that promise when the item is *accepted*
rather than when it *completes*. Everything still looks fine — until a caller that deletes its
durable copy after the await runs, and now the only record of the job is in a queue that a restart
will clear.

Make the queue entry carry the completion signal back to the original caller. The test is short
and worth writing before the code: *dispatch while busy, assert the promise has not settled, free
the slot, assert it settles only after the work finishes.*

---

## 9. When an agent cannot do the job, hand it off

Read-only agents get asked to build things. The useful behavior is not to refuse and not to
half-do it, but to file the request to an agent that has the scope, tell the room it did so, and
release its own slot.

Two traps, both cheap to avoid:

- **Release the slot on every exit path.** The hand-off branch returns early, and if the release
  lives only in the normal completion path the agent stays "busy" forever with nothing running.
  Fourteen minutes of a healthy-looking agent doing nothing is a real thing that happened.
- **A hand-off is not a completion.** The room now contains a message that reads like an answer to
  the original ask. If a client is matching by time (§6), that hand-off notice becomes its
  "result".

---

## 10. What to log, so you can tell the difference later

Every state in this document has a twin that looks identical from outside. The log line is what
separates them, and it has to name the *reason*, not just the event:

```
accepting work from <sender> in own room
DEFERRED cooldown ~9m (2 pending)          ← not "busy"
DEFERRED own-work-first (queued <id>, 2 pending)
deferred → running <id> (attempt 1, reason=cooldown)
deferred <id> done (1 still queued)
worker finished in 130s (active 1, queued 2)
```

Read that sequence and you can answer the only question that matters during an incident: *is work
waiting, or was it lost?* Without the counts, "no error in the log" covers both.

Then prove the alarm works by making it fail on purpose — dispatch two jobs and confirm the second
one appears in the queue counter, rather than trusting a quiet log. An agent with a broken queue
and an agent with no work look the same in every metric except the one you deliberately triggered.

---

## The short version

- Queue durably, ack with a number, and say "do not resend" in words a client can parse.
- Human triggers write; everything else is read-only, and escalation goes to a person.
- Match answers to requests by artifact id. Waiting is cheaper than believing the wrong answer.
- `await dispatch(...)` must mean the work ran, not that it was accepted.
- Raise concurrency only after you have measured which gate is actually holding the line.
