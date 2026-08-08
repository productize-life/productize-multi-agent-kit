# The fleet charter

A charter is the answer to "who is in this fleet, what may each of them do, and who decides?" —
written down once, in one file, before you need it.

The template is `../AGENTS.md`. This chapter is why each field is in it, and what happens when it
is missing. Read it once before filling the template in; the fields that look like bureaucracy are
the ones with a specific incident behind them.

---

## Why the charter is a file and not an understanding

With one agent, the rules live in your head and that works. With three, "the rules" means three
slightly different versions, and nobody discovers the difference until two members act on
contradictory ones in the same hour.

A charter fixes that only if it satisfies three properties. Miss any one and you have a mission
statement:

1. **One location.** Rules split across a README, a system prompt, and three chat messages are
   rules nobody can quote. `AGENTS.md` at the repo root, because that is where agent runtimes
   already look.
2. **Loaded at runtime.** A charter no code reads is decoration. Load it at startup, log what was
   loaded in the first lines of the log, and let the health check assert those values — see
   *Enforcement* at the end of this chapter.
3. **Outranks self-report.** When a member's behaviour and the charter disagree, the charter is
   right and the member is a bug. This ordering has to be explicit, because a confident member is
   very persuasive about its own capabilities.

---

## The fields, and the failure each one prevents

### Purpose, including the wrong job

Every member gets one sentence: *exists to X, is the wrong agent for Y.*

The second clause is load-bearing. Without it, a capable member accumulates every request that has
no obvious home. Six weeks later it is the only member with real context, everything routes through
it, and you have rebuilt the bottleneck you added agents to remove. Naming the wrong job is what
lets a router (whatever decides where work goes, whether that is a person, a script, or a member
whose job is triage) say "not this one" without asking a human.

### Proven, not aspirational

List what dispatches have actually shown a member can do. A **dispatch** here means one real
request handed to a member and carried through to an answer, not a message and not an experiment.

The temptation is to write the job description you had in mind when you created it, and the cost
lands on whoever routes work by reading this file: real work goes to a member that has never once
done the thing.

The honest version is boring and useful — a capability enters the list the first time a dispatch
proves it, and leaves when it stops being true.

### Not my lane, and boundaries — two different questions

These get merged into one "scope" column and the merge is the mistake:

- **Not my lane** — the member will not do this at all. It is the wrong member. This is what lets a
  router reject a request without asking a human.
- **Boundaries** — the member *can* do this; the question is what permission tier it needs. Three
  tiers is enough: act-then-report, ask first, never even if asked.

A member with boundaries but no lane statement will accept anything and queue it. A member with a
lane statement but no boundaries has one bit of permission for a spectrum of actions, and that bit
is always set wrong for something.

The axis that decides the tier is **reversibility**, not importance. Cheap to undo and inside work
already agreed → act and report. Someone else sees it, money moves, data leaves, or you cannot take
it back → ask first. That is also the honest answer to "which tier is this?" when nothing in the
table matches: ask what happens if it is wrong.

### Owner

One human per member. Not a team, not "the fleet". Shared ownership means an agent that misbehaves
at 2am has nobody who is going to be woken up, and an agent nobody is woken up for is one that
keeps misbehaving.

### Scope, defaulting to read-only

Scope belongs in the charter rather than in config, because config is where it becomes invisible.
A reader should be able to answer "which of these can write?" from the roster table alone.

Two rules that carry most of the value:

- **Grant write per member, never per task.** Task-level grants get copied, forwarded, and
  eventually applied to a task nobody reviewed.
- **A member may not grant scope to another member.** Escalation ends at a human. An automated
  approval path is a write path with extra steps, and it will be discovered by the first relayed
  message that contains the word "deploy".

What actually goes in the field: for each member, one line per tier — what it may do without
asking, what it must ask for first, and what it refuses even when asked. Write actions, not
adjectives: "commit on its own branch" and "merge to a shared branch" can be checked; "limited
write access" cannot.

### Rooms: listens vs answers

Three lists, not two: where it listens, where it answers, and where it must never post. The
third is the one people leave blank, and blank reads as "no limit".

The default that feels natural — answer wherever you were asked — is how a private
thread ends up summarised into a public room by a member doing exactly what it was told.

Write the destination explicitly, including the "never posts to" column for anywhere a customer,
a client, or the public can see.

### Retirement condition

Written when the member is created, because it cannot be written later. Once a member exists and is
useful, proposing its deletion feels like an attack on a teammate, and it will not happen.

A good condition is observable by someone else: *retires when the standard it checks is enforced by
a test in CI*, not *retires when no longer useful*.

---

## What must never go in the charter

- **Credentials.** Not tokens, not keys, not room-specific webhooks. The charter is the file most
  likely to be shared, quoted, and eventually made public.
- **Personality prose.** Voice belongs to the member's own definition. A charter that reads like
  character notes stops being consulted for decisions.
- **Memory.** What a member has learned is its own; the charter says what it may do, not what it
  knows. Copying one member's memory into another's charter creates a member that is confidently
  wrong about experiences it never had.

---

## Enforcement: three checks that make it real

1. **Startup echo.** The runtime logs the charter values it loaded — name, owner, scope, rooms. A
   member whose log says `scope=read-only` while writing files is a bug you can see; a member that
   logs nothing is a bug you find later, in the diff.
2. **A drill that must fail.** Ask a read-only member to write something. Confirm the refusal.
   A gate that has never refused anything is a gate you have not tested, and most gates are
   introduced already broken.
3. **Roster reconciliation.** Something compares the running members against the roster on a
   schedule and reports both directions: a member running that is not in the file, and a member in
   the file that is not running. One-directional checks miss the case that actually hurts — the
   quiet extra member, holding valid credentials, that nobody remembers starting.

---

## Changing it

The charter is edited by a human. Members may propose changes; they may not apply them, and the
reason is not distrust — it is that a system able to widen its own permissions has no permissions,
only preferences.

Keep the history. When a rule changes, the interesting artefact is the pair: what you believed
before, and what happened that changed it. A charter rewritten in place destroys exactly the record
that would have told the next person why the rule exists.
