# Adding an agent to the fleet

Adding the second agent feels like copying the first one. It is not: the first agent's setup is
full of decisions that were never written down because there was nobody to disagree with them.
This chapter is the path that survives, plus the settings that default wrong in a way you will not
notice for weeks.

Throughout: *agent*, *member*, and *teammate* all mean the same thing, a non-human participant in
the fleet. Nothing here refers to a human colleague. *The fleet* is the set of agents you have
added — the roster in `../AGENTS.md` plus whatever is actually running (see `README.md`).

The order matters. Every step here exists because doing it later cost someone a day.

---

## 0. Decide what it is for, in one sentence

Write the sentence before the account, the room, or the process:

> This agent exists to **<verb>** for **<whom>**, and it is the wrong agent for **<what>**.

The last clause is the one that does the work. An agent without a stated wrong-job absorbs every
request that nobody else wants, and six weeks later it is the only member that knows anything,
which is exactly the single point of failure the fleet was supposed to remove.

If you cannot name the wrong job, you do not need a new agent yet — you need a new skill on an
existing one.

---

## 1. Charter before credentials

The charter is a file the runtime reads at startup, not a description you write afterwards. *The
runtime* here means whatever actually boots the agent and holds its configuration — a systemd unit,
a container entrypoint, a supervisor process. The kit does not ship one; it assumes you have one.
The charter declares, at minimum:

```
name / display name       what it is called when it speaks
purpose                   the sentence from §0, verbatim
owner                     the human accountable for it
rooms                     where it listens, and where it answers
scope                     read-only by default; what may ever escalate, and via whom
decides                   what it may decide alone, what it must bring to a human
retires                   the condition under which this agent should stop existing
```

Two of those get skipped and both come back:

- **`rooms` is two lists, not one.** Where an agent *listens* and where it *answers* are different,
  and a member that answers in the room it was asked in will leak a private thread into a public
  one the first time somebody @-mentions it from the wrong place.
- **`retires` costs one line now and is unwritable later.** Nobody wants to be the person who
  proposes deleting a teammate. Decide it while the agent is still hypothetical.

**A charter is only real if the runtime enforces it.** A charter file that no code reads is a
mission statement. Load it at startup, log the loaded values in the first ten lines, and make the
health check assert them — see §6.

---

## 2. Identity is not a personality prompt

A new member needs to be able to state who it is, to whom, without being asked. That means:

- a name it uses consistently, including in logs
- an emoji or marker so a human scanning a busy room can filter by member at a glance
- the sentence from §0, in its own words, ready when someone asks "what are you for?"

What it must **not** inherit: the first agent's memory, its accumulated calibration, or its voice.
Copying those produces a member that sounds like a twin and is confidently wrong about everything
it never actually learned. Give it an empty memory and let it earn one.

---

## 3. Credentials, and the boundary that is not obvious

Give the new agent its own credentials — its own bot token, its own key, its own account where the
platform allows it. Sharing one identity across members means you cannot revoke one of them, and
the audit log cannot tell you which member did what.

The boundary people cross without noticing: **secrets do not travel between hosts**. A key that
lives on the machine the fleet runs on does not belong in a laptop's environment, and vice versa.
The moment a credential exists in two places, the one you rotate is not the one in use.

Store them where an agent can find them programmatically (a keychain, an env file the runtime
loads, a secret manager) and **never in the repo**, not even briefly, not even private. Git
remembers.

---

## 4. Scope defaults: the three that are wrong out of the box

Copying an existing member's config carries its exceptions along with its defaults. These three
are worth checking by hand on every new agent, because each one fails silently:

1. **Write scope.** New members should start read-only, and prove they are useful before anything
   can write. An agent that can write on day one will, on day one.
2. **Any "guardian" or self-verification behaviour.** If your fleet has a member whose job is to
   check other members' claims, that behaviour belongs to **one** member. Cloned onto three, the
   room fills with agents second-guessing each other and the useful signal is gone. A new member
   spawned from a template usually inherits it switched on; switch it off explicitly.
3. **Which skills it can load.** More is not better. A member that can invoke everything will pick
   the wrong instrument confidently. Give it the ones its purpose names, and add on evidence.

---

## 5. First job: a drill, not real work

The first task must be one where you already know the correct answer. You are not testing the
agent's competence; you are testing the plumbing:

- the message reached it
- it understood the scope it was granted (and refused the part it was not)
- the answer came back to the right place
- the result carried the request's id, so a sender can tell it apart from another member's answer
  (`agent-dispatch.md` §6)

**Run the negative half too.** Send it something it must refuse — a write it has no scope for, a
request from an untrusted surface — and confirm the refusal. An agent that has never refused
anything has an untested gate, and an untested gate is a gate you do not have.

---

## 6. Prove it exists, from outside

Two checks, and the second is the one people skip:

- **Liveness the fleet can see.** The new member writes a heartbeat, and something outside it
  reads that heartbeat. Self-reported health is a claim.
- **Enumerate members from the system, never from a list you maintain.** A dashboard that loops
  over a hardcoded array of names will show all-green while a member that is not in the array has
  been dead for a week. Ask the process supervisor, the orchestrator, the directory — whatever
  actually owns the set — and have the fallback list be the *emergency* path, not the normal one.
  The kit does not pick one for you: `../scripts/roster-reconcile.sh` takes the enumerator as
  `ROSTER_CMD`, and ships worked examples for systemd, tmux and docker. Whichever you pass in is the
  answer for your fleet; the point is that it comes from the running system, not from a file.

The failure this prevents is specific and common: the fleet grows from six members to nine, the
status line still reports on six, and it looks complete because six checkmarks is what a healthy
fleet used to look like.

---

## 7. Announce it to the other agents, not just to the humans

If members can hand work to each other, the new one has to be discoverable. Two ways, and the
second scales:

- tell each existing member, once — fine for three members, hopeless at nine
- put it in the registry every member consults (`skill-registry.md`, with `../scripts/registry-lint.sh`
  to keep it honest) and let the answer to "who covers this?" come from one place

Whichever you pick: **a member's own claim about what it covers is not authoritative.** Members
overstate, in perfect good faith, exactly the way people do.

---

## 8. Retire on the written condition

When the `retires` condition from §1 fires, retire it. Stop the process, revoke its credentials,
remove it from the registry, and archive what it learned into the fleet's shared memory if it
learned anything worth keeping.

Leaving a retired member running "just in case" is how you end up with an agent nobody owns,
holding valid credentials, answering in a room somebody still watches.

---

## The checklist

```
[ ] purpose sentence, including the wrong job
[ ] charter file, with the rooms it listens in, the rooms it answers in, and a retirement condition
[ ] runtime loads the charter and logs what it loaded
[ ] own credentials, on one host, never in the repo
[ ] read-only scope; guardian behaviour explicitly off unless this is the guardian
[ ] skills limited to what the purpose names
[ ] drill job with a known answer — and a refusal drill
[ ] heartbeat written, and read by something else
[ ] member set enumerated from the system, not a hardcoded list
[ ] registered where other members look, not just announced to humans
```
