# Registry — who or what covers which job

<!-- Copy this file to the root of your fleet repo as REGISTRY.md and fill it in.
     It is the file that answers "who covers this?" and it OUTRANKS what a member says about
     itself. When the file and a member disagree, the file is right and the member is a bug.
     See docs/skill-registry.md for why, and for the traps that eat the first real lint run. -->

Checked by `./scripts/registry-lint.sh REGISTRY.md` (run from the repo root).

The linter resolves **every backticked reference** in this file, in one of two shapes:

- `` `some/path.md` `` — must exist on disk, relative to `--root` (default: the current directory)
- `` `plugin:skill` `` — handed to `RESOLVER_CMD`, which must exit 0 if the capability is loadable

Anything not in backticks is prose and is ignored. That is deliberate: a reference the linter
cannot check should not look checked.

## Capabilities

| Capability (what someone would ask for) | Owner | How it loads | Notes |
|---|---|---|---|
| `<domain or job, in the words people actually use>` | `<member name from AGENTS.md>` | `<path/to/thing.md>` or `<plugin:skill>` | `<narrow slice? host-specific? read it before trusting the name>` |
| … | … | … | … |

<!-- Delete the example row above. A row that survives into your real registry is a promise
     nobody made. -->

## Not covered

<!-- The half that self-reporting can never produce. If every capability is discovered by asking,
     "what is NOT covered?" has no answer, because you can only ask about things you thought of.
     Write the known gaps here, by name. -->

- `<a job that arrives and has no owner yet>`

## Retired

<!-- An entry whose capability is gone gets marked here for one cycle, then dropped — not silently
     deleted, and not left in the table "until we replace it". A registry that still lists a retired
     capability sends work into a hole. -->

| Capability | Owner it had | Retired on | Why |
|---|---|---|---|
| … | … | `<YYYY-MM-DD>` | … |

---

**Denominator.** When you claim coverage, say *how many out of what, counted how*. "All 40 covered"
means nothing on its own — and the count you can defend is the one you got by opening each
capability, not by listing a directory.
