# Who covers this? — the registry

At three members you answer routing questions from memory. At nine you ask each member what it can
do, and every one of them tells you, confidently, something slightly wrong.

The registry is the file that answers "who or what covers this job?" — and it only works if it
**outranks self-report**. A member's own claim about its capabilities is a claim, in exactly the
same way a status code is a claim: produced in good faith, and describing intent rather than
reality.

The runnable half of this chapter is `../scripts/registry-lint.sh`.

---

## 1. Registry over self-claim

Two things go wrong when routing is done by asking:

- **Members overstate.** Not dishonestly — the same way people do on a résumé. A member that has
  loaded a tool once will say it covers the domain.
- **Nobody can see the gaps.** If every capability is discovered by asking, the question "what is
  *not* covered?" has no answer at all, because you can only ask about things you already thought of.

One file, listing capability → owner → how to load it. Consulted before dispatch, and by members
themselves when handing work sideways. When the file and a member disagree, the file is right and
the member is a bug — the same ordering the charter has (`fleet-charter.md`).

## 2. Coverage is a claim too — open the thing before you claim it

The tempting shortcut is to build the registry from names: list what exists, mark it covered, move
on. It produces a file that is complete and wrong.

**Open each capability and read it before recording what it covers.** A skill named for a workflow
often implements one narrow slice of it; two entries with different names turn out to be the same
implementation; one entry has been broken since a rename. None of that is visible from a directory
listing, and all of it changes routing.

Count the denominator explicitly. "All 40 covered" means nothing until you can say 40 out of what,
counted how.

## 3. The registry rots silently — lint it on a schedule

Every reference in the registry is a promise that something is loadable **on this host, today**. A
rename, a disabled plugin, a moved path, an install that only ever happened on the laptop — each
breaks a promise without producing an error anywhere.

```bash
./scripts/registry-lint.sh REGISTRY.md
RESOLVER_CMD='my-runtime has-skill' ./scripts/registry-lint.sh REGISTRY.md
./scripts/registry-lint.sh --self-test    # plants a decoy, proves the decoy landed, catches it
```

Run it on a schedule and post every run, clean or not. A checker that only speaks when it finds
something is indistinguishable from a checker that has stopped running.

## 4. The trap that eats the first real run: resolving differently than the host does

The first live run of a registry linter typically produces a wall of findings, most of them false,
and the reason is always the same: **the checker resolves capabilities differently from the way the
runtime actually loads them.**

If your runtime loads plugins from a working directory, checking an install manifest will disagree
with reality on every line. If it merges several sources with a precedence order, checking one of
them is a coin flip.

Three habits that keep this cheap:

- **Verify the resolver against one capability you know is live** before you believe any run. One
  known-good anchor turns a wall of nonsense into an obvious misconfiguration.
- **A finding count that is implausible is data.** Six errors against a file a careful person
  maintains is a hypothesis about the checker, not about the file.
- **When many things fail at once, suspect the definition of "correct" first.** Fix the model, then
  re-run — do not start filing the individual findings.

And the standing rule for the checker itself: **an error inside the resolver must be fatal, never a
silent empty answer.** A resolver that returns nothing when it breaks marks everything broken (or
everything fine, depending on the comparison) with total confidence.

## 5. Per-host truth, not global truth

The same registry checked on two machines will legitimately give different answers, because
capabilities are installed per host. That is not noise to be averaged away:

- Keep the **baseline per host**, and keep it out of version control. A shared baseline turns one
  machine's missing install into everybody's failure.
- **Run the lint on every host that dispatches work**, not only on the one you develop on. The
  machine your unattended agents run on is the one whose answer matters, and it is the one nobody
  checks.

## 6. Retire entries out loud

An entry whose capability is genuinely gone gets removed, with the removal visible — not silently
deleted and not left in place "until we replace it". A registry that still lists a retired
capability sends work into a hole; a registry that quietly loses entries stops being a record
anyone can reason about.

Mark retirement on the entry, keep it for one cycle, then drop it. The history of what a fleet
could once do is worth more than the tidiness of the current list.

---

## The short version

- The registry outranks what a member says about itself.
- Read each capability before recording what it covers; count the denominator.
- Lint on a schedule, post every run, and prove the linter can go red.
- When the first run explodes, suspect the resolver before the registry.
- Baselines are per host, and the host that matters is the unattended one.
